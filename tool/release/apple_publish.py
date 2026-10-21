"""Pinned Codemagic CLI with fail-closed What's New updates, not a new publisher.

CLI 0.70.0 catches localization API errors and may continue to App Review.
Replace only that method: update existing locales, never create listing locales,
and stop before submission on missing translations or any metadata API failure.
"""
import contextlib
import copy
from importlib.metadata import version
import io
import sys

CLI_VERSION = "0.70.0"


class PublishCliError(RuntimeError):
    """Fixed, safe diagnostics only; never include argparse output or values."""


def require_supported_cli():
    try:
        if version("codemagic-cli-tools") == CLI_VERSION:
            return
    except Exception:
        pass
    raise PublishCliError("APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED")


def validate_publish_arguments(args):
    """Parse the entire generated argv with the pinned SDK, without invoking it.

    Do not instantiate AppStoreConnect, resolve credential environment defaults,
    create an API client, configure logging, invoke actions or launch altool.
    Explicit @file: Git localizations are parsed exactly as in real publishing.
    """
    require_supported_cli()
    try:
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.arguments import Types

        # argparse errors can contain metadata, paths and argument values.
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            parsed = AppStoreConnect._setup_cli_options().parse_args(args)
            if not AppStoreConnect._validate_args(parsed):
                raise ValueError
        if parsed.action != "publish" or parsed.show_version:
            raise ValueError
        if not parsed.submit_to_app_store and (parsed.beta_group_names or parsed.submit_to_testflight):
            # Internal Automatic Distribution must not become manual assignment
            # or external Beta App Review. Production argument behavior is unchanged.
            raise ValueError
        # All three CLI options are attempt counts in 0.70.0, not extra retries.
        # Missing flags must not silently enable defaults (10 / 3 / 3).
        for flag, attribute, kind in (
            ("--altool-retries", "altool_retries_count", Types.AltoolRetriesCount),
            ("--api-server-error-retries", "server_error_retries", Types.ApiServerErrorRetries),
            ("--api-unauthorized-retries", "unauthorized_request_retries", Types.ApiUnauthorizedRetries),
        ):
            if args.count(flag) != 1 or kind.resolve_value(getattr(parsed, attribute)) != 1:
                raise ValueError
        return parsed
    except (Exception, SystemExit):
        raise PublishCliError("APPLE_PUBLISH_ARGUMENTS_INVALID") from None


def strict_localizations(client, app, app_store_version, localizations):
    try:
        existing = client._get_existing_app_store_version_localizations(app_store_version)
        supplied = {item.locale or app.attributes.primaryLocale: item for item in localizations}
        if not existing or app.attributes.primaryLocale not in existing or not set(existing).issubset(supplied):
            raise SystemExit("BLOCKED: existing App Store locales require Git translations; no submission. Inspect accepted build before recovery")
        first = client._is_first_app_store_version(app, app_store_version.attributes.platform)
        if first:
            return  # Apple forbids What's New for the first version; no empty PATCH.
        for locale, identifier in existing.items():
            item = copy.copy(supplied[locale])
            client._create_or_update_app_store_version_localization(identifier, app, app_store_version, item)
    except Exception as error:
        # SystemExit deliberately bypasses upstream's catch-and-continue handler.
        raise SystemExit(f"BLOCKED: Apple localization update failed ({type(error).__name__}); no submission. Build may already be accepted; no reupload") from None


def main():
    try:
        validate_publish_arguments(sys.argv[1:])
    except PublishCliError as error:
        raise SystemExit(f"BLOCKED: {error}") from None
    from codemagic.tools.app_store_connect import AppStoreConnect
    from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
    SubmitToAppStoreAction._create_or_update_app_store_version_localizations = strict_localizations
    AppStoreConnect.invoke_cli()


if __name__ == "__main__":
    main()
