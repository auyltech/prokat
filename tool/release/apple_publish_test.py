import contextlib
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import apple_publish as adapter
import ios_store as store
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


class ApplePublishCliTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        notes = self.root / 'build/release/apple-localizations.json'
        notes.parent.mkdir(parents=True)
        notes.write_text(json.dumps([{'locale': 'ru', 'whats_new': 'Synthetic Git notes'}]), encoding='utf-8')
        self.addCleanup(patch.stopall)
        patch.object(store, 'ROOT', self.root).start()
        # Parser-only tests cannot accidentally instantiate clients/actions or launch commands.
        for target in ('socket.socket.connect', 'requests.sessions.Session.request',
                       'subprocess.Popen',
                       'codemagic.tools.app_store_connect.AppStoreConnect.from_cli_args',
                       'codemagic.tools.app_store_connect.AppStoreConnect._invoke_action'):
            patch(target, side_effect=AssertionError('Offline test boundary'), is_cli_action=False).start()
        self.rc = {'channel': 'rc', 'destination': 'testflight', 'version': '1.2.3'}

    def arguments(self, context=None):
        return store.publish_arguments(context or self.rc, self.root / 'not-built.ipa', 'Synthetic Internal')[1:]

    def test_real_parser_accepts_complete_rc_and_production_before_ipa_exists(self):
        for context in (self.rc, {**self.rc, 'channel': 'production', 'destination': 'app_store_review'}):
            with self.subTest(context=context):
                parsed = adapter.validate_publish_arguments(self.arguments(context))
                self.assertEqual(parsed.action, 'publish')
                self.assertTrue(parsed.enable_package_validation)
                self.assertEqual(parsed.altool_retries_count.value, 1)
                self.assertEqual(parsed.server_error_retries.value, 1)
                self.assertEqual(parsed.unauthorized_request_retries.value, 1)
        self.assertFalse((self.root / 'not-built.ipa').exists())

    def test_zero_rejected_for_each_attempt_count_by_actual_sdk_parser(self):
        for flag in ('--altool-retries', '--api-server-error-retries', '--api-unauthorized-retries'):
            args = self.arguments()
            args[args.index(flag) + 1] = '0'
            with self.subTest(flag=flag), self.assertRaisesRegex(adapter.PublishCliError, '^APPLE_PUBLISH_ARGUMENTS_INVALID$'):
                adapter.validate_publish_arguments(args)

    def test_defaults_multiple_attempts_or_duplicate_flags_cannot_slip_in(self):
        for flag in ('--altool-retries', '--api-server-error-retries', '--api-unauthorized-retries'):
            for mode in ('missing', 'two', 'duplicate'):
                args = self.arguments()
                index = args.index(flag)
                if mode == 'missing':
                    del args[index:index + 2]
                elif mode == 'two':
                    args[index + 1] = '2'
                else:
                    args += [flag, '1']
                with self.subTest(flag=flag, mode=mode), self.assertRaises(adapter.PublishCliError):
                    adapter.validate_publish_arguments(args)

    def test_explicit_counts_override_environment_defaults(self):
        with patch.dict('os.environ', {
            'APP_STORE_CONNECT_ALTOOL_RETRIES': '10',
            'APP_STORE_CONNECT_API_SERVER_ERROR_RETRIES': '3',
            'APP_STORE_CONNECT_API_UNAUTHORIZED_RETRIES': '3',
            'APP_STORE_CONNECT_PRIVATE_KEY': '@file:/must-not-be-read',
        }):
            parsed = adapter.validate_publish_arguments(self.arguments())
        self.assertEqual(parsed.altool_retries_count.value, 1)
        self.assertEqual(parsed.server_error_retries.value, 1)
        self.assertEqual(parsed.unauthorized_request_retries.value, 1)

    def test_all_generated_options_and_localizations_are_parsed_not_help(self):
        cases = [self.arguments() + ['--unsupported-option'], self.arguments() + ['--help'],
                 self.arguments() + ['--version']]
        invalid_wait = self.arguments()
        invalid_wait[invalid_wait.index('--max-find-build-wait') + 1] = '0'
        cases.append(invalid_wait)
        for args in cases:
            with self.subTest(args=args), self.assertRaises(adapter.PublishCliError):
                adapter.validate_publish_arguments(args)
        (self.root / 'build/release/apple-localizations.json').write_text('{invalid JSON', encoding='utf-8')
        with self.assertRaises(adapter.PublishCliError):
            adapter.validate_publish_arguments(self.arguments())

    def test_version_drift_or_missing_distribution_blocks_without_invocation(self):
        for kwargs in ({'return_value': '0.71.0'}, {'side_effect': RuntimeError('PRIVATE_TEST_SENTINEL')}):
            with patch.object(adapter, 'version', **kwargs), self.assertRaisesRegex(
                    adapter.PublishCliError, '^APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED$'):
                adapter.validate_publish_arguments(self.arguments())

    def test_adapter_rejects_bad_argv_before_publishing_and_suppresses_values(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        sentinel = 'PRIVATE_TEST_SENTINEL'
        args = self.arguments() + ['--unknown-secret-option', sentinel]
        with patch.object(adapter.sys, 'argv', ['apple_publish.py', *args]), \
                patch.object(AppStoreConnect, 'invoke_cli', is_cli_action=False) as invoke, \
                contextlib.redirect_stdout(io.StringIO()) as stdout, \
                contextlib.redirect_stderr(io.StringIO()) as stderr, self.assertRaises(SystemExit) as caught:
            adapter.main()
        invoke.assert_not_called()
        self.assertEqual(str(caught.exception), 'BLOCKED: APPLE_PUBLISH_ARGUMENTS_INVALID')
        self.assertNotIn(sentinel, stdout.getvalue() + stderr.getvalue() + str(caught.exception))

    def test_adapter_accepts_valid_argv_only_then_delegates_to_cli(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        with patch.object(adapter.sys, 'argv', ['apple_publish.py', *self.arguments()]), \
                patch.object(AppStoreConnect, 'invoke_cli', is_cli_action=False) as invoke, \
                patch.object(SubmitToAppStoreAction, '_create_or_update_app_store_version_localizations', is_cli_action=False):
            adapter.main()
        invoke.assert_called_once_with()  # The real invoke/upload is never run.

    def test_automatic_rc_has_notes_but_no_manual_group_or_external_review_options(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.apple.resources import Platform
        args = self.arguments()
        parsed = adapter.validate_publish_arguments(args)
        self.assertFalse(parsed.submit_to_testflight)
        self.assertFalse(parsed.submit_to_app_store)
        self.assertIsNone(parsed.beta_group_names)
        self.assertTrue(parsed.beta_build_localizations.value)
        options = AppStoreConnect._get_app_store_connect_submit_options(
            None, parsed.submit_to_testflight, parsed.submit_to_app_store,
            platform=Platform.IOS, beta_group_names=parsed.beta_group_names,
            beta_build_localizations=parsed.beta_build_localizations)
        self.assertIsNone(options[0])  # No create_beta_app_review_submission.
        self.assertIsNone(options[1])  # No App Store submission.
        self.assertIsNotNone(options[2])  # Keep Git What to Test localizations.
        self.assertIsNone(options[3])  # No add_build_to_beta_groups.
        for forbidden in (['--testflight'], ['--beta-group', 'Synthetic Internal']):
            with self.subTest(flag=forbidden), self.assertRaises(adapter.PublishCliError):
                adapter.validate_publish_arguments(args + forbidden)
        original = store.publish_arguments
        def wrong_channel(*values):
            return original(*values) + ['--app-store']
        with patch.object(store, 'publish_arguments', side_effect=wrong_channel), self.assertRaisesRegex(
                store.Blocked, '^APPLE_PUBLISH_ARGUMENTS_INVALID$'):
            store.checked_publish_arguments(self.rc, self.root / 'not-built.ipa', 'Synthetic Internal')


class SingleAttemptSdkTests(unittest.TestCase):
    def test_altool_one_means_one_attempt_even_for_a_retryable_timeout(self):
        from codemagic.models.altool.altool import Altool, AltoolCommandError
        tool = object.__new__(Altool)
        tool.logger = Mock()
        with patch.object(tool, 'get_current_cli_app', return_value=None), \
                patch.object(tool, '_run_command', side_effect=AltoolCommandError('timeout', 'synthetic')) as run, \
                patch.object(tool, '_should_retry_command', return_value=True), \
                patch.object(tool, '_log_process_output'), \
                patch.object(tool, '_kill_xcode_processes_for_retrying') as kill, \
                patch('time.sleep') as sleep, self.assertRaises(IOError):
            tool._run_retrying_command(['synthetic-no-command'], Path('fixture.ipa'), 'upload', 1, 0.5)
        run.assert_called_once()
        kill.assert_not_called()
        sleep.assert_not_called()

    def test_api_one_stops_on_first_401_or_5xx_instead_of_repeating_write(self):
        import requests
        from codemagic.apple.app_store_connect.api_session import AppStoreConnectApiSession
        from codemagic.apple.app_store_connect.api_error import AppStoreConnectApiError
        for status in (401, 500, 503):
            response = requests.Response()
            response.status_code = status
            response._content = b'{"errors": []}'
            with self.subTest(status=status), \
                    patch('codemagic.apple.app_store_connect.api_session.log.get_logger', return_value=Mock()), \
                    patch('codemagic.apple.app_store_connect.api_session.auditing.save_http_request_audit') as audit, \
                    patch.object(requests.Session, 'request', return_value=response) as request:
                session = AppStoreConnectApiSession(lambda: {}, unauthorized_request_retries=1, server_error_retries=1)
                with self.assertRaises(AppStoreConnectApiError):
                    session.request('POST', 'https://example.invalid/synthetic')
                session.close()
                request.assert_called_once()  # No actual HTTP, including no second POST.
                audit.assert_called_once()


if __name__ == "__main__":
    unittest.main()
