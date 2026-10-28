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
OUTPUT_LIMIT = 2 * 1024 * 1024  # Preserve the original classification limit (characters).
TAIL_LINES = 20
TAIL_BYTES = 8 * 1024
REASONS = frozenset({
    "TRANSIENT_DOWNLOAD_TIMEOUT", "TRANSIENT_NETWORK_ERROR", "PERMANENT_RESOLUTION_ERROR",
    "MIXED_ERROR", "UNCLASSIFIED_OUTPUT", "OUTPUT_LIMIT_EXCEEDED", "LOCK_GUARD_FAILED",
    "PROCESS_TIMEOUT", "SPAWN_FAILED", "INTERNAL_ERROR", "UNSUPPORTED_EXIT_CODE",
    "TIME_BUDGET_EXHAUSTED", "INTERRUPTED",
})

# Semantic normalization is internal to classification, NOT the printable tail.
# Do not interpret credentials, numbers or package names inside URLs as errors.
URL = re.compile(r"\b[a-z][a-z0-9+.-]*://[^\s<>\"']+", re.I)
CONTROL = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]|[\x00-\x08\x0b-\x1f\x7f-\x9f]")
TIMEOUT = re.compile(r"the request timed out|operation timed out|timeout was reached|"
                     r"NSURLErrorDomain\s+(?:Code=|error\s+)-1001\b", re.I)

# The real xcodebuild I/O failure was 74. Other codes, even with similar text,
# need a reviewed fixture before becoming retryable. 74 alone is insufficient.
NETWORK = re.compile(
    TIMEOUT.pattern + r"|connection (?:was )?(?:reset|interrupted|closed)|"
    r"network connection (?:was )?lost|temporary failure in name resolution|"
    r"could(?: not|n't) resolve host|a server with the specified hostname could not be found|"
    r"network is unreachable|not connected to the internet|the internet connection appears to be offline|"
    r"could not connect to (?:the )?server|"
    r"(?:https?(?:/[0-9.]+)?(?: status)?|status code|response code|badResponseStatusCode)"
    r"\s*[:=( ]\s*(?:429|502|503|504)\b|"
    r"NSURLErrorDomain\s+(?:Code=|error\s+)-(?:1001|1003|1004|1005|1006|1009)\b", re.I)
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
LOCATION = re.compile(r"^(?:failed downloading ['\"]<URL>['\"]|failed to clone repository ['\"]?<URL>['\"]?:?)$", re.I)
ERROR = re.compile(r"\berror:|\bfatal:|downloadError\(|failed downloading|failed to (?:clone|fetch)", re.I)
# Only this reviewed Xcode footer, not arbitrary lines after the summary.
FOOTER = re.compile(r"^Writing error result bundle to (?:/[^\s\"']+\.xcresult|\"/[^\r\n\"]+\.xcresult\")$", re.I)
# Display categories only; they never grant permission to retry.
DISPLAY_TYPES = tuple((re.compile(pattern, re.I), label) for pattern, label in (
    (r"invalid manifest|manifest (?:parse|compilation|syntax)|package\.swift:\d+|tools.version", "MANIFEST_ERROR"),
    (r"checksum", "CHECKSUM_ERROR"),
    (r"signature|signing|certificate", "SIGNATURE_ERROR"),
    (r"\b(?:401|403|404)\b|authentication|authorization|permission denied", "ACCESS_ERROR"),
    (r"incompatible|not compatible|no versions? of|versions?.*(?:not found|does not exist)", "VERSION_ERROR"),
    (r"project|workspace|scheme|configuration|Package\.resolved", "CONFIGURATION_ERROR"),
))


@dataclass(frozen=True)
class Attempt:
    returncode: int
    output: str
    timed_out: bool = False


@dataclass(frozen=True)
class Classification:
    retryable: bool
    reason: str


def semantic_text(output):
    return URL.sub("<URL>", CONTROL.sub("", output.replace("\r\n", "\n").replace("\r", "\n")))


def classify_failure(result):
    """Decide from captured output, never from the lossy printable projection."""
    if result.timed_out:
        return Classification(False, "PROCESS_TIMEOUT")
    if len(result.output) > OUTPUT_LIMIT:
        return Classification(False, "OUTPUT_LIMIT_EXCEEDED")
    text = semantic_text(result.output)
    # A reviewed footer's dynamic path is not an error message either.
    errors = "\n".join(line for line in text.splitlines() if not FOOTER.fullmatch(line.strip()))
    network_download = bool(DOWNLOAD.search(errors) and NETWORK.search(errors))
    if PERMANENT.search(errors):
        return Classification(False, "MIXED_ERROR" if network_download else "PERMANENT_RESOLUTION_ERROR")
    if result.returncode != 74:
        return Classification(False, "UNSUPPORTED_EXIT_CODE")
    if not network_download:
        return Classification(False, "UNCLASSIFIED_OUTPUT")
    after_summary = False
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if SUMMARY.fullmatch(line):
            after_summary = True
        elif (after_summary or ERROR.search(line)) and not (
                NETWORK.search(line) or LOCATION.fullmatch(line) or FOOTER.fullmatch(line)):
            return Classification(False, "MIXED_ERROR")
    return Classification(True, "TRANSIENT_DOWNLOAD_TIMEOUT" if TIMEOUT.search(errors) else "TRANSIENT_NETWORK_ERROR")


def transient_download_failure(result):
    return classify_failure(result).retryable


