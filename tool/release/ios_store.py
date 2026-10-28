"""Fail-closed App Store read checks, then the standard Codemagic publisher.

No local state database; state snapshots are diagnostic CI output only.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.appstoreconnect.apple.com"
ROOT = Path(__file__).resolve().parents[2]
RC_APP_ID = "6817078475"
APP_ID = "6817078475"
RC_GROUP = "AuylTech Test Team"
DISTRIBUTION_TIMEOUT = 20 * 60
DISTRIBUTION_INTERVAL = 20
DISTRIBUTION_POLLS = 61


class Blocked(RuntimeError):
    pass


FAILURE_CODES = frozenset({
    "APPLE_ENV_MISSING", "APPLE_ENV_INVALID", "APPLE_PEM_INVALID", "APPLE_KEY_UNSUPPORTED",
    "APPLE_JWT_FAILED", "APPLE_AUTH_REJECTED", "APPLE_ACCESS_FORBIDDEN", "APPLE_API_REJECTED",
    "APPLE_API_UNAVAILABLE", "APPLE_RESPONSE_INVALID", "APPLE_PAGINATION_FAILED",
    "APPLE_APP_MISMATCH", "APPLE_GROUP_INVALID",     "APPLE_BUILD_ALREADY_USED",
    "APPLE_BUILD_NOT_INCREASING", "APPLE_STATE_INVALID", "APPLE_DIAGNOSTIC_INTERNAL_ERROR",
    "APPLE_DIAGNOSTIC_USAGE", "APPLE_DEPENDENCY_SETUP_FAILED", "APPLE_SOURCE_CONTEXT_INVALID",
    "APPLE_REVIEW_SUBMISSION_OPEN", "APPLE_VERSION_IN_FLIGHT", "APPLE_VERSION_STATE_UNSUPPORTED",
    "APPLE_VERSION_STATE_MISMATCH", "APPLE_VERSION_CONFLICT", "APPLE_VERSION_NOT_INCREASING",
    "APPLE_SUBMISSION_GUARD_FAILED", "APPLE_SUBMISSION_ITEMS_CHANGED",
    "APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM", "APPLE_SUBMISSION_OUTCOME_UNKNOWN",
})
STAGES = frozenset({"environment", "pem", "key", "jwt", "api", "app", "builds", "uploads",
                    "groups", "build", "usage", "runtime", "snapshot", "versions", "submissions"})
REASONS = frozenset({"format", "escaped_newline", "newline_missing", "leading_quote", "leading_backtick",
                     "bom", "file_reference", "env_reference", "load_failed",
                     "key_type", "curve", "unexpected", "http_4xx", "rate_limit", "server_error",
                     "timeout", "transport", "json", "schema", "unsafe_url", "redirect", "cycle",
                     "page_limit", "incomplete", "duplicate_resource"})
ENV_NAMES = ("APP_STORE_CONNECT_ISSUER_ID", "APP_STORE_CONNECT_KEY_IDENTIFIER",
             "PROKAT_ASC_PRIVATE_KEY_PEM", "APP_STORE_APP_ID", "IOS_HISTORICAL_MAX_BUILD",
             "TESTFLIGHT_GROUP")
SUCCESS_EVENTS = frozenset({
    ("APPLE_ENV_VALID", "environment"), ("APPLE_PEM_VALID", "pem"), ("APPLE_KEY_VALID", "key"),
    ("APPLE_JWT_CREATED", "jwt"), ("APPLE_AUTH_MATERIAL_VALID", "jwt"),
    ("APPLE_APP_VERIFIED", "app"), ("APPLE_BUILDS_READ", "builds"),
    ("APPLE_UPLOADS_READ", "uploads"), ("APPLE_GROUP_VERIFIED", "groups"),
    ("APPLE_STATE_VALID", "build"),
})


class AppleCheckFailure(Blocked):
    """Only allowlisted literals can cross the credential/log boundary."""

    def __init__(self, code, stage, reason=None, variable=None):
        if (code not in FAILURE_CODES or stage not in STAGES or
                (reason is not None and reason not in REASONS) or
                (variable is not None and variable not in ENV_NAMES)):
            code, stage, reason, variable = "APPLE_DIAGNOSTIC_INTERNAL_ERROR", "runtime", None, None
        self.code, self.stage, self.reason, self.variable = code, stage, reason, variable
        message = f"{code} stage={stage}"
        if reason is not None:
            message += f" reason={reason}"
        if variable is not None:
            message += f" variable={variable}"
        super().__init__(message)


def report(emit, code, stage):
    if (code, stage) not in SUCCESS_EVENTS:
        raise AppleCheckFailure("APPLE_DIAGNOSTIC_INTERNAL_ERROR", "runtime")
    if emit is not None:
        emit(code, stage)


def validate_apple_environment(env, *, require_internal_group):
    names = ENV_NAMES if require_internal_group else ENV_NAMES[:-1]
    for name in names:
        if not env.get(name):
            raise AppleCheckFailure("APPLE_ENV_MISSING", "environment", variable=name)
        if not isinstance(env[name], str):
            raise AppleCheckFailure("APPLE_ENV_INVALID", "environment", variable=name)
    patterns = {
        "APP_STORE_CONNECT_ISSUER_ID": r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}",
        "APP_STORE_CONNECT_KEY_IDENTIFIER": r"[A-Za-z0-9]{10}",
        "APP_STORE_APP_ID": r"[1-9][0-9]{0,19}",
        "IOS_HISTORICAL_MAX_BUILD": r"0|[1-9][0-9]{0,3}",
    }
    for name, pattern in patterns.items():
        if not re.fullmatch(pattern, env[name]):
            raise AppleCheckFailure("APPLE_ENV_INVALID", "environment", variable=name)
    if require_internal_group and (not env["TESTFLIGHT_GROUP"].strip() or
                                   env["TESTFLIGHT_GROUP"] != env["TESTFLIGHT_GROUP"].strip()):
        raise AppleCheckFailure("APPLE_ENV_INVALID", "environment", variable="TESTFLIGHT_GROUP")
    # Private material is never returned as part of printable configuration/state.
    return {"app_id": env["APP_STORE_APP_ID"], "historical_floor": int(env["IOS_HISTORICAL_MAX_BUILD"]),
            "issuer": env["APP_STORE_CONNECT_ISSUER_ID"], "key_id": env["APP_STORE_CONNECT_KEY_IDENTIFIER"],
            "group": env.get("TESTFLIGHT_GROUP")}


def load_apple_private_key(pem, emit=None):
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.serialization import load_pem_private_key

    if "\\n" in pem or "\\r" in pem:
        raise AppleCheckFailure("APPLE_PEM_INVALID", "pem", "escaped_newline")
    for prefix, reason in (("\ufeff", "bom"), ("'", "leading_quote"), ('"', "leading_quote"),
                           ("`", "leading_backtick"), ("@file:", "file_reference"), ("@env:", "env_reference")):
        if pem.startswith(prefix):
            raise AppleCheckFailure("APPLE_PEM_INVALID", "pem", reason)
    if "\n" not in pem:
        raise AppleCheckFailure("APPLE_PEM_INVALID", "pem", "newline_missing")
    lines = pem.splitlines()
    label = "PRIVATE KEY"
    if (len(pem) > 16384 or not pem.isascii() or
            "\r" in pem.replace("\r\n", "") or len(lines) < 3 or
            lines[0] != f"-----BEGIN {label}-----" or lines[-1] != f"-----END {label}-----" or
            any(not re.fullmatch(r"[A-Za-z0-9+/=]+", line) for line in lines[1:-1])):
        raise AppleCheckFailure("APPLE_PEM_INVALID", "pem", "format")
    report(emit, "APPLE_PEM_VALID", "pem")
    try:
        key = load_pem_private_key(pem.encode("ascii"), password=None)
    except Exception:
        raise AppleCheckFailure("APPLE_PEM_INVALID", "pem", "load_failed") from None
    if not isinstance(key, ec.EllipticCurvePrivateKey):
        raise AppleCheckFailure("APPLE_KEY_UNSUPPORTED", "key", "key_type")
    if not isinstance(key.curve, ec.SECP256R1):
        raise AppleCheckFailure("APPLE_KEY_UNSUPPORTED", "key", "curve")
    report(emit, "APPLE_KEY_VALID", "key")
    return key


def create_apple_token(config, pem):
    import jwt

    try:
        now = int(time.time())
        return jwt.encode(
            {"iss": config["issuer"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
            pem, algorithm="ES256", headers={"kid": config["key_id"], "typ": "JWT"},
        )
    except Exception:
        raise AppleCheckFailure("APPLE_JWT_FAILED", "jwt", "unexpected") from None


def prepare_apple_auth(env, *, require_internal_group, emit=None):
    config = validate_apple_environment(env, require_internal_group=require_internal_group)
    report(emit, "APPLE_ENV_VALID", "environment")
    # This raw-PEM input is independent of Codemagic CLI/integration references.
    # Never fall back to APP_STORE_CONNECT_PRIVATE_KEY or resolve its files.
    pem = env["PROKAT_ASC_PRIVATE_KEY_PEM"]
    load_apple_private_key(pem, emit)
    token = create_apple_token(config, pem)
    report(emit, "APPLE_JWT_CREATED", "jwt")
    return config, token


def build_tuple(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]{1,64}(?:\.[0-9]{1,64}){0,2}", value):
        raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
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
            raise AppleCheckFailure("APPLE_BUILD_ALREADY_USED", "build")
    for item in uploads:
        attrs = item["attributes"]
        number = build_tuple(attrs["cfBundleVersion"])
        observed.append(number)
        if requested == number:
            raise AppleCheckFailure("APPLE_BUILD_ALREADY_USED", "build")
    if requested <= max(observed):
        raise AppleCheckFailure("APPLE_BUILD_NOT_INCREASING", "build")


def checked_url(url, stage):
    # Never forward JWTs to an arbitrary pagination host or follow HTTP redirects.
    try:
        if not isinstance(url, str) or any(ord(c) <= 32 or ord(c) == 127 for c in url):
            raise ValueError
        parsed = urllib.parse.urlsplit(url)
        if (parsed.scheme != "https" or parsed.netloc != "api.appstoreconnect.apple.com" or
                not parsed.path.startswith("/v1/") or parsed.fragment):
            raise ValueError
        return parsed
    except ValueError:
        raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "unsafe_url") from None


def remaining_timeout(deadline, stage):
    remaining = 15 if deadline is None else deadline - time.monotonic()
    if remaining <= 0:
        raise AppleCheckFailure("APPLE_API_UNAVAILABLE", stage, "timeout")
    return min(15, remaining)


def get_json(url, token, *, stage="api", deadline=None):
    checked_url(url, stage)

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "redirect")

    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"}, method="GET")
    try:
        with urllib.request.build_opener(NoRedirect).open(request, timeout=remaining_timeout(deadline, stage)) as response:
            result = json.load(response)
        remaining_timeout(deadline, stage)
        return result
    except urllib.error.HTTPError as error:
        code = error.code
        error.close()
        if code == 401:
            raise AppleCheckFailure("APPLE_AUTH_REJECTED", stage) from None
        if code == 403:
            raise AppleCheckFailure("APPLE_ACCESS_FORBIDDEN", stage) from None
        if 300 <= code < 400:
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "redirect") from None
        if code == 429 or 500 <= code < 600:
            raise AppleCheckFailure("APPLE_API_UNAVAILABLE", stage, "rate_limit" if code == 429 else "server_error") from None
        raise AppleCheckFailure("APPLE_API_REJECTED", stage, "http_4xx") from None
    except TimeoutError:
        raise AppleCheckFailure("APPLE_API_UNAVAILABLE", stage, "timeout") from None
    except (urllib.error.URLError, OSError):
        raise AppleCheckFailure("APPLE_API_UNAVAILABLE", stage, "transport") from None
    except (ValueError, UnicodeError):
        raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "json") from None


def all_pages(path, token, *, stage="api", deadline=None):
    url = API + path
    original = checked_url(url, stage)
    def filters(parsed):
        try:
            return {key: value for key, value in urllib.parse.parse_qs(
                parsed.query, keep_blank_values=True, max_num_fields=100).items() if key.startswith("filter[")}
        except ValueError:
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "unsafe_url") from None
    original_filters = filters(original)
    resources = []
    visited = set()
    identifiers = set()
    expected_total = None
    while url:
        remaining_timeout(deadline, stage)
        parsed = checked_url(url, stage)
        if parsed.path != original.path or filters(parsed) != original_filters:
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "unsafe_url")
        if url in visited:
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "cycle")
        if len(visited) >= 100:
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "page_limit")
        visited.add(url)
        page = get_json(url, token, stage=stage, deadline=deadline)
        if not isinstance(page, dict) or not isinstance(page.get("data"), list) or not isinstance(page.get("links"), dict):
            raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")
        for item in page["data"]:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"]:
                raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")
            if item["id"] in identifiers:
                raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "duplicate_resource")
            identifiers.add(item["id"])
        resources.extend(page["data"])
        if "meta" in page:
            meta = page["meta"]
            if not isinstance(meta, dict) or not isinstance(meta.get("paging"), dict):
                raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")
            if "total" in meta["paging"]:
                total = meta["paging"]["total"]
                if type(total) is not int or total < 0:
                    raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")
                if expected_total is not None and expected_total != total:
                    raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "incomplete")
                expected_total = total
        url = page["links"].get("next")
        if url is not None and (not isinstance(url, str) or not url):
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "unsafe_url")
        if expected_total is not None and (len(resources) > expected_total or (not url and len(resources) != expected_total)):
            raise AppleCheckFailure("APPLE_PAGINATION_FAILED", stage, "incomplete")
    return resources


def check_internal_group(groups, name, *, automatic=False):
    if not isinstance(name, str) or not name.strip():
        raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
    validate_resources(groups, ("name",), "groups")
    matches = [group for group in groups if group["attributes"]["name"] == name]
    if len(matches) != 1 or matches[0]["attributes"].get("isInternalGroup") is not True:
        raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
    if automatic and (matches[0]["attributes"].get("hasAccessToAllBuilds") is not True or
                      not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", matches[0]["id"])):
        raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
    return matches[0]["id"]


def require_rc_target(config):
    if config["app_id"] != RC_APP_ID:
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    if config["group"] != RC_GROUP:
        raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")


def validate_resources(items, fields, stage):
    if not isinstance(items, list):
        raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")
    for item in items:
        if (not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"] or
                not isinstance(item.get("attributes"), dict) or
                any(not isinstance(item["attributes"].get(field), str) or not item["attributes"][field] for field in fields)):
            raise AppleCheckFailure("APPLE_RESPONSE_INVALID", stage, "schema")


def validate_build_uploads(uploads):
    """Apple BuildUpload.Attributes.State is an object, unlike Build.processingState."""
    validate_resources(uploads, ("cfBundleVersion",), "uploads")
    for upload in uploads:
        attributes = upload["attributes"]
        try:
            build_tuple(attributes["cfBundleVersion"])
        except AppleCheckFailure:
            raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "uploads", "schema") from None
        state = attributes.get("state")
        if (not isinstance(state, dict) or set(state) - {"state", "errors", "warnings", "infos"} or
                not isinstance(state.get("state"), str) or
                state["state"] not in {"AWAITING_UPLOAD", "PROCESSING", "FAILED", "COMPLETE"}):
            raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "uploads", "schema")
        for field in ("errors", "warnings", "infos"):
            if field not in state:
                continue
            details = state[field]
            if not isinstance(details, list):
                raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "uploads", "schema")
            for detail in details:
                if (not isinstance(detail, dict) or set(detail) - {"code", "description"} or
                        any(not isinstance(value, str) for value in detail.values())):
                    raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "uploads", "schema")


def read_apple_state(config, token, *, require_internal_group, emit=None, automatic=False):
    """GET-only, in-memory state. No snapshot, publisher, or response logging."""
    deadline = time.monotonic() + 90
    if automatic:
        if not require_internal_group:
            raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
        require_rc_target(config)
    app_id = config["app_id"]
    response = get_json(f"{API}/v1/apps/{app_id}", token, stage="app", deadline=deadline)
    if not isinstance(response, dict):
        raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "app", "schema")
    app = response.get("data")
    validate_resources([app], ("bundleId", "primaryLocale"), "app")
    if app["id"] != app_id:
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    if app["attributes"]["bundleId"] != "com.auyltech.prokat":
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    if app["attributes"]["primaryLocale"] not in ("ru", "en-US", "en-GB"):
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    report(emit, "APPLE_APP_VERIFIED", "app")
    builds = all_pages(f"/v1/builds?filter[app]={app_id}&filter[preReleaseVersion.platform]=IOS&limit=200", token, stage="builds", deadline=deadline)
    validate_resources(builds, ("version", "processingState"), "builds")
    report(emit, "APPLE_BUILDS_READ", "builds")
    # Covers uploads not yet visible in /builds (new Apple API since WWDC25).
    # Unsupported/forbidden endpoint is UNKNOWN, never an empty list.
    uploads = all_pages(f"/v1/apps/{app_id}/buildUploads", token, stage="uploads", deadline=deadline)
    validate_build_uploads(uploads)
    report(emit, "APPLE_UPLOADS_READ", "uploads")
    if require_internal_group:
        # The pinned publisher only warns about a missing group and can exit 0.
        # Reject that state (and external groups) before building/uploading.
        groups = all_pages(f"/v1/apps/{app_id}/betaGroups?limit=200", token, stage="groups", deadline=deadline)
        group_id = check_internal_group(groups, config["group"], automatic=automatic)
        report(emit, "APPLE_GROUP_VERIFIED", "groups")
    remaining_timeout(deadline, "build")
    return {**({"automatic_group_id": group_id} if automatic else {}),
            "app_id": app_id, "builds": [{"id": b["id"], "attributes": {k: b["attributes"][k] for k in ("version", "processingState")}} for b in builds],
            # Keep the existing snapshot contract and never persist StateDetail text.
            "uploads": [{"id": u["id"], "attributes": {"cfBundleVersion": u["attributes"]["cfBundleVersion"],
                                                        "state": u["attributes"]["state"]["state"]}} for u in uploads],
            "historical_floor": config["historical_floor"]}


def preflight(context=None):
    require_group = context is None or context["channel"] == "rc"
    config, token = prepare_apple_auth(os.environ, require_internal_group=require_group)
    if context is not None and context["channel"] == "production" and config["app_id"] != APP_ID:
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    state = read_apple_state(config, token, require_internal_group=require_group,
                            automatic=context is not None and context["channel"] == "rc")
    if context is not None and context["channel"] == "production":
        check_production_review(config, token, context.get("version"))
    snapshot = ROOT / "build/release/apple-state.json"
    snapshot.parent.mkdir(parents=True, exist_ok=True)
    snapshot.write_text(json.dumps(state, indent=2), encoding="utf-8")
    print(json.dumps(state), flush=True)
    if context is not None:
        check_builds(context, state["builds"], state["uploads"], state["historical_floor"])
    return state


def production_version_path(app_id):
    return (f"/v1/apps/{app_id}/appStoreVersions?filter[platform]=IOS"
            "&fields[appStoreVersions]=versionString,platform,appStoreState,appVersionState&limit=100")


def production_submission_path(app_id):
    return (f"/v1/reviewSubmissions?filter[app]={app_id}&filter[platform]=IOS"
            "&fields[reviewSubmissions]=platform,state&limit=200")


def check_production_review(config, token, version):
    """GET-only early stop. Not the mutation-time guard."""
    from apple_review_policy import classify

    deadline = time.monotonic() + 90
    versions = all_pages(production_version_path(config["app_id"]), token, stage="versions", deadline=deadline)
    submissions = all_pages(production_submission_path(config["app_id"]), token, stage="submissions", deadline=deadline)
    decision = classify(version, versions, submissions)
    if not decision.ok:
        raise AppleCheckFailure(decision.code, decision.stage)


def distribution_resource(response, kind, identifier=None):
    """Strict resource identity on documented related-resource GET endpoints."""
    item = response.get("data") if isinstance(response, dict) else None
    if (not isinstance(item, dict) or item.get("type") != kind or
            not isinstance(item.get("id"), str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", item["id"]) or
            (identifier is not None and item["id"] != identifier) or not isinstance(item.get("attributes"), dict)):
        raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "build", "schema")
    return item


def distribution_ready(context, config, token, group_id, build_id, deadline):
    """One GET-only poll. Returns a pinned build ID and current readiness."""
    groups = all_pages(f"/v1/apps/{config['app_id']}/betaGroups?limit=200", token, stage="groups", deadline=deadline)
    if check_internal_group(groups, config["group"], automatic=True) != group_id:
        raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
    app = distribution_resource(get_json(f"{API}/v1/betaGroups/{group_id}/app", token,
                                         stage="app", deadline=deadline), "apps", config["app_id"])
    if app["attributes"].get("bundleId") != "com.auyltech.prokat":
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    if build_id is None:
        query = urllib.parse.urlencode({"filter[app]": config["app_id"], "filter[version]": str(context["build"]),
                                       "filter[preReleaseVersion.version]": context["version"],
                                       "filter[preReleaseVersion.platform]": "IOS", "limit": "200"})
        builds = all_pages("/v1/builds?" + query, token, stage="builds", deadline=deadline)
        if not builds:
            return None, False  # Eventual visibility, not permission/transport errors.
        if len(builds) != 1:
            raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "builds", "schema")
        candidate = distribution_resource({"data": builds[0]}, "builds")
        if candidate["attributes"].get("version") != str(context["build"]):
            raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
        build_id = candidate["id"]  # Never choose the latest or switch IDs on later polls.
    build = distribution_resource(get_json(f"{API}/v1/builds/{build_id}", token, stage="build", deadline=deadline),
                                  "builds", build_id)
    attrs = build["attributes"]
    if attrs.get("version") != str(context["build"]) or attrs.get("expired") is not False:
        raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
    if attrs.get("processingState") == "PROCESSING":
        return build_id, False
    if attrs.get("processingState") != "VALID":
        raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
    app = distribution_resource(get_json(f"{API}/v1/builds/{build_id}/app", token, stage="app", deadline=deadline),
                                "apps", config["app_id"])
    if app["attributes"].get("bundleId") != "com.auyltech.prokat":
        raise AppleCheckFailure("APPLE_APP_MISMATCH", "app")
    version = distribution_resource(get_json(f"{API}/v1/builds/{build_id}/preReleaseVersion", token,
                                             stage="build", deadline=deadline), "preReleaseVersions")
    if version["attributes"].get("version") != context["version"] or version["attributes"].get("platform") != "IOS":
        raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
    detail = distribution_resource(get_json(f"{API}/v1/builds/{build_id}/buildBetaDetail", token,
                                            stage="build", deadline=deadline), "buildBetaDetails")
    internal = detail["attributes"].get("internalBuildState")
    if internal in ("PROCESSING", "READY_FOR_BETA_TESTING"):
        return build_id, False
    if internal != "IN_BETA_TESTING":
        raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
    members = all_pages(f"/v1/betaGroups/{group_id}/relationships/builds?limit=200", token,
                        stage="groups", deadline=deadline)
    if any(item.get("type") != "builds" for item in members):
        raise AppleCheckFailure("APPLE_RESPONSE_INVALID", "groups", "schema")
    return build_id, any(item["id"] == build_id for item in members)


def confirm_testflight_distribution(context, group_id, *, clock=time.monotonic, sleep=time.sleep):
    """After a successful single publisher call: bounded GETs, never re-upload."""
    try:
        if (context.get("platform") != "ios" or context.get("channel") != "rc" or
                context.get("destination") != "testflight" or type(context.get("build")) is not int or
                not 1 <= context["build"] <= 9999 or not isinstance(context.get("version"), str) or
                not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", context["version"]) or
                not isinstance(group_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", group_id)):
            raise AppleCheckFailure("APPLE_STATE_INVALID", "build", "format")
        config, token = prepare_apple_auth(os.environ, require_internal_group=True)
        require_rc_target(config)
        deadline, build_id = clock() + DISTRIBUTION_TIMEOUT, None
        for attempt in range(1, DISTRIBUTION_POLLS + 1):
            if clock() >= deadline:
                break
            build_id, ready = distribution_ready(context, config, token, group_id, build_id, deadline)
            if clock() >= deadline:
                break
            if ready:
                print("TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED", flush=True)
                return build_id
            print(f"TESTFLIGHT_DISTRIBUTION_PENDING attempt={attempt}/{DISTRIBUTION_POLLS}", flush=True)
            if attempt < DISTRIBUTION_POLLS:
                sleep(min(DISTRIBUTION_INTERVAL, max(0, deadline - clock())))
    except AppleCheckFailure as error:
        # These fields are already allowlisted; never print responses/exceptions.
        print(f"TESTFLIGHT_CONFIRMATION_CHECK_FAILED code={error.code} stage={error.stage}", flush=True)
    except Exception:
        print("TESTFLIGHT_CONFIRMATION_CHECK_FAILED code=INTERNAL_ERROR", flush=True)
    raise Blocked("TESTFLIGHT_DISTRIBUTION_UNCONFIRMED") from None


def publish_arguments(context, ipa, group=None):
    args = ["app-store-connect", "publish", "--path", str(ipa), "--enable-package-validation",
            "--altool-retries", "1", "--api-server-error-retries", "1", "--api-unauthorized-retries", "1",
            "--max-find-build-wait", "10", "--max-build-processing-wait", "20"]
    notes = "@file:" + str(ROOT / "build/release/apple-localizations.json")
    if context["channel"] == "rc" and context["destination"] == "testflight":
        if not group:
            raise Blocked("TESTFLIGHT_GROUP must name the internal group prepared at U3")
        # Automatic Distribution owns group assignment. --testflight means
        # external Beta App Review in 0.70.0, not internal availability.
        args += ["--beta-build-localizations", notes]
    elif context["channel"] == "production" and context["destination"] == "app_store_review":
        args += ["--app-store", "--release-type", "AFTER_APPROVAL", "--version-string", context["version"],
                 "--app-store-version-localizations", notes]
    else:
        raise Blocked("Publishing channel/destination mismatch")
    return args


def require_production_cloud(context):
    """Production-only. RC and diagnostic commands never reach this check."""
    if context.get("channel") != "production":
        return
    if os.environ.get("PRODUCTION_PUBLISHING_ENABLED") != "true":
        raise Blocked("Production disabled until U5")
    if os.environ.get("CM_TRIGGER_SOURCE") != "webhook":
        raise Blocked("IOS_PRODUCTION_REQUIRES_WEBHOOK")
    commit = os.environ.get("CM_COMMIT") or ""
    tag = context.get("tag")
    if not isinstance(tag, str) or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise Blocked("IOS_PRODUCTION_AUTHORIZATION_INVALID")


def checked_publish_arguments(context, ipa, group=None):
    from apple_publish import PublishCliError, validate_publish_arguments

    args = publish_arguments(context, ipa, group)
    try:
        parsed = validate_publish_arguments(args[1:])
    except PublishCliError as error:
        raise Blocked(str(error)) from None
    if context["channel"] == "rc" and (parsed.submit_to_app_store or parsed.submit_to_testflight or parsed.beta_group_names):
        raise Blocked("APPLE_PUBLISH_ARGUMENTS_INVALID")
    return args


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("access", "validate-publish", "preflight", "publish"):
        raise Blocked("Expected access, validate-publish, preflight or publish")
    if sys.argv[1] == "access":
        preflight()
        print("APPLE_ACCESS_VERIFIED: app/builds/uploads/internal group read through GET only; no signing, upload or submission. Publishing permissions NOT proven")
        return
    context = json.loads((ROOT / "build/release/context.json").read_text(encoding="utf-8"))
    if not os.environ.get("CM_BUILD_ID") or os.environ.get("CM_TAG") != context["tag"]:
        raise Blocked("Codemagic iOS tag webhook required")
    if context["channel"] == "production" and os.environ.get("PRODUCTION_PUBLISHING_ENABLED") != "true":
        raise Blocked("Production disabled until U5")
    require_production_cloud(context)
    if sys.argv[1] == "validate-publish":
        # No IPA exists yet. Only the path literal differs from the final argv;
        # context, group, localizations and every option use the same builder.
        checked_publish_arguments(context, ROOT / "build/ios/ipa/offline-preflight.ipa",
                                  os.environ.get("TESTFLIGHT_GROUP"))
        print("APPLE_PUBLISH_ARGUMENTS_VALID: CLI 0.70.0; offline parse only; no upload")
        return
    state = preflight(context)
    if sys.argv[1] == "publish":
        packages = list((ROOT / "build/ios/ipa").glob("*.ipa"))
        if len(packages) != 1:
            raise Blocked("Expected exactly one signed IPA")
        args = checked_publish_arguments(context, packages[0], os.environ.get("TESTFLIGHT_GROUP"))
        require_production_cloud(context)
        if context["channel"] == "rc":
            group_id = state.get("automatic_group_id")
            if not isinstance(group_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,128}", group_id):
                raise AppleCheckFailure("APPLE_GROUP_INVALID", "groups")
        result = subprocess.run([sys.executable, str(ROOT / "tool/release/apple_publish.py"), *args[1:]], check=False)
        if result.returncode:
            raise Blocked("Apple publishing incomplete; upload may already be accepted. Inspect Build Uploads/TestFlight/App Store version; no automatic retry")
        if context["channel"] == "rc":
            confirm_testflight_distribution(context, group_id)
        else:
            print("APPLE_SUBMISSION_STEP_COMPLETED: check TestFlight group or App Review state; this does not prove App Store publication")
    else:
        print("APPLE_PREFLIGHT_VERIFIED: complete API snapshot; no binary uploaded")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never print JWT/key/request dumps, including library exception bodies.
        print(f"BLOCKED: {error if isinstance(error, Blocked) else AppleCheckFailure('APPLE_DIAGNOSTIC_INTERNAL_ERROR', 'runtime')}", file=sys.stderr)
        sys.exit(1)
