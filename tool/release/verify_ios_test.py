import datetime
import unittest

from verify_ios import EXPECTED_DOMAINS, validate


class ExportedSigningTests(unittest.TestCase):
    def setUp(self):
        self.context = {"version": "1.8.0", "build": 108}
        self.info = {"CFBundleIdentifier": "com.auyltech.prokat", "CFBundleShortVersionString": "1.8.0", "CFBundleVersion": "108", "ITSAppUsesNonExemptEncryption": False}
        self.entitlements = {"aps-environment": "production", "application-identifier": "VT7KXG8NBR.com.auyltech.prokat", "com.apple.developer.team-identifier": "VT7KXG8NBR", "com.apple.developer.associated-domains": list(EXPECTED_DOMAINS)}
        self.profile = {"ExpirationDate": datetime.datetime.now() + datetime.timedelta(days=10),
                        "TeamIdentifier": ["VT7KXG8NBR"], "Entitlements": {
                            "aps-environment": "production", "application-identifier": "VT7KXG8NBR.com.auyltech.prokat",
                            "com.apple.developer.team-identifier": "VT7KXG8NBR", "get-task-allow": False}}

    def test_valid_distribution_contract(self):
        validate(self.info, self.entitlements, self.profile, self.context)

    def test_actual_development_or_debug_entitlements_block(self):
        for overrides in ({"aps-environment": "development"}, {"get-task-allow": True}, {"com.apple.developer.team-identifier": "OTHER"}, {"com.apple.developer.associated-domains": []}):
            with self.subTest(overrides=overrides), self.assertRaises(RuntimeError):
                validate(self.info, {**self.entitlements, **overrides}, self.profile, self.context)

    def test_mismatched_build_or_unknown_export_compliance_blocks(self):
        for overrides in ({"CFBundleVersion": "109"}, {"CFBundleShortVersionString": "1.8.1"}, {"ITSAppUsesNonExemptEncryption": None}):
            with self.subTest(overrides=overrides), self.assertRaises(RuntimeError):
                validate({**self.info, **overrides}, self.entitlements, self.profile, self.context)

    def test_expired_or_adhoc_profile_blocks(self):
        for overrides in ({"ExpirationDate": datetime.datetime(2020, 1, 1)}, {"ProvisionedDevices": ["device"]}, {"ProvisionedDevices": []}):
            with self.subTest(overrides=overrides), self.assertRaises(RuntimeError):
                validate(self.info, self.entitlements, {**self.profile, **overrides}, self.context)

    def test_profile_must_match_app_team_and_distribution(self):
        for overrides in ({"application-identifier": "VT7KXG8NBR.other.app"},
                          {"com.apple.developer.team-identifier": "OTHER"}, {"get-task-allow": True}):
            with self.subTest(overrides=overrides), self.assertRaises(RuntimeError):
                validate(self.info, self.entitlements, {**self.profile, "Entitlements": {**self.profile["Entitlements"], **overrides}}, self.context)
        with self.assertRaises(RuntimeError):
            validate(self.info, self.entitlements, {**self.profile, "TeamIdentifier": ["OTHER"]}, self.context)


if __name__ == "__main__":
    unittest.main()
