"""Fail-closed App Store read checks, then the standard Codemagic publisher.

No local state database; state snapshots are diagnostic CI output only.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.appstoreconnect.apple.com"
ROOT = Path(__file__).resolve().parents[2]


class Blocked(RuntimeError):
    pass


def build_tuple(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", value):
        raise Blocked("Unknown existing Apple build-number format; inspect before uploading")
    parts = tuple(int(n) for n in value.split("."))
    return parts + (0,) * (3 - len(parts))


def check_builds(context, builds, uploads, floor):
    if context["platform"] != "ios" or context["channel"] not in ("rc", "production"):
        raise Blocked("Invalid iOS release context")
    expected = "testflight" if context["channel"] == "rc" else "app_store_review"
    if context["destination"] != expected:
        raise Blocked("iOS channel/destination mismatch")
    requested = (context["build"], 0, 0)
    observed = [build_tuple(str(floor))]
    for item in builds:
        version = item["attributes"]["version"]
        number = build_tuple(version)
        observed.append(number)
        if requested == number:
            raise Blocked(f"Apple already has build {version}, id={item['id']}, state={item['attributes']['processingState']}. Inspect existing build; never reupload blindly")
    for item in uploads:
        attrs = item["attributes"]
        number = build_tuple(attrs["cfBundleVersion"])
        observed.append(number)
        if requested == number:
            raise Blocked(f"Apple upload already exists, id={item['id']}, state={attrs['state']}. Inspect Build Uploads before recovery")
    if requested <= max(observed):
        raise Blocked(f"Use a new globally increasing iOS build number above {max(observed)} (conservative policy, including failed/expired builds)")


def get_json(url, token):
    # Never forward JWTs to an arbitrary pagination host or follow HTTP redirects.
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" or parsed.netloc != "api.appstoreconnect.apple.com" or not parsed.path.startswith("/v1/"):
        raise Blocked("Unexpected Apple API pagination URL")

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            raise Blocked("Unexpected Apple API redirect")

    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    with urllib.request.build_opener(NoRedirect).open(request, timeout=60) as response:
        return json.load(response)


def all_pages(path, token):
    url = API + path
    resources = []
    visited = set()
    while url:
        if url in visited or len(visited) >= 100:
            raise Blocked("Incomplete/cyclic Apple pagination; state UNKNOWN")
        visited.add(url)
        page = get_json(url, token)
        if not isinstance(page.get("data"), list):
            raise Blocked("Malformed Apple resource list; state UNKNOWN")
        resources.extend(page["data"])
        url = page["links"].get("next")
    return resources


def preflight(context):
    import jwt  # Installed by pinned Codemagic CLI requirements.

    for name in ("APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_PRIVATE_KEY", "APP_STORE_CONNECT_KEY_IDENTIFIER"):
        if not os.environ.get(name):
            raise Blocked(f"Missing protected integration variable {name}; complete U3")
    app_id = os.environ.get("APP_STORE_APP_ID", "")
    floor = os.environ.get("IOS_HISTORICAL_MAX_BUILD", "")
    if not re.fullmatch(r"[1-9][0-9]*", app_id) or not re.fullmatch(r"0|[1-9][0-9]*", floor):
        raise Blocked("U3 must set APP_STORE_APP_ID and confirmed IOS_HISTORICAL_MAX_BUILD")
    now = int(time.time())
    token = jwt.encode(
        {"iss": os.environ["APP_STORE_CONNECT_ISSUER_ID"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        os.environ["APP_STORE_CONNECT_PRIVATE_KEY"],
        algorithm="ES256",
        headers={"kid": os.environ["APP_STORE_CONNECT_KEY_IDENTIFIER"], "typ": "JWT"},
    )
    app = get_json(f"{API}/v1/apps/{app_id}", token)["data"]
    if app["attributes"]["bundleId"] != "com.auyltech.prokat":
        raise Blocked("Apple app ID/bundle mismatch")
    if app["attributes"]["primaryLocale"] not in ("ru", "en-US", "en-GB"):
        raise Blocked("Apple primary locale needs an explicit Git translation mapping")
    builds = all_pages(f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.platform]=IOS&limit=200", token)
    # Covers uploads not yet visible in /builds (new Apple API since WWDC25).
    # Unsupported/forbidden endpoint is UNKNOWN, never an empty list.
    uploads = all_pages(f"/v1/apps/{app_id}/buildUploads", token)
    state = {"app_id": app_id, "builds": [{"id": b["id"], "attributes": {k: b["attributes"][k] for k in ("version", "processingState")}} for b in builds],
             "uploads": [{"id": u["id"], "attributes": {k: u["attributes"][k] for k in ("cfBundleVersion", "state")}} for u in uploads], "historical_floor": int(floor)}
    (ROOT / "build/release/apple-state.json").write_text(json.dumps(state, indent=2), encoding="utf-8")
    print(json.dumps(state), flush=True)
    check_builds(context, builds, uploads, int(floor))


def publish_arguments(context, ipa, group=None):
    args = ["app-store-connect", "publish", "--path", str(ipa), "--enable-package-validation",
            "--altool-retries", "0", "--api-server-error-retries", "0", "--api-unauthorized-retries", "0",
            "--max-find-build-wait", "10", "--max-build-processing-wait", "20"]
    notes = "@file:" + str(ROOT / "build/release/apple-localizations.json")
    if context["channel"] == "rc" and context["destination"] == "testflight":
        if not group:
            raise Blocked("TESTFLIGHT_GROUP must name the internal group prepared at U3")
        args += ["--beta-group", group, "--beta-build-localizations", notes]
    elif context["channel"] == "production" and context["destination"] == "app_store_review":
        args += ["--app-store", "--release-type", "AFTER_APPROVAL", "--version-string", context["version"],
                 "--app-store-version-localizations", notes]
    else:
        raise Blocked("Publishing channel/destination mismatch")
    return args


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("preflight", "publish"):
        raise Blocked("Expected preflight or publish")
    context = json.loads((ROOT / "build/release/context.json").read_text(encoding="utf-8"))
    if not os.environ.get("CM_BUILD_ID") or os.environ.get("CM_TAG") != context["tag"]:
        raise Blocked("Codemagic iOS tag webhook required")
    if context["channel"] == "production" and os.environ.get("PRODUCTION_PUBLISHING_ENABLED") != "true":
        raise Blocked("Production disabled until U5")
    preflight(context)
    if sys.argv[1] == "publish":
        packages = list((ROOT / "build/ios/ipa").glob("*.ipa"))
        if len(packages) != 1:
            raise Blocked("Expected exactly one signed IPA")
        result = subprocess.run(publish_arguments(context, packages[0], os.environ.get("TESTFLIGHT_GROUP")), check=False)
        if result.returncode:
            raise Blocked("Apple publishing incomplete; upload may already be accepted. Inspect Build Uploads/TestFlight/App Store version; no automatic retry")
        print("APPLE_SUBMISSION_STEP_COMPLETED: check TestFlight group or App Review state; this does not prove App Store publication")
    else:
        print("APPLE_PREFLIGHT_VERIFIED: complete API snapshot; no binary uploaded")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never print JWT/key/request dumps, including library exception bodies.
        print(f"BLOCKED: {error if isinstance(error, Blocked) else 'Apple state UNKNOWN (' + type(error).__name__ + ')'}", file=sys.stderr)
        sys.exit(1)
