import contextlib
import urllib.error
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

import ios_store as store


class AppleStorePolicyTests(unittest.TestCase):
    def setUp(self):
        self.rc = {"platform": "ios", "channel": "rc", "destination": "testflight", "version": "1.8.0", "build": 108}

    def test_new_build(self):
        store.check_builds(self.rc, [{"id": "old", "attributes": {"version": "107", "processingState": "VALID"}}], [], 100)

    def test_rc_group_must_exist_and_be_internal(self):
        group = {"id": "fixture", "attributes": {"name": store.RC_GROUP, "isInternalGroup": True, "hasAccessToAllBuilds": True}}
        self.assertEqual(store.check_internal_group([group], store.RC_GROUP), "fixture")
        for groups, name in (([], None), ([], store.RC_GROUP), ([group], "typo"),
                             ([group, group], store.RC_GROUP),
                             ([{**group, "attributes": {**group["attributes"], "isInternalGroup": False}}], store.RC_GROUP)):
            with self.subTest(groups=groups, name=name), self.assertRaises(store.Blocked):
                store.check_internal_group(groups, name)

    def test_access_mode_needs_no_tag_and_never_invokes_publisher(self):
        with patch.object(store.sys, "argv", ["ios_store.py", "access"]), patch.object(store, "preflight") as read, \
                patch.object(store.subprocess, "run") as publish, contextlib.redirect_stdout(io.StringIO()) as output:
            store.main()
            read.assert_called_once_with()
            publish.assert_not_called()
            self.assertIn("APPLE_ACCESS_VERIFIED", output.getvalue())

    def test_access_failure_never_reports_success_or_invokes_publisher(self):
        with patch.object(store.sys, "argv", ["ios_store.py", "access"]), \
                patch.object(store, "preflight", side_effect=TimeoutError), patch.object(store.subprocess, "run") as publish, \
                contextlib.redirect_stdout(io.StringIO()) as output, self.assertRaises(TimeoutError):
            store.main()
        publish.assert_not_called()
        self.assertNotIn("VERIFIED", output.getvalue())

    def test_production_gate_blocks_before_api_or_publisher(self):
        context = {**self.rc, "channel": "production", "destination": "app_store_review", "tag": "ios/v1.8.0+108"}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "build/release").mkdir(parents=True)
            (root / "build/release/context.json").write_text(json.dumps(context))
            for gate in ("", "false", "TRUE", "1"):
                env = {"CM_BUILD_ID": "fixture", "CM_TAG": context["tag"], "PRODUCTION_PUBLISHING_ENABLED": gate}
                with self.subTest(gate=gate), patch.object(store, "ROOT", root), patch.dict(store.os.environ, env, clear=True), \
                        patch.object(store.sys, "argv", ["ios_store.py", "publish"]), patch.object(store, "preflight") as read, \
                        patch.object(store.subprocess, "run") as publish, self.assertRaises(store.Blocked):
                    store.main()
                read.assert_not_called()
                publish.assert_not_called()

    def test_rc_publish_delegates_to_pinned_adapter_after_fresh_preflight(self):
        context = {**self.rc, "tag": "rc/ios/v1.8.0+108"}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "build/release").mkdir(parents=True)
            (root / "build/release/context.json").write_text(json.dumps(context))
            (root / "build/ios/ipa").mkdir(parents=True)
            (root / "build/ios/ipa/fixture.ipa").touch()  # Empty fixture, never a signed binary.
            (root / "build/release/apple-localizations.json").write_text(
                json.dumps([{"locale": "ru", "whats_new": "Synthetic Git notes"}]))
            env = {"CM_BUILD_ID": "fixture", "CM_TAG": context["tag"], "TESTFLIGHT_GROUP": store.RC_GROUP}
            with patch.object(store, "ROOT", root), patch.dict(store.os.environ, env, clear=True), \
                    patch.object(store.sys, "argv", ["ios_store.py", "publish"]), patch.object(store, "preflight") as read, \
                    patch.object(store, "confirm_testflight_distribution") as confirm, \
                    patch.object(store.subprocess, "run") as publish, \
                    contextlib.redirect_stdout(io.StringIO()):
                read.return_value = {"automatic_group_id": "fixture"}
                publish.side_effect = lambda *a, **k: (read.assert_called_once_with(context) or SimpleNamespace(returncode=0))
                store.main()
                args = publish.call_args.args[0]
                self.assertEqual(args[1], str(root / "tool/release/apple_publish.py"))
                self.assertNotIn("--beta-group", args)
                self.assertNotIn("--app-store", args)
                confirm.assert_called_once_with(context, "fixture")

    def test_real_preflight_flow_uses_fresh_complete_reads_and_internal_group(self):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        env = {"APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000", "PROKAT_ASC_PRIVATE_KEY_PEM": pem,
               "APP_STORE_CONNECT_PRIVATE_KEY": "@file:/synthetic-cli-only-reference",
               "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "APP_STORE_APP_ID": store.RC_APP_ID,
               "IOS_HISTORICAL_MAX_BUILD": "100", "TESTFLIGHT_GROUP": store.RC_GROUP}
        app = {"data": {"id": store.RC_APP_ID, "attributes": {"bundleId": "com.auyltech.prokat", "primaryLocale": "ru"}}}
        groups = [{"id": "fixture", "attributes": {"name": store.RC_GROUP, "isInternalGroup": True, "hasAccessToAllBuilds": True}}]
        with tempfile.TemporaryDirectory() as directory, patch.object(store, "ROOT", Path(directory)), \
                patch.dict(store.os.environ, env, clear=True), \
                patch.object(store, "get_json", return_value=app), \
                patch.object(store, "all_pages", side_effect=[[], [], groups, [], [], groups]) as pages, \
                contextlib.redirect_stdout(io.StringIO()):
            store.preflight(self.rc)
            store.preflight(self.rc)
            self.assertEqual(pages.call_count, 6)  # No cache between pre-build and pre-upload.
            self.assertEqual(pages.call_args_list[2].args[0], f"/v1/apps/{store.RC_APP_ID}/betaGroups?limit=200")
            self.assertTrue((Path(directory) / "build/release/apple-state.json").is_file())

    def test_publish_stops_on_isolated_auth_or_unknown_store_without_publisher(self):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        context = {**self.rc, "tag": "rc/ios/v1.8.0+108"}
        base = {"CM_BUILD_ID": "fixture", "CM_TAG": context["tag"],
                "APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000",
                "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "APP_STORE_CONNECT_PRIVATE_KEY": pem,
                "APP_STORE_APP_ID": store.RC_APP_ID, "IOS_HISTORICAL_MAX_BUILD": "100", "TESTFLIGHT_GROUP": store.RC_GROUP}
        cases = ((None, "APPLE_ENV_MISSING"), ("@file:/synthetic-unread-key", "APPLE_PEM_INVALID"),
                 ("@env:SYNTHETIC_UNREAD_KEY", "APPLE_PEM_INVALID"), (pem, "APPLE_API_UNAVAILABLE"))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "build/release").mkdir(parents=True)
            (root / "build/release/context.json").write_text(json.dumps(context))
            for isolated, expected in cases:
                env = dict(base)
                if isolated is not None:
                    env["PROKAT_ASC_PRIVATE_KEY_PEM"] = isolated
                with self.subTest(code=expected), patch.object(store, "ROOT", root), \
                        patch.dict(store.os.environ, env, clear=True), \
                        patch.object(store.sys, "argv", ["ios_store.py", "publish"]), \
                        patch.object(store, "get_json", side_effect=store.AppleCheckFailure(
                            "APPLE_API_UNAVAILABLE", "app", "timeout")) as get, \
                        patch.object(store.subprocess, "run") as publisher, \
                        self.assertRaises(store.AppleCheckFailure) as caught:
                    store.main()
                self.assertEqual(caught.exception.code, expected)
                publisher.assert_not_called()
                if expected == "APPLE_API_UNAVAILABLE":
                    get.assert_called_once()
                else:
                    get.assert_not_called()
                self.assertFalse((root / "build/release/apple-state.json").exists())

    def test_release_preflight_normalizes_upload_state_without_detail_leaks(self):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        env = {"APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000",
               "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "PROKAT_ASC_PRIVATE_KEY_PEM": pem,
               "APP_STORE_APP_ID": store.RC_APP_ID, "IOS_HISTORICAL_MAX_BUILD": "17", "TESTFLIGHT_GROUP": store.RC_GROUP}
        app = {"data": {"id": store.RC_APP_ID, "attributes": {"bundleId": "com.auyltech.prokat", "primaryLocale": "ru"}}}
        upload = {"id": "old-upload", "attributes": {"cfBundleVersion": "18", "state": {
            "state": "FAILED", "errors": [{"code": "PRIVATE_UPLOAD_DETAIL", "description": "PRIVATE_UPLOAD_DETAIL"}]}}}
        groups = [{"id": "group", "attributes": {"name": store.RC_GROUP, "isInternalGroup": True, "hasAccessToAllBuilds": True}}]
        for channel in ("rc", "production"):
            context = {**self.rc, "build": 20, "channel": channel,
                       "destination": "testflight" if channel == "rc" else "app_store_review"}
            responses = [app, {"data": [], "links": {}}, {"data": [upload], "links": {}}]
            if channel == "rc":
                responses.append({"data": groups, "links": {}})
            else:
                responses.extend(({"data": [], "links": {}}, {"data": [], "links": {}}))
            with self.subTest(channel=channel), tempfile.TemporaryDirectory() as directory, \
                    patch.object(store, "ROOT", Path(directory)), patch.dict(store.os.environ, env, clear=True), \
                    patch.object(store, "get_json", side_effect=responses) as get, \
                    patch.object(store.subprocess, "run") as publisher, \
                    contextlib.redirect_stdout(io.StringIO()) as output:
                state = store.preflight(context)
                snapshot = (Path(directory) / "build/release/apple-state.json").read_text(encoding="utf-8")
            self.assertEqual(get.call_count, 4 if channel == "rc" else 5)
            if channel == "production":
                self.assertEqual(get.call_args_list[3].args[0], store.API + store.production_version_path(store.APP_ID))
                self.assertEqual(get.call_args_list[4].args[0], store.API + store.production_submission_path(store.APP_ID))
            else:
                self.assertFalse(any("appStoreVersions" in call.args[0] or "reviewSubmissions" in call.args[0] for call in get.call_args_list))
            self.assertEqual(state["uploads"], [{"id": "old-upload", "attributes": {"cfBundleVersion": "18", "state": "FAILED"}}])
            self.assertEqual(json.loads(snapshot), state)
            self.assertNotIn("PRIVATE_UPLOAD_DETAIL", snapshot + output.getvalue())
            self.assertNotIn("errors", snapshot)
            self.assertIsInstance(upload["attributes"]["state"], dict)  # Do not mutate the API response.
            publisher.assert_not_called()

    def test_invalid_or_occupied_upload_blocks_release_before_publisher(self):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        context = {**self.rc, "build": 20, "tag": "rc/ios/v1.2.3+20"}
        env = {"CM_BUILD_ID": "fixture", "CM_TAG": context["tag"],
               "APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000",
               "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "PROKAT_ASC_PRIVATE_KEY_PEM": pem,
               "APP_STORE_APP_ID": store.RC_APP_ID, "IOS_HISTORICAL_MAX_BUILD": "17", "TESTFLIGHT_GROUP": store.RC_GROUP}
        app = {"data": {"id": store.RC_APP_ID, "attributes": {"bundleId": "com.auyltech.prokat", "primaryLocale": "ru"}}}
        groups = [{"id": "group", "attributes": {"name": store.RC_GROUP, "isInternalGroup": True, "hasAccessToAllBuilds": True}}]
        cases = (({"cfBundleVersion": "18", "state": "COMPLETE"}, "APPLE_RESPONSE_INVALID"),
                 ({"state": {"state": "COMPLETE"}}, "APPLE_RESPONSE_INVALID"),
                 ({"cfBundleVersion": "18", "state": {"state": "UNKNOWN_PRIVATE_DETAIL"}}, "APPLE_RESPONSE_INVALID"),
                 ({"cfBundleVersion": "20", "state": {"state": "FAILED"}}, "APPLE_BUILD_ALREADY_USED"),
                 ({"cfBundleVersion": "21", "state": {"state": "FAILED"}}, "APPLE_BUILD_NOT_INCREASING"))
        for attributes, code in cases:
            with self.subTest(code=code), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / "build/release").mkdir(parents=True)
                (root / "build/release/context.json").write_text(json.dumps(context))
                responses = [app, {"data": [], "links": {}},
                             {"data": [{"id": "upload", "attributes": attributes}], "links": {}},
                             {"data": groups, "links": {}}]
                with patch.object(store, "ROOT", root), patch.dict(store.os.environ, env, clear=True), \
                        patch.object(store.sys, "argv", ["ios_store.py", "publish"]), \
                        patch.object(store, "get_json", side_effect=responses), \
                        patch.object(store.subprocess, "run") as publisher, \
                        contextlib.redirect_stdout(io.StringIO()) as output, \
                        self.assertRaises(store.AppleCheckFailure) as caught:
                    store.main()
                self.assertEqual(caught.exception.code, code)
                self.assertNotIn("UNKNOWN_PRIVATE_DETAIL", str(caught.exception) + output.getvalue())
                publisher.assert_not_called()

    def test_existing_build_in_any_state_blocks(self):
        for state in ("VALID", "PROCESSING", "FAILED", "INVALID"):
            with self.subTest(state=state), self.assertRaises(store.Blocked):
                store.check_builds(self.rc, [{"id": "existing", "attributes": {"version": "108", "processingState": state}}], [], 100)

    def test_inflight_upload_blocks_before_build_resource_exists(self):
        with self.assertRaises(store.Blocked):
            store.check_builds(self.rc, [], [{"id": "upload", "attributes": {"cfBundleVersion": "108", "state": "PROCESSING"}}], 100)

    def test_historical_floor_and_dotted_numbers(self):
        with self.assertRaises(store.Blocked):
            store.check_builds(self.rc, [], [], 108)
        with self.assertRaises(store.Blocked):
            store.check_builds(self.rc, [{"id": "old", "attributes": {"version": "108.1", "processingState": "VALID"}}], [], 100)
        with self.assertRaises(store.Blocked):
            store.build_tuple("unknown")

    def test_rc_does_not_request_app_store_or_external_review(self):
        args = store.publish_arguments(self.rc, "build.ipa", store.RC_GROUP)
        self.assertNotIn("--app-store", args)
        self.assertNotIn("--release-type", args)
        self.assertNotIn("--testflight", args)
        self.assertNotIn("--beta-group", args)
        for flag in ("--altool-retries", "--api-server-error-retries", "--api-unauthorized-retries"):
            self.assertEqual(args[args.index(flag) + 1], "1")

    def test_production_requests_after_approval(self):
        args = store.publish_arguments({**self.rc, "channel": "production", "destination": "app_store_review"}, "build.ipa")
        self.assertEqual(args, ["app-store-connect", "publish", "--path", "build.ipa", "--enable-package-validation",
                               "--altool-retries", "1", "--api-server-error-retries", "1", "--api-unauthorized-retries", "1",
                               "--max-find-build-wait", "10", "--max-build-processing-wait", "20", "--app-store",
                               "--release-type", "AFTER_APPROVAL", "--version-string", "1.8.0",
                               "--app-store-version-localizations", "@file:" + str(store.ROOT / "build/release/apple-localizations.json")])

    def test_cross_channel_context_is_rejected(self):
        with self.assertRaises(store.Blocked):
            store.check_builds({**self.rc, "destination": "app_store_review"}, [], [], 0)
        with self.assertRaises(store.Blocked):
            store.publish_arguments({**self.rc, "destination": "app_store_review"}, "build.ipa")

    def test_paginated_results_are_complete(self):
        pages = [{"data": [{"id": "a"}], "links": {"next": store.API + "/v1/builds?page=2"}}, {"data": [{"id": "b"}], "links": {"next": None}}]
        with patch.object(store, "get_json", side_effect=pages) as get:
            self.assertEqual([b["id"] for b in store.all_pages("/v1/builds", "fake")], ["a", "b"])
            self.assertEqual(get.call_count, 2)

    def test_unavailable_second_page_is_not_empty_state(self):
        pages = [{"data": [], "links": {"next": store.API + "/v1/builds?page=2"}}, TimeoutError()]
        with patch.object(store, "get_json", side_effect=pages), self.assertRaises(TimeoutError):
            store.all_pages("/v1/builds", "fake")

    def test_malformed_or_cyclic_pagination_blocks(self):
        for page in ({"data": None}, {"data": [], "links": {"next": store.API + "/v1/builds"}}):
            with self.subTest(page=page), patch.object(store, "get_json", return_value=page), self.assertRaises(store.Blocked):
                store.all_pages("/v1/builds", "fake")

    def test_pagination_does_not_leak_jwt_to_other_hosts(self):
        with self.assertRaises(store.Blocked):
            store.get_json("https://example.invalid/v1/builds", "fake")


class ApplePublishBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.addCleanup(patch.stopall)
        self.root = Path(self.directory.name)
        self.context = {"platform": "ios", "channel": "rc", "destination": "testflight",
                        "version": "1.2.3", "build": 23, "tag": "rc/ios/v1.2.3+23"}
        release = self.root / 'build/release'
        release.mkdir(parents=True)
        (release / 'context.json').write_text(json.dumps(self.context))
        (release / 'apple-localizations.json').write_text(json.dumps([{'locale': 'ru', 'whats_new': 'Synthetic notes'}]))
        self.ipa = self.root / 'build/ios/ipa/fixture.ipa'
        patch.object(store, 'ROOT', self.root).start()
        patch.dict(store.os.environ, {'CM_BUILD_ID': 'fixture', 'CM_TAG': self.context['tag'],
                                     'TESTFLIGHT_GROUP': 'Synthetic Internal'}, clear=True).start()
        self.read = patch.object(store, 'preflight', return_value={'automatic_group_id': 'fixture'}).start()
        self.confirm = patch.object(store, 'confirm_testflight_distribution', return_value='synthetic-build').start()
        self.publish = patch.object(store.subprocess, 'run', return_value=SimpleNamespace(returncode=0)).start()
        patch.object(store, 'get_json', side_effect=AssertionError('No real Apple requests')).start()

    def run_main(self, command):
        with patch.object(store.sys, 'argv', ['ios_store.py', command]), contextlib.redirect_stdout(io.StringIO()) as output:
            store.main()
        return output.getvalue()

    def create_ipa(self):
        self.ipa.parent.mkdir(parents=True)
        self.ipa.write_bytes(b'SYNTHETIC_NOT_A_SIGNED_BINARY')

    def test_early_validation_reads_same_git_notes_without_ipa_api_or_publisher(self):
        files = sorted(self.root.rglob('*'))
        self.assertIn('APPLE_PUBLISH_ARGUMENTS_VALID', self.run_main('validate-publish'))
        self.read.assert_not_called()
        self.publish.assert_not_called()
        self.assertFalse(self.ipa.exists())
        self.assertEqual(sorted(self.root.rglob('*')), files)

    def test_bad_builder_arguments_stop_both_early_check_and_real_publisher(self):
        self.create_ipa()
        original = store.publish_arguments
        def old_arguments(*args):
            generated = original(*args)
            generated[generated.index('--altool-retries') + 1] = '0'
            return generated
        with patch.object(store, 'publish_arguments', side_effect=old_arguments):
            for command in ('validate-publish', 'publish'):
                with self.subTest(command=command), self.assertRaisesRegex(store.Blocked, '^APPLE_PUBLISH_ARGUMENTS_INVALID$'):
                    self.run_main(command)
                self.publish.assert_not_called()
                self.assertTrue(self.ipa.exists())

    def test_unknown_preupload_state_stops_without_upload_and_retains_ipa(self):
        self.create_ipa()
        self.read.side_effect = store.AppleCheckFailure('APPLE_API_UNAVAILABLE', 'uploads', 'timeout')
        with self.assertRaises(store.Blocked):
            self.run_main('publish')
        self.publish.assert_not_called()
        self.assertTrue(self.ipa.exists())

    def test_success_and_failed_or_unknown_cli_exit_always_retain_exact_ipa(self):
        self.create_ipa()
        expected = self.ipa.read_bytes()
        for status in (0, 1, 130):
            self.publish.reset_mock()
            self.read.reset_mock()
            self.confirm.reset_mock()
            self.publish.return_value = SimpleNamespace(returncode=status)
            if status:
                with self.assertRaisesRegex(store.Blocked, 'upload may already be accepted.*no automatic retry'):
                    self.run_main('publish')
            else:
                self.run_main('publish')
            self.read.assert_called_once_with(self.context)
            self.publish.assert_called_once()  # Mock subprocess: never a real upload.
            if status:
                self.confirm.assert_not_called()
            else:
                self.confirm.assert_called_once_with(self.context, 'fixture')
            self.assertEqual(self.ipa.read_bytes(), expected)

    def test_production_early_check_is_default_deny_before_api_or_publisher(self):
        context = {**self.context, 'channel': 'production', 'destination': 'app_store_review'}
        (self.root / 'build/release/context.json').write_text(json.dumps(context))
        for command in ('validate-publish', 'publish'):
            with self.subTest(command=command), self.assertRaisesRegex(store.Blocked, 'Production disabled until U5'):
                self.run_main(command)
        self.read.assert_not_called()
        self.publish.assert_not_called()

    def test_unconfirmed_postupload_stops_after_one_publisher_call_and_keeps_ipa(self):
        self.create_ipa()
        self.confirm.side_effect = store.Blocked('TESTFLIGHT_DISTRIBUTION_UNCONFIRMED')
        with self.assertRaisesRegex(store.Blocked, '^TESTFLIGHT_DISTRIBUTION_UNCONFIRMED$'):
            self.run_main('publish')
        self.publish.assert_called_once()
        self.confirm.assert_called_once()
        self.assertTrue(self.ipa.exists())

    def test_production_success_never_calls_rc_distribution_confirmation(self):
        self.create_ipa()
        context = {**self.context, 'channel': 'production', 'destination': 'app_store_review', 'tag': 'ios/v1.2.3+23'}
        (self.root / 'build/release/context.json').write_text(json.dumps(context))
        commit = 'a' * 40
        with patch.dict(store.os.environ, {
                'CM_TAG': context['tag'], 'PRODUCTION_PUBLISHING_ENABLED': 'true',
                'CM_TRIGGER_SOURCE': 'webhook', 'CM_COMMIT': commit,
                'PRODUCTION_RELEASE_AUTH_IOS': f"{context['tag']}@{commit}"}):
            preview = self.run_main('validate-publish')
            published = self.run_main('publish')
        self.assertIn('APPLE_PUBLISH_ARGUMENTS_VALID', preview)
        self.assertIn('does not prove App Store publication', published)
        self.assertNotIn('PUBLISHER_INVOKED', published)
        self.read.assert_called_once_with(context)
        self.publish.assert_called_once()
        self.confirm.assert_not_called()
        self.assertIn('--app-store', self.publish.call_args.args[0])

    def test_ios_production_non_webhook_stops_before_preflight_and_does_not_retag(self):
        self.create_ipa()
        context = {**self.context, 'channel': 'production', 'destination': 'app_store_review', 'tag': 'ios/v1.2.3+23'}
        (self.root / 'build/release/context.json').write_text(json.dumps(context))
        commit = 'a' * 40
        base = {
            'CM_TAG': context['tag'], 'PRODUCTION_PUBLISHING_ENABLED': 'true',
            'CM_COMMIT': commit, 'PRODUCTION_RELEASE_AUTH_IOS': f"{context['tag']}@{commit}",
        }
        for source in ('api', 'schedule', '', 'Webhook'):
            with self.subTest(source=source), patch.dict(store.os.environ, {**base, 'CM_TRIGGER_SOURCE': source}):
                with self.assertRaisesRegex(store.Blocked, 'IOS_PRODUCTION_REQUIRES_WEBHOOK'):
                    self.run_main('publish')
            self.read.assert_not_called()
            self.publish.assert_not_called()
        missing = {**store.os.environ, **base}
        missing.pop('CM_TRIGGER_SOURCE', None)
        with patch.dict(store.os.environ, missing, clear=True):
            with self.assertRaisesRegex(store.Blocked, 'IOS_PRODUCTION_REQUIRES_WEBHOOK'):
                self.run_main('publish')
        self.read.assert_not_called()
        self.publish.assert_not_called()
        self.assertEqual(json.loads((self.root / 'build/release/context.json').read_text())['tag'], context['tag'])

    def test_wrong_ios_cloud_authorization_stops_before_store_reads(self):
        context = {**self.context, 'channel': 'production', 'destination': 'app_store_review', 'tag': 'ios/v1.2.3+23'}
        (self.root / 'build/release/context.json').write_text(json.dumps(context))
        commit = 'a' * 40
        with patch.dict(store.os.environ, {
                'CM_TAG': context['tag'], 'PRODUCTION_PUBLISHING_ENABLED': 'true',
                'CM_TRIGGER_SOURCE': 'webhook', 'CM_COMMIT': commit,
                'PRODUCTION_RELEASE_AUTH_IOS': f"{context['tag']}@{'b' * 40}"}):
            with self.assertRaisesRegex(store.Blocked, 'IOS_PRODUCTION_AUTHORIZATION_INVALID'):
                self.run_main('validate-publish')
        self.read.assert_not_called()
        self.publish.assert_not_called()

    def test_rc_publish_does_not_require_production_webhook(self):
        self.create_ipa()
        self.assertNotIn('CM_TRIGGER_SOURCE', store.os.environ)
        self.assertNotIn('PRODUCTION_RELEASE_AUTH_IOS', store.os.environ)
        self.run_main('publish')
        self.publish.assert_called_once()
        self.read.assert_called_once()

    def test_valid_authorization_is_not_consumed(self):
        context = {**self.context, 'channel': 'production', 'destination': 'app_store_review', 'tag': 'ios/v1.2.3+23'}
        commit = 'a' * 40
        with patch.dict(store.os.environ, {
                'PRODUCTION_PUBLISHING_ENABLED': 'true', 'CM_TRIGGER_SOURCE': 'webhook',
                'CM_COMMIT': commit, 'PRODUCTION_RELEASE_AUTH_IOS': f"{context['tag']}@{commit}"}):
            store.require_production_cloud(context)
            store.require_production_cloud(context)
        self.publish.assert_not_called()
        self.read.assert_not_called()


