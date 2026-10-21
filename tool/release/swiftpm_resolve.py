"""Retry only locked SwiftPM resolution, never build/sign/publish operations."""
from dataclasses import dataclass
import json
import math
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
LOCKS = (
    "pubspec.lock", "ios/Podfile.lock",
    "ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    "ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
)
CLOCK_FILE = "build/release/swiftpm-clock.json"
ATTEMPT_SECONDS = 600
CLEANUP_SECONDS = 10
TOTAL_SECONDS = 32 * 60
DEPENDENCY_PHASE_SECONDS = 60 * 60
BACKOFFS = (15, 45)

# The real xcodebuild I/O failure was 74. Other codes, even with similar text,
# need a reviewed fixture before becoming retryable. 74 alone is insufficient.
NETWORK = re.compile(
    r"the request timed out|operation timed out|connection (?:was )?(?:reset|interrupted|closed)|"
    r"network connection (?:was )?lost|temporary failure in name resolution|"
    r"could(?: not|n't) resolve host|network is unreachable|not connected to the internet|"
    r"could not connect to (?:the )?server|"
    r"(?:https?(?:/[0-9.]+)?(?: status)?|status code|response code|badResponseStatusCode)"
    r"\s*[:=( ]\s*(?:429|502|503|504)\b|"
    r"NSURLErrorDomain\s+Code=-(?:1001|1003|1004|1005|1006|1009)\b", re.I)
PERMANENT = re.compile(
    r"invalid manifest|manifest (?:parse|compilation|syntax)|package\.swift:\d+|"
    r"tools.version|incompatible|not compatible|could not find|no versions? of|"
    r"versions?.*(?:not found|does not exist)|dependencies could not be resolved because|"
    r"checksum.*(?:mismatch|invalid|does not match)|(?:invalid|mismatched).*checksum|"
    r"signature|signing|certificate|authentication|authorization|permission denied|"
    r"\b(?:401|403|404)\b|Package\.resolved.*(?:required|out.of.date|missing|changed)|"
    r"(?:unable|failed) to (?:load|open).*(?:project|workspace)|"
    r"(?:project|workspace).*(?:does not exist|not found)|scheme.*(?:not found|not contain)|"
    r"configuration.*(?:invalid|missing|not found)", re.I)
SUMMARY = re.compile(r"^xcodebuild: error: Could not resolve package dependencies:?$", re.I)
DOWNLOAD = re.compile(r"failed downloading|downloadError\(|failed to (?:clone|fetch)|fatal: unable to access", re.I)
LOCATION = re.compile(r"^(?:failed downloading ['\"][^'\"]+['\"]|failed to clone repository ['\"]?https?://\S+['\"]?:?)$", re.I)
ERROR = re.compile(r"\berror:|\bfatal:|downloadError\(|failed downloading|failed to (?:clone|fetch)", re.I)


@dataclass(frozen=True)
class Attempt:
    returncode: int
    output: str
    timed_out: bool = False


def transient_download_failure(result):
    # Never expose captured output, URLs, headers or environment in diagnostics.
    if result.returncode != 74 or result.timed_out or len(result.output) > 2 * 1024 * 1024:
        return False
    text = re.sub(r"\x1b\[[0-9;]*m", "", result.output)
    if PERMANENT.search(text) or not DOWNLOAD.search(text) or not NETWORK.search(text):
        return False
    after_summary = False
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if SUMMARY.fullmatch(line):
            after_summary = True
        elif (after_summary or ERROR.search(line)) and not (NETWORK.search(line) or LOCATION.fullmatch(line)):
            return False
    return True


def command(root):
    return ["xcodebuild", "-resolvePackageDependencies", "-workspace", "ios/Runner.xcworkspace",
            "-scheme", "Runner", "-clonedSourcePackagesDirPath", str(root / "build/release/SourcePackages"),
            "-onlyUsePackageVersionsFromResolvedFile"]


def stop_process(process):
    """Terminate the resolver process group; never leave a second resolver running."""
    if os.name == "posix":
        os.killpg(process.pid, signal.SIGTERM)
    else:
        process.terminate()
    try:
        process.communicate(timeout=5)
    except subprocess.TimeoutExpired:
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGKILL)
        else:
            process.kill()
        process.communicate(timeout=5)


