from types import SimpleNamespace
import unittest
from unittest.mock import Mock

from apple_publish import strict_localizations


class AppleLocalizationSafetyTests(unittest.TestCase):
    def setUp(self):
        self.client = Mock()
        self.client._get_existing_app_store_version_localizations.return_value = {"ru": "locale-ru"}
        self.client._is_first_app_store_version.return_value = False
        self.app = SimpleNamespace(attributes=SimpleNamespace(primaryLocale="ru"))
        self.version = SimpleNamespace(attributes=SimpleNamespace(platform="IOS"))
        self.notes = [SimpleNamespace(locale=locale, whats_new="Git notes") for locale in ("ru", "en-US", "en-GB")]

    def test_only_existing_locales_are_updated(self):
        strict_localizations(self.client, self.app, self.version, self.notes)
        update = self.client._create_or_update_app_store_version_localization
        update.assert_called_once()
        self.assertEqual(update.call_args.args[0], "locale-ru")
        self.assertEqual(update.call_args.args[-1].locale, "ru")

    def test_missing_translation_blocks_before_metadata_updates(self):
        self.client._get_existing_app_store_version_localizations.return_value = {"ru": "ru", "fr-FR": "fr"}
        with self.assertRaises(SystemExit):
            strict_localizations(self.client, self.app, self.version, self.notes)
        self.client._create_or_update_app_store_version_localization.assert_not_called()

    def test_missing_primary_or_empty_listing_blocks(self):
        for locales in ({}, {"en-US": "en"}):
            self.client._get_existing_app_store_version_localizations.return_value = locales
            with self.subTest(locales=locales), self.assertRaises(SystemExit):
                strict_localizations(self.client, self.app, self.version, self.notes)

    def test_api_failure_stops_and_suppresses_body(self):
        self.client._create_or_update_app_store_version_localization.side_effect = RuntimeError("SIMULATED_PRIVATE_BODY")
        with self.assertRaises(SystemExit) as caught:
            strict_localizations(self.client, self.app, self.version, self.notes)
        self.assertNotIn("SIMULATED_PRIVATE_BODY", str(caught.exception))
        self.assertIn("BLOCKED", str(caught.exception))

    def test_first_version_follows_apple_rule_without_mutating_git_notes(self):
        self.client._is_first_app_store_version.return_value = True
        strict_localizations(self.client, self.app, self.version, self.notes)
        self.client._create_or_update_app_store_version_localization.assert_not_called()
        self.assertEqual(self.notes[0].whats_new, "Git notes")

    def test_real_sdk_locale_values_match_existing_locales(self):
        from codemagic.apple.resources import Locale
        self.app.attributes.primaryLocale = Locale("ru")
        self.client._get_existing_app_store_version_localizations.return_value = {Locale("ru"): "locale-ru"}
        self.notes[0].locale = Locale("ru")
        strict_localizations(self.client, self.app, self.version, self.notes)
        self.client._create_or_update_app_store_version_localization.assert_called_once()

    def test_pinned_sdk_inherits_the_adapter_method(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        self.assertIs(AppStoreConnect._create_or_update_app_store_version_localizations,
                      SubmitToAppStoreAction._create_or_update_app_store_version_localizations)
        self.assertTrue(callable(SubmitToAppStoreAction._create_or_update_app_store_version_localization))


if __name__ == "__main__":
    unittest.main()
