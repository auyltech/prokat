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
        self.write_context('rc', '1.2.3', 23)
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
        self.assertNotIn('PUBLISHER_INVOKED', stdout.getvalue())

    def test_adapter_accepts_valid_argv_only_then_delegates_to_cli(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        with patch.object(adapter.sys, 'argv', ['apple_publish.py', *self.arguments()]), \
                patch.object(AppStoreConnect, 'invoke_cli', is_cli_action=False) as invoke, \
                patch.object(SubmitToAppStoreAction, '_create_or_update_app_store_version_localizations', is_cli_action=False):
            adapter.main()
        invoke.assert_called_once_with()  # The real invoke/upload is never run.

    def test_rc_publish_does_not_install_submission_guards(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        original = SubmitToAppStoreAction._ensure_app_store_version
        with patch.object(adapter.sys, "argv", ["apple_publish.py", *self.arguments()]), \
                patch.object(AppStoreConnect, "invoke_cli", is_cli_action=False):
            adapter.main()
        self.assertIs(SubmitToAppStoreAction._ensure_app_store_version, original)
        self.assertFalse(adapter._GUARD_INSTALLED)

    def write_context(self, channel, version, build):
        prefix = '' if channel == 'production' else 'rc/'
        (self.root / 'build/release/context.json').write_text(json.dumps({
            'platform': 'ios', 'channel': channel, 'version': version, 'build': build,
            'tag': f'{prefix}ios/v{version}+{build}',
            'destination': 'app_store_review' if channel == 'production' else 'testflight',
        }), encoding='utf-8')

    def production_arguments(self):
        self.write_context('production', '1.2.4', 25)
        return store.publish_arguments(
            {'channel': 'production', 'destination': 'app_store_review', 'version': '1.2.4'},
            self.root / 'not-built.ipa')[1:]

    def test_publisher_marker_is_not_success_and_missing_context_skips_cli(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        args = self.production_arguments()
        try:
            with patch.object(adapter.sys, 'argv', ['apple_publish.py', *args]), \
                    patch.object(AppStoreConnect, 'invoke_cli', is_cli_action=False) as invoke, \
                    contextlib.redirect_stdout(io.StringIO()) as stdout:
                adapter.main()
            self.assertIn('PUBLISHER_INVOKED platform=ios tag=ios/v1.2.4+25', stdout.getvalue())
            self.assertNotIn('APPLE_REVIEW_SUBMISSION_CONFIRMED', stdout.getvalue())
            invoke.assert_called_once_with()
            (self.root / 'build/release/context.json').unlink()
            with patch.object(adapter.sys, 'argv', ['apple_publish.py', *args]), \
                    patch.object(AppStoreConnect, 'invoke_cli', is_cli_action=False) as skipped, \
                    contextlib.redirect_stdout(io.StringIO()) as missed, \
                    self.assertRaises(SystemExit) as caught:
                adapter.main()
            skipped.assert_not_called()
            self.assertNotIn('PUBLISHER_INVOKED', missed.getvalue())
            self.assertIn('APPLE_PUBLISH_CONTEXT_INVALID', str(caught.exception))
        finally:
            adapter.restore_submission_guards()

    def test_production_main_installs_all_four_guards_before_cli(self):
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.action_groups.review_submission_items_actions_group import ReviewSubmissionItemsActionGroup
        from codemagic.tools.app_store_connect.action_groups.review_submissions_actions_group import ReviewSubmissionsActionGroup
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        observed = {}

        def invoke():
            observed["ensure"] = SubmitToAppStoreAction._ensure_app_store_version
            observed["submission"] = SubmitToAppStoreAction._create_review_submission
            observed["item"] = ReviewSubmissionItemsActionGroup.create_review_submission_item
            observed["confirm"] = ReviewSubmissionsActionGroup.confirm_review_submission
            observed["installed"] = adapter._GUARD_INSTALLED

        original_localizations = SubmitToAppStoreAction._create_or_update_app_store_version_localizations
        try:
            with patch.object(adapter.sys, "argv", ["apple_publish.py", *self.production_arguments()]), \
                    patch.object(AppStoreConnect, "invoke_cli", side_effect=invoke, is_cli_action=False):
                adapter.main()
            self.assertTrue(self.production_arguments().count("--app-store") == 1)
            self.assertIs(observed["ensure"], adapter.guarded_ensure_version)
            self.assertIs(observed["submission"], adapter.guarded_create_submission)
            self.assertIs(observed["item"], adapter.guarded_create_item)
            self.assertIs(observed["confirm"], adapter.guarded_confirm)
            self.assertIs(AppStoreConnect._ensure_app_store_version, adapter.guarded_ensure_version)
            self.assertIs(AppStoreConnect._create_review_submission, adapter.guarded_create_submission)
            self.assertIs(AppStoreConnect.create_review_submission_item, adapter.guarded_create_item)
            self.assertIs(AppStoreConnect.confirm_review_submission, adapter.guarded_confirm)
            self.assertTrue(observed["installed"])
        finally:
            adapter.restore_submission_guards()
            SubmitToAppStoreAction._create_or_update_app_store_version_localizations = original_localizations

    def test_production_main_submit_uses_guards_and_stops_before_mutation(self):
        from codemagic.apple.resources import Platform
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        from codemagic.tools.app_store_connect.arguments import AppStoreVersionInfo
        from codemagic.tools.app_store_connect.errors import AppStoreConnectError
        client = Mock()
        app = SimpleNamespace(id="6817078475", attributes=SimpleNamespace(primaryLocale="ru"))
        build = SimpleNamespace(id="build-1")
        action = AppStoreConnect.__new__(AppStoreConnect)
        action.logger = Mock()
        action.echo = Mock()
        action.printer = Mock()
        action.create_app_store_version = Mock()
        action._update_existing_app_store_version = Mock()
        client.builds.read_with_include.return_value = (build, app)
        client.apps.list_app_store_versions_data.return_value = [{
            "id": "foreign-version",
            "attributes": {"versionString": "1.0.0", "platform": "IOS",
                           "appStoreState": "IN_REVIEW", "appVersionState": "READY_FOR_DISTRIBUTION"}}]
        client.review_submissions.list.return_value = []
        client.review_submissions.create = Mock()
        info = AppStoreVersionInfo(platform=Platform.IOS, version_string="1.2.4")

        def invoke():
            self.assertIs(SubmitToAppStoreAction._ensure_app_store_version, adapter.guarded_ensure_version)
            logged = []
            with patch.object(AppStoreConnect, "api_client", client), \
                    contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr:
                try:
                    action._submit_to_app_store(
                        "build-1", max_processing_minutes=0, app_store_version_info=info,
                        app_store_version_localization_infos=[], cancel_previous_submissions=False, phased_release=None)
                except AppStoreConnectError as error:
                    logged.append(error.message)
                except SystemExit as error:
                    logged.append(str(error))
            self.assertEqual(logged, [
                "BLOCKED: APPLE_VERSION_IN_FLIGHT; no further App Store mutation. Inspect build uploads; no reupload"])
            self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", stdout.getvalue() + stderr.getvalue())
            action.logger.error.assert_not_called()

        original_localizations = SubmitToAppStoreAction._create_or_update_app_store_version_localizations
        try:
            with patch.object(adapter.sys, "argv", ["apple_publish.py", *self.production_arguments()]), \
                    patch.object(AppStoreConnect, "invoke_cli", side_effect=invoke, is_cli_action=False):
                adapter.main()
        finally:
            adapter.restore_submission_guards()
            SubmitToAppStoreAction._create_or_update_app_store_version_localizations = original_localizations
        action.create_app_store_version.assert_not_called()
        action._update_existing_app_store_version.assert_not_called()
        client.review_submissions.create.assert_not_called()

    def test_production_main_submit_confirms_only_through_installed_guards(self):
        from codemagic.apple.resources import Platform
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        from codemagic.tools.app_store_connect.arguments import AppStoreVersionInfo, AppStoreVersionLocalizationInfo
        order = []
        client = Mock()
        app = SimpleNamespace(id="6817078475", attributes=SimpleNamespace(primaryLocale="ru"))
        build = SimpleNamespace(id="build-1")
        action = AppStoreConnect.__new__(AppStoreConnect)
        action.logger = Mock()
        action.echo = Mock()
        action.printer = Mock()
        action._get_existing_app_store_version_localizations = Mock(return_value={"ru": "locale-ru"})
        action._is_first_app_store_version = Mock(return_value=True)
        action._update_existing_app_store_version = Mock(side_effect=AssertionError("version update"))
        action.create_app_store_version = Mock(side_effect=lambda *args, **kwargs: (
            order.append("create-version") or SimpleNamespace(
                id="version-new", created=True,
                attributes=SimpleNamespace(versionString="1.2.4", platform=Platform.IOS))))
        client.builds.read_with_include.return_value = (build, app)
        client.apps.list_app_store_versions_data.side_effect = lambda *args, **kwargs: order.append("versions") or []
        client.review_submissions.list.side_effect = lambda *args, **kwargs: order.append("submissions") or []
        client.review_submissions.read = Mock(side_effect=AssertionError("reuse"))
        client.review_submissions.create.side_effect = lambda *args, **kwargs: (
            order.append("create-submission") or SimpleNamespace(id="submission-new", created=True))
        client.review_submissions_items.create.side_effect = lambda *args, **kwargs: (
            order.append("create-item") or SimpleNamespace(id="item-1", created=True))
        client.review_submissions.modify.side_effect = lambda *args, **kwargs: (
            order.append("confirm") or SimpleNamespace(id="submission-new"))
        client.review_submissions.list_items.side_effect = lambda *args, **kwargs: (
            order.append("items") or [SimpleNamespace(id="item-1")])
        info = AppStoreVersionInfo(platform=Platform.IOS, version_string="1.2.4")

        def invoke():
            self.assertIs(SubmitToAppStoreAction._ensure_app_store_version, adapter.guarded_ensure_version)
            self.assertIs(SubmitToAppStoreAction._create_review_submission, adapter.guarded_create_submission)
            with patch.object(AppStoreConnect, "api_client", client), contextlib.redirect_stdout(io.StringIO()) as output:
                action._submit_to_app_store(
                    "build-1", max_processing_minutes=0, app_store_version_info=info,
                    app_store_version_localization_infos=[AppStoreVersionLocalizationInfo(whats_new="Synthetic")],
                    cancel_previous_submissions=False, phased_release=None)
            self.assertIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", output.getvalue())

        original_localizations = SubmitToAppStoreAction._create_or_update_app_store_version_localizations
        try:
            with patch.object(adapter.sys, "argv", ["apple_publish.py", *self.production_arguments()]), \
                    patch.object(AppStoreConnect, "invoke_cli", side_effect=invoke, is_cli_action=False):
                adapter.main()
        finally:
            adapter.restore_submission_guards()
            SubmitToAppStoreAction._create_or_update_app_store_version_localizations = original_localizations
        self.assertEqual(order, [
            "versions", "submissions", "create-version", "submissions", "create-submission",
            "create-item", "items", "confirm", "items"])
        self.assertEqual(action.create_app_store_version.call_count, 1)
        self.assertEqual(client.review_submissions.create.call_count, 1)
        self.assertEqual(client.review_submissions_items.create.call_count, 1)
        self.assertEqual(client.review_submissions.modify.call_count, 1)
        action._update_existing_app_store_version.assert_not_called()
        client.review_submissions.read.assert_not_called()

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


class SubmissionGuardTests(unittest.TestCase):
    def setUp(self):
        adapter._reset_guard()
        self.app = SimpleNamespace(id="6817078475")
        self.build = SimpleNamespace(id="build-1")
        self.info = SimpleNamespace(version_string="1.2.4", platform="IOS", copyright=None,
                                    earliest_release_date=None, release_type=None)
        self.client = Mock()
        self.action = SimpleNamespace(
            api_client=self.client,
            create_app_store_version=Mock(),
            _update_existing_app_store_version=Mock(),
        )
        self.client.apps.list_app_store_versions_data.return_value = []
        self.client.review_submissions.list.return_value = []
        self.client.review_submissions.read = Mock()
        self.client.review_submissions.create = Mock()

    def tearDown(self):
        adapter.restore_submission_guards()

    def version(self, store_state, version_state, version_string="1.0.0", identifier="version-1"):
        return {"id": identifier, "attributes": {
            "versionString": version_string, "platform": "IOS",
            "appStoreState": store_state, "appVersionState": version_state}}

    def test_changed_version_blocks_before_either_mutation(self):
        for row in (self.version("IN_REVIEW", "READY_FOR_DISTRIBUTION"),
                    self.version("WAITING_FOR_REVIEW", "WAITING_FOR_REVIEW"),
                    self.version("PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION", "9.9.9")):
            self.client.apps.list_app_store_versions_data.return_value = [row]
            with self.subTest(row=row), self.assertRaises(SystemExit):
                adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
            self.action.create_app_store_version.assert_not_called()
            self.action._update_existing_app_store_version.assert_not_called()

    def test_open_submission_blocks_before_version_mutation(self):
        self.client.review_submissions.list.return_value = [
            SimpleNamespace(id="other", attributes=SimpleNamespace(platform="IOS", state="READY_FOR_REVIEW"))]
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        self.assertIn("APPLE_REVIEW_SUBMISSION_OPEN", str(caught.exception))
        self.action.create_app_store_version.assert_not_called()
        self.action._update_existing_app_store_version.assert_not_called()

    def test_create_is_the_only_version_mutation_when_none_exists(self):
        created = SimpleNamespace(id="version-new", created=True, attributes=SimpleNamespace(versionString="1.2.4"))
        self.action.create_app_store_version.return_value = created
        result = adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        self.assertIs(result, created)
        self.action.create_app_store_version.assert_called_once()
        self.action._update_existing_app_store_version.assert_not_called()
        self.assertEqual(adapter._GUARD.version_id, "version-new")

    def test_approved_version_is_updated_once_by_its_id(self):
        self.client.apps.list_app_store_versions_data.return_value = [
            self.version("PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION", "1.2.4", "version-approved")]
        updated = SimpleNamespace(id="version-approved", created=False, attributes=SimpleNamespace(versionString="1.2.4"))
        self.action._update_existing_app_store_version.return_value = updated
        adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        self.action.create_app_store_version.assert_not_called()
        self.action._update_existing_app_store_version.assert_called_once()
        self.assertEqual(self.action._update_existing_app_store_version.call_args.args[0].id, "version-approved")

    def test_open_submission_blocks_create_before_post(self):
        adapter._GUARD.version_id = "version-new"
        self.client.review_submissions.list.return_value = [
            SimpleNamespace(id="other", attributes=SimpleNamespace(platform="IOS", state="READY_FOR_REVIEW"))]
        with self.assertRaises(SystemExit):
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        self.client.review_submissions.create.assert_not_called()
        self.client.review_submissions.read.assert_not_called()

    def test_reused_submission_error_does_not_read_or_continue(self):
        adapter._GUARD.version_id = "version-new"
        self.client.review_submissions.create.side_effect = RuntimeError("another reviewSubmissions with id SECRET still in progress")
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        self.client.review_submissions.read.assert_not_called()
        self.assertNotIn("SECRET", str(caught.exception))
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))

    def test_foreign_or_repeated_item_is_not_posted(self):
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._ORIGINAL_ITEM = Mock()
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, "other-submission", app_store_version_id="version-new")
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="other-version")
        adapter._GUARD.item_id = "item-1"
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new")
        adapter._ORIGINAL_ITEM.assert_not_called()

    def assert_outcome_unknown(self, call, mutation):
        from codemagic.tools.app_store_connect.errors import AppStoreConnectError
        logged = []
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr:
            try:
                call()
            except AppStoreConnectError as error:
                logged.append(error.message)
            except SystemExit as error:
                logged.append(str(error))
        rendered = stdout.getvalue() + stderr.getvalue() + "".join(logged)
        self.assertNotIn("SECRET_SENTINEL", rendered)
        self.assertEqual(logged, [
            "BLOCKED: APPLE_SUBMISSION_OUTCOME_UNKNOWN; no further App Store mutation. Inspect build uploads; no reupload"])
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(mutation.call_count, 1)

    def test_mutation_errors_are_unknown_and_hide_the_response_body(self):
        from codemagic.tools.app_store_connect.errors import AppStoreConnectError
        secret = AppStoreConnectError("SECRET_SENTINEL")
        self.action.create_app_store_version.side_effect = secret
        self.assert_outcome_unknown(
            lambda: adapter.guarded_ensure_version(self.action, self.app, self.build, self.info),
            self.action.create_app_store_version)
        self.assertIsNone(adapter._GUARD.version_id)
        adapter._reset_guard()
        self.client.apps.list_app_store_versions_data.return_value = [
            self.version("PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION", "1.2.4", "version-approved")]
        self.action._update_existing_app_store_version.side_effect = secret
        self.assert_outcome_unknown(
            lambda: adapter.guarded_ensure_version(self.action, self.app, self.build, self.info),
            self.action._update_existing_app_store_version)
        adapter._reset_guard()
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._ORIGINAL_ITEM = Mock(side_effect=secret)
        self.assert_outcome_unknown(
            lambda: adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new"),
            adapter._ORIGINAL_ITEM)
        self.assertIsNone(adapter._GUARD.item_id)
        adapter._GUARD.item_id = "item-1"
        adapter._ORIGINAL_CONFIRM = Mock(side_effect=secret)
        self.client.review_submissions.list_items.return_value = [SimpleNamespace(id="item-1")]
        self.assert_outcome_unknown(
            lambda: adapter.guarded_confirm(self.action, "submission-new"),
            adapter._ORIGINAL_CONFIRM)
        self.assertEqual(self.client.review_submissions.list_items.call_count, 1)

    def test_submission_create_exception_is_unknown_and_stops_the_chain(self):
        from codemagic.tools.app_store_connect.errors import AppStoreConnectError
        adapter._GUARD.version_id = "version-new"
        adapter._ORIGINAL_ITEM = Mock()
        adapter._ORIGINAL_CONFIRM = Mock()
        self.client.review_submissions.create.side_effect = AppStoreConnectError("SECRET_SENTINEL")
        self.assert_outcome_unknown(
            lambda: adapter.guarded_create_submission(self.action, self.app, "IOS"),
            self.client.review_submissions.create)
        self.client.review_submissions.read.assert_not_called()
        adapter._ORIGINAL_ITEM.assert_not_called()
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.assertIsNone(adapter._GUARD.submission_id)

    def test_unexpected_mutation_results_are_unknown_and_do_not_continue(self):
        secret = "SECRET_SENTINEL"
        self.action.create_app_store_version.return_value = SimpleNamespace(
            id="version-new", created=False, attributes=SimpleNamespace(versionString=secret))
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn(secret, rendered)
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(self.action.create_app_store_version.call_count, 1)
        self.action._update_existing_app_store_version.assert_not_called()
        self.assertIsNone(adapter._GUARD.version_id)
        self.client.review_submissions.create.assert_not_called()

        adapter._reset_guard()
        self.action.create_app_store_version.reset_mock()
        self.client.apps.list_app_store_versions_data.return_value = [
            self.version("PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION", "1.2.4", "version-approved")]
        self.action._update_existing_app_store_version.return_value = SimpleNamespace(
            id=secret, created=False, attributes=SimpleNamespace(versionString="1.2.4"))
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn(secret, rendered)
        self.assertEqual(self.action._update_existing_app_store_version.call_count, 1)
        self.action.create_app_store_version.assert_not_called()
        self.assertIsNone(adapter._GUARD.version_id)

        adapter._reset_guard()
        self.action._update_existing_app_store_version.reset_mock()
        self.client.apps.list_app_store_versions_data.return_value = []
        self.action.create_app_store_version.return_value = SimpleNamespace(
            id="version-new", created=True, attributes=SimpleNamespace(versionString=secret))
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn(secret, rendered)
        self.assertEqual(self.action.create_app_store_version.call_count, 1)
        self.assertIsNone(adapter._GUARD.version_id)

        adapter._reset_guard()
        self.action.create_app_store_version.reset_mock()
        self.action.create_app_store_version.return_value = SimpleNamespace(
            id=None, created=True, attributes=SimpleNamespace(versionString="1.2.4"))
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertEqual(self.action.create_app_store_version.call_count, 1)
        self.assertIsNone(adapter._GUARD.version_id)

        adapter._reset_guard()
        adapter._GUARD.version_id = "version-new"
        self.client.review_submissions.create.return_value = SimpleNamespace(id=secret, created=False)
        adapter._ORIGINAL_ITEM = Mock()
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn(secret, rendered)
        self.assertEqual(self.client.review_submissions.create.call_count, 1)
        adapter._ORIGINAL_ITEM.assert_not_called()
        self.assertIsNone(adapter._GUARD.submission_id)

        adapter._GUARD.submission_id = "submission-new"
        adapter._ORIGINAL_ITEM = Mock(return_value=SimpleNamespace(id=secret, created=False))
        adapter._ORIGINAL_CONFIRM = Mock()
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new")
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn(secret, rendered)
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(adapter._ORIGINAL_ITEM.call_count, 1)
        self.assertIsNone(adapter._GUARD.item_id)
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertIn("APPLE_SUBMISSION_GUARD_FAILED", str(caught.exception))
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.client.review_submissions.list_items.assert_not_called()

    def test_updated_version_marked_created_with_the_same_id_is_unknown(self):
        self.client.apps.list_app_store_versions_data.return_value = [
            self.version("PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION", "1.2.4", "version-approved")]
        self.action._update_existing_app_store_version.return_value = SimpleNamespace(
            id="version-approved", created=True, attributes=SimpleNamespace(versionString="1.2.4"))
        adapter._ORIGINAL_ITEM = Mock()
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(self.action._update_existing_app_store_version.call_count, 1)
        self.assertEqual(self.action._update_existing_app_store_version.call_args.args[0].id, "version-approved")
        self.assertTrue(self.action._update_existing_app_store_version.return_value.created)
        self.assertEqual(self.action._update_existing_app_store_version.return_value.id, "version-approved")
        self.action.create_app_store_version.assert_not_called()
        self.assertIsNone(adapter._GUARD.version_id)
        with self.assertRaises(SystemExit) as next_step:
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        self.assertIn("APPLE_SUBMISSION_GUARD_FAILED", str(next_step.exception))
        self.client.review_submissions.create.assert_not_called()
        adapter._ORIGINAL_ITEM.assert_not_called()

    def test_created_submission_without_id_is_unknown_and_stops(self):
        adapter._GUARD.version_id = "version-new"
        self.client.review_submissions.create.return_value = SimpleNamespace(id="", created=True)
        adapter._ORIGINAL_ITEM = Mock()
        adapter._ORIGINAL_CONFIRM = Mock()
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(self.client.review_submissions.create.call_count, 1)
        self.assertTrue(self.client.review_submissions.create.return_value.created)
        self.assertEqual(self.client.review_submissions.create.return_value.id, "")
        self.assertIsNone(adapter._GUARD.submission_id)
        adapter._ORIGINAL_ITEM.assert_not_called()
        adapter._ORIGINAL_CONFIRM.assert_not_called()

    def test_created_item_without_id_is_unknown_and_stops(self):
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._ORIGINAL_ITEM = Mock(return_value=SimpleNamespace(id=None, created=True))
        adapter._ORIGINAL_CONFIRM = Mock()
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new")
        rendered = str(caught.exception) + stdout.getvalue() + stderr.getvalue()
        self.assertIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertEqual(adapter._ORIGINAL_ITEM.call_count, 1)
        self.assertTrue(adapter._ORIGINAL_ITEM.return_value.created)
        self.assertIsNone(adapter._ORIGINAL_ITEM.return_value.id)
        self.assertIsNone(adapter._GUARD.item_id)
        with self.assertRaises(SystemExit) as next_step:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertIn("APPLE_SUBMISSION_GUARD_FAILED", str(next_step.exception))
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.client.review_submissions.list_items.assert_not_called()

    def test_pre_mutation_refusal_stays_guard_failed(self):
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_create_submission(self.action, self.app, "IOS")
        self.assertIn("APPLE_SUBMISSION_GUARD_FAILED", str(caught.exception))
        self.assertNotIn("APPLE_SUBMISSION_OUTCOME_UNKNOWN", str(caught.exception))
        self.client.review_submissions.create.assert_not_called()

    def test_item_and_confirm_require_bound_identifiers_before_mutation(self):
        adapter._ORIGINAL_ITEM = Mock()
        adapter._ORIGINAL_CONFIRM = Mock()
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, None, app_store_version_id=None)
        adapter._GUARD.submission_id = "submission-new"
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new")
        adapter._reset_guard()
        adapter._GUARD.version_id = "version-new"
        with self.assertRaises(SystemExit):
            adapter.guarded_create_item(self.action, None, app_store_version_id="version-new")
        adapter._GUARD.item_id = "item-1"
        with self.assertRaises(SystemExit):
            adapter.guarded_confirm(self.action, None)
        adapter._ORIGINAL_ITEM.assert_not_called()
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.client.review_submissions.list_items.assert_not_called()

    def test_confirm_foreign_submission_or_missing_item_does_not_patch(self):
        adapter._ORIGINAL_CONFIRM = Mock()
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        with self.assertRaises(SystemExit):
            adapter.guarded_confirm(self.action, "submission-new")
        adapter._GUARD.item_id = "item-1"
        with self.assertRaises(SystemExit):
            adapter.guarded_confirm(self.action, "other-submission")
        self.client.review_submissions.list_items.return_value = [SimpleNamespace(id="foreign")]
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertIn("APPLE_SUBMISSION_ITEMS_CHANGED", str(caught.exception))
        adapter._ORIGINAL_CONFIRM.assert_not_called()

    def test_happy_path_performs_each_mutation_once(self):
        created_version = SimpleNamespace(id="version-new", created=True, attributes=SimpleNamespace(versionString="1.2.4"))
        self.action.create_app_store_version.return_value = created_version
        created_submission = SimpleNamespace(id="submission-new", created=True)
        self.client.review_submissions.create.return_value = created_submission
        adapter._ORIGINAL_ITEM = Mock(return_value=SimpleNamespace(id="item-1", created=True))
        adapter._ORIGINAL_CONFIRM = Mock(return_value=SimpleNamespace(id="submission-new"))
        self.client.review_submissions.list_items.side_effect = [
            [SimpleNamespace(id="item-1")], [SimpleNamespace(id="item-1")]]
        adapter.guarded_ensure_version(self.action, self.app, self.build, self.info)
        adapter.guarded_create_submission(self.action, self.app, "IOS")
        adapter.guarded_create_item(self.action, "submission-new", app_store_version_id="version-new")
        with contextlib.redirect_stdout(io.StringIO()) as output:
            adapter.guarded_confirm(self.action, "submission-new")
        self.action.create_app_store_version.assert_called_once()
        self.action._update_existing_app_store_version.assert_not_called()
        self.client.review_submissions.create.assert_called_once()
        self.client.review_submissions.read.assert_not_called()
        adapter._ORIGINAL_ITEM.assert_called_once()
        adapter._ORIGINAL_CONFIRM.assert_called_once()
        self.assertEqual(self.client.review_submissions.list_items.call_count, 2)
        self.assertIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", output.getvalue())

    def test_confirm_rereads_items_before_patch_and_after_patch(self):
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._GUARD.item_id = "item-1"
        adapter._ORIGINAL_CONFIRM = Mock(return_value=SimpleNamespace(id="submission-new"))
        self.client.review_submissions.list_items.return_value = [SimpleNamespace(id="item-1"), SimpleNamespace(id="foreign")]
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertIn("APPLE_SUBMISSION_ITEMS_CHANGED", str(caught.exception))
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.client.review_submissions.list_items.side_effect = RuntimeError("PRIVATE_BODY")
        with self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertNotIn("PRIVATE_BODY", str(caught.exception))
        adapter._ORIGINAL_CONFIRM.assert_not_called()
        self.client.review_submissions.list_items.side_effect = [
            [SimpleNamespace(id="item-1")], [SimpleNamespace(id="item-1"), SimpleNamespace(id="extra")]]
        with contextlib.redirect_stdout(io.StringIO()) as output, self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertEqual(caught.exception.code, 1)
        self.assertIn("APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM", output.getvalue())
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", output.getvalue())
        adapter._ORIGINAL_CONFIRM.assert_called_once()

    def test_post_confirm_read_exception_is_not_success(self):
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._GUARD.item_id = "item-1"
        adapter._ORIGINAL_CONFIRM = Mock(return_value=SimpleNamespace(id="submission-new"))
        adapter._ORIGINAL_ITEM = Mock()
        self.action.create_app_store_version = Mock()
        self.client.review_submissions.create = Mock()
        self.client.review_submissions.list_items.side_effect = [
            [SimpleNamespace(id="item-1")], RuntimeError("SECRET_SENTINEL")]
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr, \
                self.assertRaises(SystemExit) as caught:
            adapter.guarded_confirm(self.action, "submission-new")
        rendered = stdout.getvalue() + stderr.getvalue() + str(caught.exception)
        self.assertNotEqual(caught.exception.code, 0)
        self.assertIn("APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM", stdout.getvalue())
        self.assertNotIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", rendered)
        self.assertNotIn("APPLE_SUBMISSION_GUARD_FAILED", rendered)
        self.assertNotIn("SECRET_SENTINEL", rendered)
        adapter._ORIGINAL_CONFIRM.assert_called_once()
        self.assertEqual(self.client.review_submissions.list_items.call_count, 2)
        adapter._ORIGINAL_ITEM.assert_not_called()
        self.action.create_app_store_version.assert_not_called()
        self.client.review_submissions.create.assert_not_called()

    def test_happy_path_confirms_only_after_the_second_item_read(self):
        adapter._GUARD.version_id = "version-new"
        adapter._GUARD.submission_id = "submission-new"
        adapter._GUARD.item_id = "item-1"
        adapter._ORIGINAL_CONFIRM = Mock(return_value=SimpleNamespace(id="submission-new"))
        self.client.review_submissions.list_items.side_effect = [
            [SimpleNamespace(id="item-1")], [SimpleNamespace(id="item-1")]]
        with contextlib.redirect_stdout(io.StringIO()) as output:
            adapter.guarded_confirm(self.action, "submission-new")
        self.assertEqual(self.client.review_submissions.list_items.call_count, 2)
        self.assertIn("APPLE_REVIEW_SUBMISSION_CONFIRMED", output.getvalue())
        adapter._ORIGINAL_CONFIRM.assert_called_once()

    def test_version_guard_rejects_a_changed_signature_before_cli_invocation(self):
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        original = SubmitToAppStoreAction._ensure_app_store_version
        SubmitToAppStoreAction._ensure_app_store_version = lambda self: None
        try:
            with self.assertRaisesRegex(adapter.PublishCliError, "^APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED$"):
                adapter.install_submission_guards()
        finally:
            SubmitToAppStoreAction._ensure_app_store_version = original
        self.assertFalse(adapter._GUARD_INSTALLED)

    def test_version_guard_rejects_a_missing_method_before_cli_invocation(self):
        from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
        original = SubmitToAppStoreAction._ensure_app_store_version
        del SubmitToAppStoreAction._ensure_app_store_version
        try:
            with self.assertRaisesRegex(adapter.PublishCliError, "^APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED$"):
                adapter.install_submission_guards()
        finally:
            SubmitToAppStoreAction._ensure_app_store_version = original
        self.assertFalse(adapter._GUARD_INSTALLED)


if __name__ == "__main__":
    unittest.main()
