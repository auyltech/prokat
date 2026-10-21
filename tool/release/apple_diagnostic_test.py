"""Offline diagnostics: synthetic keys and in-memory HTTP only; no Apple access."""
import base64
import contextlib
import copy
import io
import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import urllib.error

import jwt
from cryptography.hazmat.primitives.asymmetric import ec, rsa
from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, NoEncryption, BestAvailableEncryption

import apple_diagnostic as diagnostic
import ios_store as apple

SENTINEL = "CONFIDENTIAL_TEST_SENTINEL_NEVER_LOG"
APP_ID = "6817078475"
GROUP = "AuylTech Test Team"


def pem_for(key, encryption=None):
    return key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, encryption or NoEncryption()).decode("ascii")


def resource(identifier, **attributes):
    return {"id": identifier, "attributes": attributes}


def page(data, next_url=None, total=None):
    result = {"data": data, "links": {"next": next_url}}
    if total is not None:
        result["meta"] = {"paging": {"total": total}}
    return result


class AppleDiagnosticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.key = ec.generate_private_key(ec.SECP256R1())
        cls.pem = pem_for(cls.key)

    def setUp(self):
        self.env = {
            "APP_STORE_CONNECT_ISSUER_ID": "00000000-0000-4000-8000-000000000000",
            "APP_STORE_CONNECT_KEY_IDENTIFIER": "ABCDEFGHIJ", "APP_STORE_CONNECT_PRIVATE_KEY": self.pem,
            "APP_STORE_APP_ID": APP_ID, "IOS_HISTORICAL_MAX_BUILD": "17", "TESTFLIGHT_GROUP": GROUP,
        }
        self.responses = [
            {"data": resource(APP_ID, bundleId="com.auyltech.prokat", primaryLocale="ru", ignored=SENTINEL)},
            page([resource("old", version="17", processingState="VALID")]), page([]),
            page([resource("group", name=GROUP, isInternalGroup=True)]),
        ]

    def invoke(self, args=None, env=None, responses=None, error=None):
        """Exercise real auth, urllib request creation, JSON and pagination in memory."""
        output, errors = io.StringIO(), io.StringIO()
        fixtures = iter(copy.deepcopy(self.responses if responses is None else responses))
        requests = []

        def open_request(request, timeout):
            requests.append(request)
            self.assertEqual(request.get_method(), "GET")
            self.assertIsNone(request.data)
            self.assertGreater(timeout, 0)
            self.assertLessEqual(timeout, 15)
            if error is not None:
                raise error
            return io.BytesIO(json.dumps(next(fixtures)).encode())

        with contextlib.ExitStack() as stack:
            for name in ("write_text", "write_bytes", "mkdir", "open"):
                stack.enter_context(patch.object(Path, name, side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch("builtins.open", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch("io.open", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch("os.open", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch.object(apple.subprocess, "run", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch.object(apple, "publish_arguments", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch.object(apple, "preflight", side_effect=AssertionError(SENTINEL)))
            stack.enter_context(patch.object(apple.urllib.request, "build_opener",
                                             return_value=SimpleNamespace(open=open_request)))
            stack.enter_context(contextlib.redirect_stdout(output))
            stack.enter_context(contextlib.redirect_stderr(errors))
            status = diagnostic.main(["check", "--build", "20"] if args is None else args,
                                     self.env if env is None else env)
        text = output.getvalue() + errors.getvalue()
        self.assertNotIn(SENTINEL, text)
        self.assertNotIn(self.pem, text)
        self.assertNotIn("Traceback", text)
        self.assertNotIn("Authorization", text)
        for request in requests:
            token = request.get_header("Authorization").split(" ", 1)[1]
            self.assertNotIn(token, text)
        if status:
            self.assertNotIn("APPLE_STATE_VALID", text)
            self.assertNotIn("APPLE_AUTH_MATERIAL_VALID", text)
        return status, text, requests

    def assert_failure(self, code, **kwargs):
        status, text, requests = self.invoke(**kwargs)
        self.assertEqual(status, 1)
        self.assertIn("BLOCKED: " + code + " stage=", text)
        return text, requests

    def test_success_without_files_or_publisher_and_verified_jwt(self):
        status, text, requests = self.invoke()
        self.assertEqual(status, 0)
        self.assertTrue(text.endswith("APPLE_DIAG: APPLE_STATE_VALID stage=build\n"))
        self.assertEqual(len(requests), 4)
        claims = jwt.decode(requests[0].get_header("Authorization").split()[1], self.key.public_key(),
                            algorithms=["ES256"], audience="appstoreconnect-v1")
        self.assertEqual(claims["iss"], self.env["APP_STORE_CONNECT_ISSUER_ID"])
        self.assertEqual(claims["exp"] - claims["iat"], 1200)

    def test_auth_rc_and_production_are_network_free(self):
        for channel in ("rc", "production"):
            env = dict(self.env)
            if channel == "production":
                del env["TESTFLIGHT_GROUP"]
            status, text, requests = self.invoke(args=["auth", "--channel", channel], env=env)
            self.assertEqual(status, 0)
            self.assertIn("APPLE_AUTH_MATERIAL_VALID", text)
            self.assertNotIn("APPLE_STATE_VALID", text)
            self.assertEqual(requests, [])

    def test_crlf_key_is_accepted_without_repair(self):
        status, _, requests = self.invoke(args=["auth", "--channel", "rc"],
                                         env={**self.env, "APP_STORE_CONNECT_PRIVATE_KEY": self.pem.replace("\n", "\r\n")})
        self.assertEqual((status, requests), (0, []))

    def test_malformed_pem_never_reaches_network(self):
        cases = [self.pem.replace("\n", r"\n"), base64.b64encode(self.pem.encode()).decode(),
                 '"' + self.pem + '"', "'" + self.pem + "'", "\ufeff" + self.pem, self.pem[:75],
                 "@file:" + SENTINEL, "@env:" + SENTINEL, "```\n" + self.pem + "```",
                 self.pem.replace("\n", "\r"), self.pem.replace("\n", "\n" + SENTINEL + "\n", 1),
                 pem_for(self.key, BestAvailableEncryption(b"synthetic-password"))]
        for pem in cases:
            with self.subTest(case=cases.index(pem)):
                _, requests = self.assert_failure("APPLE_PEM_INVALID", env={**self.env, "APP_STORE_CONNECT_PRIVATE_KEY": pem})
                self.assertEqual(requests, [])

    def test_unsupported_rsa_and_p384(self):
        for key in (rsa.generate_private_key(public_exponent=65537, key_size=2048),
                    ec.generate_private_key(ec.SECP384R1())):
            _, requests = self.assert_failure("APPLE_KEY_UNSUPPORTED", env={**self.env, "APP_STORE_CONNECT_PRIVATE_KEY": pem_for(key)})
            self.assertEqual(requests, [])

    def test_public_key_is_rejected(self):
        from cryptography.hazmat.primitives.serialization import PublicFormat
        public = self.key.public_key().public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo).decode()
        self.assert_failure("APPLE_PEM_INVALID", env={**self.env, "APP_STORE_CONNECT_PRIVATE_KEY": public})

    def test_jwt_failure_after_valid_key_is_sanitized(self):
        with patch("jwt.encode", side_effect=ValueError(SENTINEL)):
            text, requests = self.assert_failure("APPLE_JWT_FAILED")
        self.assertIn("APPLE_KEY_VALID", text)
        self.assertEqual(requests, [])

    def test_all_missing_variables_fail_before_network(self):
        for name in apple.ENV_NAMES:
            with self.subTest(variable=name):
                env = dict(self.env)
                del env[name]
                text, requests = self.assert_failure("APPLE_ENV_MISSING", env=env)
                self.assertIn("variable=" + name, text)
                self.assertEqual(requests, [])

    def test_invalid_environment_and_wrong_diagnostic_scope(self):
        for name, value in (("APP_STORE_CONNECT_ISSUER_ID", SENTINEL),
                            ("APP_STORE_CONNECT_KEY_IDENTIFIER", SENTINEL),
                            ("APP_STORE_APP_ID", "123"), ("TESTFLIGHT_GROUP", SENTINEL),
                            ("IOS_HISTORICAL_MAX_BUILD", "9" * 5000),
                            ("IOS_HISTORICAL_MAX_BUILD", "017"), ("IOS_HISTORICAL_MAX_BUILD", " 17")):
            _, requests = self.assert_failure("APPLE_ENV_INVALID", env={**self.env, name: value})
            self.assertEqual(requests, [])

    def test_usage_cannot_select_publish_or_echo_arguments(self):
        for args in (["publish", "--path", SENTINEL], ["check", "--build", SENTINEL],
                     ["check", "--build", "0"], ["check", "--build", "10000"],
                     ["auth", "--channel", SENTINEL], [SENTINEL], []):
            _, requests = self.assert_failure("APPLE_DIAGNOSTIC_USAGE", args=args)
            self.assertEqual(requests, [])

    def test_http_codes_are_sanitized_and_fail_closed(self):
        for status, code in ((401, "APPLE_AUTH_REJECTED"), (403, "APPLE_ACCESS_FORBIDDEN"),
                             (404, "APPLE_API_REJECTED"), (429, "APPLE_API_UNAVAILABLE"),
                             (500, "APPLE_API_UNAVAILABLE"), (503, "APPLE_API_UNAVAILABLE"),
                             (302, "APPLE_PAGINATION_FAILED")):
            error = urllib.error.HTTPError(apple.API + "/" + SENTINEL, status, SENTINEL, {}, io.BytesIO(SENTINEL.encode()))
            text, requests = self.assert_failure(code, error=error)
            self.assertIn("stage=app", text)
            self.assertEqual(len(requests), 1)

    def test_transport_and_timeout_are_sanitized(self):
        for error in (TimeoutError(SENTINEL), urllib.error.URLError(SENTINEL), OSError(SENTINEL)):
            self.assert_failure("APPLE_API_UNAVAILABLE", error=error)

    def test_json_error_is_sanitized(self):
        opener = SimpleNamespace(open=lambda *args, **kwargs: io.BytesIO(SENTINEL.encode()))
        with patch.object(apple.urllib.request, "build_opener", return_value=opener), self.assertRaises(apple.AppleCheckFailure) as caught:
            apple.get_json(apple.API + "/v1/apps/" + APP_ID, "synthetic-token", stage="app")
        self.assertEqual(caught.exception.code, "APPLE_RESPONSE_INVALID")
        self.assertNotIn(SENTINEL, str(caught.exception))

    def test_schema_and_app_identity_errors(self):
        for first, code in ((None, "APPLE_RESPONSE_INVALID"), ({"data": None}, "APPLE_RESPONSE_INVALID"),
                            ({"data": resource(APP_ID, bundleId=SENTINEL, primaryLocale="ru")}, "APPLE_APP_MISMATCH"),
                            ({"data": resource(APP_ID, bundleId="com.auyltech.prokat", primaryLocale=SENTINEL)}, "APPLE_APP_MISMATCH")):
            self.assert_failure(code, responses=[first])

    def test_group_must_be_unique_and_internal(self):
        group = resource("group", name=GROUP, isInternalGroup=True)
        for groups in ([], [group, {**group, "id": "second"}], [resource("group", name=GROUP, isInternalGroup=False)]):
            self.assert_failure("APPLE_GROUP_INVALID", responses=self.responses[:3] + [page(groups)])

    def test_used_builds_uploads_and_non_increasing_numbers(self):
        for bucket, attributes in ((1, {"version": "20", "processingState": "FAILED"}),
                                   (2, {"cfBundleVersion": "20", "state": "PROCESSING"})):
            responses = copy.deepcopy(self.responses)
            responses[bucket] = page([resource(SENTINEL, **attributes)])
            self.assert_failure("APPLE_BUILD_ALREADY_USED", responses=responses)
        for version in ("21", "20.1"):
            responses = copy.deepcopy(self.responses)
            responses[1] = page([resource("higher", version=version, processingState="VALID")])
            self.assert_failure("APPLE_BUILD_NOT_INCREASING", responses=responses)
        self.assert_failure("APPLE_BUILD_NOT_INCREASING", env={**self.env, "IOS_HISTORICAL_MAX_BUILD": "20"})
        responses = copy.deepcopy(self.responses)
        responses[1] = page([resource("bad", version="9" * 5000, processingState="VALID")])
        self.assert_failure("APPLE_STATE_INVALID", responses=responses)

    def test_generic_error_and_invalid_error_fields_are_sanitized(self):
        with patch.object(apple, "read_apple_state", side_effect=RuntimeError(SENTINEL)):
            self.assert_failure("APPLE_DIAGNOSTIC_INTERNAL_ERROR")
        self.assertNotIn(SENTINEL, str(apple.AppleCheckFailure(SENTINEL, SENTINEL, SENTINEL, SENTINEL)))


class ApplePaginationTests(unittest.TestCase):
    path = "/v1/builds?filter[app]=6817078475&filter[preReleaseVersion.platform]=IOS&limit=200"

    def test_pagination_preserves_app_platform_and_reads_every_page(self):
        next_url = apple.API + self.path + "&cursor=second"
        with patch.object(apple, "get_json", side_effect=[page([resource("a")], next_url, 2), page([resource("b")], total=2)]) as get:
            self.assertEqual([item["id"] for item in apple.all_pages(self.path, "synthetic")], ["a", "b"])
            self.assertEqual(get.call_count, 2)

    def test_unsafe_pagination_rejected_before_next_request(self):
        for url in ("https://example.invalid/v1/builds", "http://api.appstoreconnect.apple.com/v1/builds",
                    "https://[invalid/v1/builds", apple.API + "/v1/builds?cursor=2",
                    apple.API + self.path.replace("6817078475", "123"),
                    apple.API + self.path.replace("IOS", "MAC_OS"), apple.API + "/v1/apps/123/builds",
                    apple.API + self.path + "\n", apple.API + self.path + "#fragment", 1, ""):
            with self.subTest(url_type=type(url).__name__), patch.object(apple, "get_json", return_value=page([], url)) as get:
                with self.assertRaises(apple.AppleCheckFailure) as caught:
                    apple.all_pages(self.path, "synthetic")
                self.assertEqual(caught.exception.code, "APPLE_PAGINATION_FAILED")
                self.assertEqual(get.call_count, 1)

    def test_redirect_handler_does_not_follow_redirects(self):
        def opener(handler):
            with self.assertRaises(apple.AppleCheckFailure) as caught:
                handler().redirect_request(None, None, 302, SENTINEL, {}, "https://example.invalid/" + SENTINEL)
            self.assertEqual(caught.exception.reason, "redirect")
            raise caught.exception
        with patch.object(apple.urllib.request, "build_opener", side_effect=opener), self.assertRaises(apple.AppleCheckFailure):
            apple.get_json(apple.API + self.path, "synthetic")

    def test_cycles_duplicate_ids_missing_pages_and_malformed_lists(self):
        next_url = apple.API + self.path + "&cursor=2"
        cases = [([page([], apple.API + self.path)], "APPLE_PAGINATION_FAILED"),
                 ([page([resource("a")], next_url), page([resource("a")])], "APPLE_PAGINATION_FAILED"),
                 ([page([], total=1)], "APPLE_PAGINATION_FAILED"),
                 ([page([], next_url, 1), page([], total=2)], "APPLE_PAGINATION_FAILED"),
                 ([{"data": [], "links": None}], "APPLE_RESPONSE_INVALID"),
                 ([{"data": None, "links": {}}], "APPLE_RESPONSE_INVALID"),
                 ([page([], total=True)], "APPLE_RESPONSE_INVALID")]
        for pages, code in cases:
            with patch.object(apple, "get_json", side_effect=pages), self.assertRaises(apple.AppleCheckFailure) as caught:
                apple.all_pages(self.path, "synthetic")
            self.assertEqual(caught.exception.code, code)

    def test_page_cap_and_total_deadline(self):
        pages = [page([], apple.API + self.path + "&cursor=" + str(i)) for i in range(1, 102)]
        with patch.object(apple, "get_json", side_effect=pages) as get, self.assertRaises(apple.AppleCheckFailure) as caught:
            apple.all_pages(self.path, "synthetic")
        self.assertEqual(caught.exception.reason, "page_limit")
        self.assertEqual(get.call_count, 100)
        with patch.object(apple.time, "monotonic", return_value=91), patch.object(apple, "get_json") as get:
            with self.assertRaises(apple.AppleCheckFailure) as caught:
                apple.all_pages(self.path, "synthetic", deadline=90)
            self.assertEqual(caught.exception.code, "APPLE_API_UNAVAILABLE")
            get.assert_not_called()

    def test_second_page_failure_is_not_an_empty_state(self):
        with patch.object(apple, "get_json", side_effect=[page([], apple.API + self.path + "&cursor=2"),
                                                       apple.AppleCheckFailure("APPLE_ACCESS_FORBIDDEN", "builds")]):
            with self.assertRaises(apple.AppleCheckFailure) as caught:
                apple.all_pages(self.path, "synthetic", stage="builds")
        self.assertEqual(caught.exception.code, "APPLE_ACCESS_FORBIDDEN")


if __name__ == "__main__":
    unittest.main()
