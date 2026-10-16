"""Pinned Codemagic CLI with fail-closed What's New updates, not a new publisher.

CLI 0.70.0 catches localization API errors and may continue to App Review.
Replace only that method: update existing locales, never create listing locales,
and stop before submission on missing translations or any metadata API failure.
"""
import copy
from importlib.metadata import version


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
    if version("codemagic-cli-tools") != "0.70.0":
        raise SystemExit("BLOCKED: revalidate the localization adapter before upgrading Codemagic CLI")
    from codemagic.tools.app_store_connect import AppStoreConnect
    from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
    SubmitToAppStoreAction._create_or_update_app_store_version_localizations = strict_localizations
    AppStoreConnect.invoke_cli()


if __name__ == "__main__":
    main()
