"""Apple authentication and GET-only diagnostics. No files or publishing."""
import os
import re
import sys

import ios_store as apple


def emit(code, stage):
    if (code, stage) not in apple.SUCCESS_EVENTS:
        raise apple.AppleCheckFailure("APPLE_DIAGNOSTIC_INTERNAL_ERROR", "runtime")
    print(f"APPLE_DIAG: {code} stage={stage}", flush=True)


def run(args, env):
    # Deliberately no argparse error echo: even invalid CLI text must not leak.
    if len(args) != 3:
        raise apple.AppleCheckFailure("APPLE_DIAGNOSTIC_USAGE", "usage")
    mode, option, value = args
    if mode == "auth" and option == "--channel" and value in ("rc", "production"):
        apple.prepare_apple_auth(env, require_internal_group=value == "rc", emit=emit)
        emit("APPLE_AUTH_MATERIAL_VALID", "jwt")
        return
    if mode != "check" or option != "--build" or not re.fullmatch(r"[1-9][0-9]{0,3}", value):
        raise apple.AppleCheckFailure("APPLE_DIAGNOSTIC_USAGE", "usage")
    # This diagnostic is intentionally scoped to PROKAT and its existing RC group.
    apple.validate_apple_environment(env, require_internal_group=True)
    for name, expected in (("APP_STORE_APP_ID", "6817078475"), ("TESTFLIGHT_GROUP", "AuylTech Test Team")):
        if env[name] != expected:
            raise apple.AppleCheckFailure("APPLE_ENV_INVALID", "environment", variable=name)
    config, token = apple.prepare_apple_auth(env, require_internal_group=True, emit=emit)
    state = apple.read_apple_state(config, token, require_internal_group=True, emit=emit)
    apple.check_builds({"platform": "ios", "channel": "rc", "destination": "testflight", "build": int(value)},
                       state["builds"], state["uploads"], state["historical_floor"])
    emit("APPLE_STATE_VALID", "build")


def main(args=None, env=None):
    try:
        run(sys.argv[1:] if args is None else args, os.environ if env is None else env)
        return 0
    except Exception as error:
        safe = error if isinstance(error, apple.AppleCheckFailure) else apple.AppleCheckFailure(
            "APPLE_DIAGNOSTIC_INTERNAL_ERROR", "runtime")
        print(f"BLOCKED: {safe}", file=sys.stderr, flush=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