def run_xcodebuild(root, timeout):
    process = subprocess.Popen(command(root), cwd=root, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        stop_process(process)
        return Attempt(124, "", timed_out=True)
    except BaseException:
        stop_process(process)
        raise
    return Attempt(process.returncode, output.decode("utf-8", errors="replace"))


class LockFailure(RuntimeError):
    pass


def log(message):
    print(message, flush=True)


def locked_inputs(root):
    """Compare against the tagged HEAD, not a snapshot of already-drifted files."""
    baseline = {}
    for path in LOCKS:
        result = subprocess.run(["git", "show", "HEAD:" + path], cwd=root,
                                capture_output=True, timeout=15, check=False)
        if result.returncode:
            raise LockFailure
        baseline[path] = result.stdout
    verify_locks(root, baseline)
    return baseline


def verify_locks(root, baseline):
    try:
        for path, expected in baseline.items():
            file = root / path
            if not stat.S_ISREG(file.lstat().st_mode) or file.read_bytes() != expected:
                raise LockFailure
    except OSError:
        raise LockFailure from None


def resolve(root, source_started, *, runner=run_xcodebuild, clock=time.monotonic,
            sleep=time.sleep, emit=log, baseline_loader=locked_inputs):
    deadline = min(clock() + TOTAL_SECONDS, source_started + DEPENDENCY_PHASE_SECONDS)
    try:
        baseline = baseline_loader(root)
        last_code = 75  # No command ran when the available budget is insufficient.
        for attempt in range(1, 4):
            verify_locks(root, baseline)
            if deadline - clock() < ATTEMPT_SECONDS + CLEANUP_SECONDS:
                emit("SwiftPM resolution failed: insufficient time budget")
                return last_code
            emit(f"SwiftPM resolution attempt {attempt}/3")
            result = runner(root, ATTEMPT_SECONDS)
            last_code = result.returncode if result.returncode >= 0 else 128 - result.returncode
            verify_locks(root, baseline)
            if clock() > deadline:
                emit("SwiftPM resolution failed: time budget exhausted")
                return last_code or 75
            if result.returncode == 0:
                emit("SwiftPM dependencies resolved successfully")
                return 0
            if result.timed_out:
                emit("SwiftPM resolution failed: resolver time limit exceeded")
                return last_code
            if not transient_download_failure(result):
                emit("SwiftPM resolution failed: non-retryable error")
                return last_code
            emit("Transient network download failure")
            if attempt == 3:
                emit("SwiftPM resolution failed: retry limit reached")
                return last_code
            delay = BACKOFFS[attempt - 1]
            if deadline - clock() < delay + ATTEMPT_SECONDS + CLEANUP_SECONDS:
                emit("SwiftPM resolution failed: insufficient time budget")
                return last_code
            emit(f"Retrying after {delay} seconds")
            sleep(delay)
        raise AssertionError
    except LockFailure:
        emit("BLOCKED: SWIFTPM_LOCK_GUARD_FAILED")
        return 1


def ci_context(env):
    if (env.get("CI") != "true" or not env.get("CM_BUILD_ID") or
            not re.fullmatch(r"[0-9a-f]{40}", env.get("CM_COMMIT", ""))):
        raise ValueError
    return {"build_id": env["CM_BUILD_ID"], "commit": env["CM_COMMIT"]}


def main(args=None, *, root=ROOT, env=None):
    try:
        args = sys.argv[1:] if args is None else args
        env = os.environ if env is None else env
        if args not in (["start"], ["resolve"]):
            raise ValueError
        context = ci_context(env)
        marker = root / CLOCK_FILE
        now = time.monotonic()
        if args == ["start"]:
            marker.parent.mkdir(parents=True, exist_ok=True)
            # Ephemeral public timing data only; refuse stale/repeated initialization.
            with marker.open("x", encoding="utf-8") as stream:
                json.dump({**context, "started": now}, stream)
            return 0
        data = json.loads(marker.read_text(encoding="utf-8"))
        started = data["started"]
        if ({k: data[k] for k in context} != context or type(started) not in (int, float) or
                not math.isfinite(started) or started < 0 or started > now):
            raise ValueError
        return resolve(root, started)
    except KeyboardInterrupt:
        print("SwiftPM resolution failed: interrupted", flush=True)
        return 130
    except Exception:
        # No subprocess/exception bodies: they can contain credential-bearing URLs.
        print("SwiftPM resolution failed: invalid context or internal error", flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