class ProductionReviewPreflightTests(unittest.TestCase):
    def env(self, app_id):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, NoEncryption, PrivateFormat
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        return {"APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000",
                "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "PROKAT_ASC_PRIVATE_KEY_PEM": pem,
                "APP_STORE_APP_ID": app_id, "IOS_HISTORICAL_MAX_BUILD": "17"}

    def test_wrong_production_app_stops_before_reads(self):
        with patch.dict(store.os.environ, self.env("2"), clear=True), patch.object(store, "get_json") as get:
            with self.assertRaises(store.AppleCheckFailure) as caught:
                store.preflight({"platform": "ios", "channel": "production", "destination": "app_store_review",
                                 "version": "1.2.4", "build": 25})
        self.assertEqual(caught.exception.code, "APPLE_APP_MISMATCH")
        get.assert_not_called()

    def test_inflight_version_stops_before_publisher_and_hides_body(self):
        context = {"platform": "ios", "channel": "production", "destination": "app_store_review",
                   "version": "1.2.4", "build": 25, "tag": "ios/v1.2.4+25"}
        app = {"data": {"id": store.APP_ID, "attributes": {"bundleId": "com.auyltech.prokat", "primaryLocale": "ru"}}}
        inflight = {"id": "version", "attributes": {
            "versionString": "1.0.0", "platform": "IOS", "appStoreState": "IN_REVIEW",
            "appVersionState": "READY_FOR_DISTRIBUTION"}}
        secret = "PRIVATE_RESPONSE_BODY"
        pages = [app, {"data": [], "links": {}}, {"data": [], "links": {}},
                 {"data": [inflight], "links": {}, "raw": secret}, {"data": [], "links": {}}]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "build/release").mkdir(parents=True)
            (root / "build/release/context.json").write_text(json.dumps(context))
            with patch.object(store, "ROOT", root), patch.dict(store.os.environ, self.env(store.APP_ID), clear=True), \
                    patch.object(store, "get_json", side_effect=pages), \
                    contextlib.redirect_stdout(io.StringIO()) as output, \
                    self.assertRaises(store.AppleCheckFailure) as caught:
                store.preflight(context)
        self.assertEqual(caught.exception.code, "APPLE_VERSION_IN_FLIGHT")
        self.assertNotIn(secret, str(caught.exception) + output.getvalue())

    def test_dropped_filter_on_next_page_is_unknown(self):
        first = {"data": [], "links": {"next": store.API + "/v1/apps/6817078475/appStoreVersions?limit=100"}}
        with patch.object(store, "get_json", return_value=first), self.assertRaises(store.AppleCheckFailure) as caught:
            store.check_production_review({"app_id": store.APP_ID}, "token", "1.2.4")
        self.assertEqual(caught.exception.code, "APPLE_PAGINATION_FAILED")

    def test_expired_review_deadline_stops_without_a_second_read(self):
        with patch.object(store.time, "monotonic", return_value=0), \
                patch.object(store, "all_pages", side_effect=store.AppleCheckFailure("APPLE_API_UNAVAILABLE", "versions", "timeout")) as pages:
            with self.assertRaises(store.AppleCheckFailure) as caught:
                store.check_production_review({"app_id": store.APP_ID}, "token", "1.2.4")
        self.assertEqual(caught.exception.reason, "timeout")
        pages.assert_called_once()
        self.assertEqual(pages.call_args.kwargs["deadline"], 90)

    def test_review_urls_are_get_only_and_http_failures_hide_the_body(self):
        secret = "PRIVATE_RESPONSE_BODY"
        path = store.production_version_path(store.APP_ID)
        self.assertNotIn("filter[state]", path)
        self.assertNotIn("filter[appStoreState]", path)
        self.assertNotIn("filter[state]", store.production_submission_path(store.APP_ID))
        cases = ((401, "APPLE_AUTH_REJECTED"), (403, "APPLE_ACCESS_FORBIDDEN"),
                 (429, "APPLE_API_UNAVAILABLE"), (500, "APPLE_API_UNAVAILABLE"), (503, "APPLE_API_UNAVAILABLE"))
        for status, code in cases:
            opener = Mock()
            opener.open.side_effect = urllib.error.HTTPError(
                store.API + path, status, "status", hdrs=None, fp=io.BytesIO(secret.encode()))
            with self.subTest(status=status), patch.object(store.urllib.request, "build_opener", return_value=opener), \
                    patch.object(store.subprocess, "run") as publisher, \
                    self.assertRaises(store.AppleCheckFailure) as caught:
                store.check_production_review({"app_id": store.APP_ID}, "token", "1.2.4")
            self.assertEqual(caught.exception.code, code)
            self.assertNotIn(secret, str(caught.exception))
            self.assertEqual(opener.open.call_args.args[0].get_method(), "GET")
            publisher.assert_not_called()
        opener = Mock()
        opener.open.side_effect = TimeoutError()
        with patch.object(store.urllib.request, "build_opener", return_value=opener), \
                self.assertRaises(store.AppleCheckFailure) as caught:
            store.check_production_review({"app_id": store.APP_ID}, "token", "1.2.4")
        self.assertEqual(caught.exception.reason, "timeout")

    def test_unsafe_or_incomplete_review_pages_fail_closed(self):
        version_path = store.production_version_path(store.APP_ID)
        same = store.API + version_path
        cases = (
            [{"data": [], "links": {"next": "https://evil.example" + version_path}}],
            [{"data": [{"id": "a"}], "links": {"next": same + "&cursor=2"}}, {"data": [{"id": "a"}], "links": {}}],
            [{}],
        )
        for pages in cases:
            with self.subTest(pages=pages), patch.object(store, "get_json", side_effect=pages), \
                    self.assertRaises(store.AppleCheckFailure) as caught:
                store.check_production_review({"app_id": store.APP_ID}, "token", "1.2.4")
            self.assertIn(caught.exception.code, {"APPLE_PAGINATION_FAILED", "APPLE_RESPONSE_INVALID"})


if __name__ == "__main__":
    unittest.main()
