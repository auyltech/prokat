import contextlib
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import ios_store as store


class AppleStorePolicyTests(unittest.TestCase):
    def setUp(self):
        self.rc = {"platform": "ios", "channel": "rc", "destination": "testflight", "version": "1.8.0", "build": 108}

    def test_new_build(self):
        store.check_builds(self.rc, [{"id": "old", "attributes": {"version": "107", "processingState": "VALID"}}], [], 100)

    def test_rc_group_must_exist_and_be_internal(self):
        group = {"id": "fixture", "attributes": {"name": "PROKAT Internal", "isInternalGroup": True}}
        self.assertEqual(store.check_internal_group([group], "PROKAT Internal"), "fixture")
        for groups, name in (([], None), ([], "PROKAT Internal"), ([group], "typo"),
                             ([group, group], "PROKAT Internal"),
                             ([{**group, "attributes": {**group["attributes"], "isInternalGroup": False}}], "PROKAT Internal")):
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
            env = {"CM_BUILD_ID": "fixture", "CM_TAG": context["tag"], "TESTFLIGHT_GROUP": "PROKAT Internal"}
            with patch.object(store, "ROOT", root), patch.dict(store.os.environ, env, clear=True), \
                    patch.object(store.sys, "argv", ["ios_store.py", "publish"]), patch.object(store, "preflight") as read, \
                    patch.object(store.subprocess, "run") as publish, \
                    contextlib.redirect_stdout(io.StringIO()):
                publish.side_effect = lambda *a, **k: (read.assert_called_once_with(context) or SimpleNamespace(returncode=0))
                store.main()
                args = publish.call_args.args[0]
                self.assertEqual(args[1], str(root / "tool/release/apple_publish.py"))
                self.assertIn("--beta-group", args)
                self.assertNotIn("--app-store", args)

    def test_real_preflight_flow_uses_fresh_complete_reads_and_internal_group(self):
        from cryptography.hazmat.primitives.asymmetric import ec
        from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption
        pem = ec.generate_private_key(ec.SECP256R1()).private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()).decode()
        env = {"APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000", "APP_STORE_CONNECT_PRIVATE_KEY": pem,
               "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "APP_STORE_APP_ID": "123",
               "IOS_HISTORICAL_MAX_BUILD": "100", "TESTFLIGHT_GROUP": "PROKAT Internal"}
        app = {"data": {"id": "123", "attributes": {"bundleId": "com.auyltech.prokat", "primaryLocale": "ru"}}}
        groups = [{"id": "fixture", "attributes": {"name": "PROKAT Internal", "isInternalGroup": True}}]
        with tempfile.TemporaryDirectory() as directory, patch.object(store, "ROOT", Path(directory)), \
                patch.dict(store.os.environ, env, clear=True), \
                patch.object(store, "get_json", return_value=app), \
                patch.object(store, "all_pages", side_effect=[[], [], groups, [], [], groups]) as pages, \
                contextlib.redirect_stdout(io.StringIO()):
            store.preflight(self.rc)
            store.preflight(self.rc)
            self.assertEqual(pages.call_count, 6)  # No cache between pre-build and pre-upload.
            self.assertEqual(pages.call_args_list[2].args[0], "/v1/apps/123/betaGroups?limit=200")
            self.assertTrue((Path(directory) / "build/release/apple-state.json").is_file())

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
        args = store.publish_arguments(self.rc, "build.ipa", "PROKAT Internal")
        self.assertNotIn("--app-store", args)
        self.assertNotIn("--release-type", args)
        self.assertNotIn("--testflight", args)
        self.assertIn("--beta-group", args)
        self.assertEqual(args[args.index("--altool-retries") + 1], "0")

    def test_production_requests_after_approval(self):
        args = store.publish_arguments({**self.rc, "channel": "production", "destination": "app_store_review"}, "build.ipa")
        self.assertIn("--app-store", args)
        self.assertIn("AFTER_APPROVAL", args)

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


if __name__ == "__main__":
    unittest.main()