def safe_diagnostic_tail(output):
    """Lossy allowlisted projection: NO substrings/values from the log are emitted.

    Unknown text, headers, tokens, PEM, paths and even unrecognized secret formats
    cannot cross this boundary. These patterns select constants, not replacements
    in raw lines. The input/output window is bounded; no raw artifact is written.
    """
    projected = []
    for line in semantic_text(output[-TAIL_BYTES:]).splitlines()[-TAIL_LINES:]:
        line = line.strip()
        if not line:
            continue
        if SUMMARY.fullmatch(line):
            safe = "xcodebuild: error: Could not resolve package dependencies"
        elif FOOTER.fullmatch(line):
            safe = "Writing error result bundle to [PATH_REDACTED]"
        elif LOCATION.fullmatch(line):
            safe = "Dependency download location: [URL_REDACTED]"
        elif PERMANENT.search(line):
            label = next((label for pattern, label in DISPLAY_TYPES if pattern.search(line)), "PERMANENT_RESOLUTION_ERROR")
            safe = "[" + label + "_TEXT_REDACTED]"
        elif TIMEOUT.search(line):
            safe = "[DOWNLOAD_TIMEOUT_TEXT_REDACTED]"
        elif NETWORK.search(line):
            safe = "[NETWORK_ERROR_TEXT_REDACTED]"
        else:
            safe = "[UNCLASSIFIED_LINE_REDACTED]"
        projected.append(safe)
    # All emitted strings are fixed ASCII; this is also a strict byte limit.
    return "\n".join(projected)[:TAIL_BYTES]


def diagnose_failure(attempt, result, retry, reason, emit):
    if reason not in REASONS:
        retry, reason = False, "INTERNAL_ERROR"
    attempt = attempt if type(attempt) is int and 0 <= attempt <= 3 else 0
    code = result.returncode if result is not None and type(result.returncode) is int else "NONE"
    emit(f"SWIFTPM_FAILURE attempt={attempt}/3 child_exit={code} retry={'yes' if retry is True else 'no'} reason={reason}")
    if result is not None and result.output:
        tail = safe_diagnostic_tail(result.output)
        if tail:
            emit("SWIFTPM_DIAGNOSTIC_TAIL stream=combined projection=allowlisted")
            emit(tail)


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
    try:
        process = subprocess.Popen(command(root), cwd=root, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
    except OSError:
        raise SpawnFailure from None
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as error:
        stop_process(process)
        partial = error.output or b""
        return Attempt(124, partial.decode("utf-8", errors="replace"), timed_out=True)
    except BaseException:
        stop_process(process)
        raise
    return Attempt(process.returncode, output.decode("utf-8", errors="replace"))


class LockFailure(RuntimeError):
    pass


class SpawnFailure(RuntimeError):
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
    attempt, result = 0, None
    try:
        baseline = baseline_loader(root)
        last_code = 75  # No command ran when the available budget is insufficient.
        for number in range(1, 4):
            verify_locks(root, baseline)
            if deadline - clock() < ATTEMPT_SECONDS + CLEANUP_SECONDS:
                diagnose_failure(attempt, result, False, "TIME_BUDGET_EXHAUSTED", emit)
                emit("SwiftPM resolution failed: insufficient time budget")
                return last_code
            attempt, result = number, None
            emit(f"SwiftPM resolution attempt {attempt}/3")
            result = runner(root, ATTEMPT_SECONDS)
            last_code = result.returncode if result.returncode >= 0 else 128 - result.returncode
            verify_locks(root, baseline)
            if clock() > deadline:
                diagnose_failure(attempt, result, False, "TIME_BUDGET_EXHAUSTED", emit)
                emit("SwiftPM resolution failed: time budget exhausted")
                return last_code or 75
            if result.returncode == 0:
                emit("SwiftPM dependencies resolved successfully")
                return 0
            if result.timed_out:
                diagnose_failure(attempt, result, False, "PROCESS_TIMEOUT", emit)
                emit("SwiftPM resolution failed: resolver time limit exceeded")
                return last_code
            classification = classify_failure(result)
            if not classification.retryable:
                diagnose_failure(attempt, result, False, classification.reason, emit)
                emit("SwiftPM resolution failed: non-retryable error")
                return last_code
            if attempt == 3:
                diagnose_failure(attempt, result, False, classification.reason, emit)
                emit("Transient network download failure")
                emit("SwiftPM resolution failed: retry limit reached")
                return last_code
            delay = BACKOFFS[attempt - 1]
            if deadline - clock() < delay + ATTEMPT_SECONDS + CLEANUP_SECONDS:
                diagnose_failure(attempt, result, False, "TIME_BUDGET_EXHAUSTED", emit)
                emit("SwiftPM resolution failed: insufficient time budget")
                return last_code
            diagnose_failure(attempt, result, True, classification.reason, emit)
            emit("Transient network download failure")
            emit(f"Retrying after {delay} seconds")
            sleep(delay)
        raise AssertionError
    except LockFailure:
        diagnose_failure(attempt, result, False, "LOCK_GUARD_FAILED", emit)
        emit("BLOCKED: SWIFTPM_LOCK_GUARD_FAILED")
        return 1
    except SpawnFailure:
        diagnose_failure(attempt, None, False, "SPAWN_FAILED", emit)
        emit("SwiftPM resolution failed: unable to start resolver")
        return 1
    except KeyboardInterrupt:
        diagnose_failure(attempt, result, False, "INTERRUPTED", emit)
        emit("SwiftPM resolution failed: interrupted")
        return 130
    except Exception:
        diagnose_failure(attempt, None, False, "INTERNAL_ERROR", emit)
        emit("SwiftPM resolution failed: internal error")
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
        diagnose_failure(0, None, False, "INTERRUPTED", log)
        print("SwiftPM resolution failed: interrupted", flush=True)
        return 130
    except Exception:
        # No subprocess/exception bodies: they can contain credential-bearing URLs.
        diagnose_failure(0, None, False, "INTERNAL_ERROR", log)
        print("SwiftPM resolution failed: invalid context or internal error", flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
