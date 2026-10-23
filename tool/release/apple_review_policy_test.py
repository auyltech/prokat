import unittest

import apple_review_policy as policy


STORE_ACTIVE = {
    "WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "ACCEPTED",
    "PENDING_APPLE_RELEASE", "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_APP_STORE", "WAITING_FOR_EXPORT_COMPLIANCE",
}
STORE_EDITABLE = {
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "INVALID_BINARY",
}
STORE_FINAL = {
    "READY_FOR_SALE", "REPLACED_WITH_NEW_VERSION", "REMOVED_FROM_SALE",
    "DEVELOPER_REMOVED_FROM_SALE",
}
STORE_UNSUPPORTED = {"PENDING_CONTRACT", "PREORDER_READY_FOR_SALE", "NOT_APPLICABLE"}
VERSION_ACTIVE = {
    "WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "ACCEPTED",
    "PENDING_APPLE_RELEASE", "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_DISTRIBUTION", "WAITING_FOR_EXPORT_COMPLIANCE",
}
VERSION_EDITABLE = {
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "INVALID_BINARY",
}
VERSION_FINAL = {"READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_VERSION"}
SUBMISSION_STATES = {
    "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES",
    "CANCELING", "COMPLETING", "COMPLETE",
}


def expected_pair(store_state, version_state):
    def category(value, active, editable, final, unsupported=()):
        if value in active:
            return "ACTIVE"
        if value in editable:
            return "EDITABLE"
        if value in final:
            return "FINAL"
        if value in unsupported:
            return "UNSUPPORTED"
        raise AssertionError(value)

    store = category(store_state, STORE_ACTIVE, STORE_EDITABLE, STORE_FINAL, STORE_UNSUPPORTED)
    version = category(version_state, VERSION_ACTIVE, VERSION_EDITABLE, VERSION_FINAL)
    if store == "ACTIVE" or version == "ACTIVE":
        return "IN_FLIGHT"
    if store == "UNSUPPORTED" or version == "UNSUPPORTED":
        return "UNSUPPORTED"
    if store == "EDITABLE" and version == "EDITABLE":
        return "EDITABLE" if store_state == version_state else "MISMATCH"
    if store == "FINAL" and version == "FINAL":
        return "FINAL"
    if {store, version} == {"EDITABLE", "FINAL"}:
        return "MISMATCH"
    raise AssertionError((store_state, version_state))


def version(identifier, version_string, store_state, version_state):
    return {"id": identifier, "attributes": {
        "versionString": version_string, "platform": "IOS",
        "appStoreState": store_state, "appVersionState": version_state}}


def submission(identifier, state):
    return {"id": identifier, "attributes": {"platform": "IOS", "state": state}}


class ReviewPairTests(unittest.TestCase):
    def test_every_documented_pair_matches_the_field_table(self):
        store_states = STORE_ACTIVE | STORE_EDITABLE | STORE_FINAL | STORE_UNSUPPORTED
        version_states = VERSION_ACTIVE | VERSION_EDITABLE | VERSION_FINAL
        self.assertEqual(len(store_states), 20)
        self.assertEqual(len(version_states), 15)
        self.assertEqual(len(store_states) * len(version_states), 300)
        for store_state in store_states:
            for version_state in version_states:
                with self.subTest(store_state=store_state, version_state=version_state):
                    self.assertEqual(policy.field_pair(store_state, version_state), expected_pair(store_state, version_state))

    def test_named_pairs(self):
        cases = (
            ("IN_REVIEW", "READY_FOR_DISTRIBUTION", "IN_FLIGHT"),
            ("READY_FOR_SALE", "IN_REVIEW", "IN_FLIGHT"),
            ("PROCESSING_FOR_APP_STORE", "READY_FOR_DISTRIBUTION", "IN_FLIGHT"),
            ("PREPARE_FOR_SUBMISSION", "READY_FOR_DISTRIBUTION", "MISMATCH"),
            ("REJECTED", "METADATA_REJECTED", "MISMATCH"),
            ("NOT_APPLICABLE", "PREPARE_FOR_SUBMISSION", "UNSUPPORTED"),
            ("PENDING_CONTRACT", "READY_FOR_DISTRIBUTION", "UNSUPPORTED"),
            ("REMOVED_FROM_SALE", "READY_FOR_DISTRIBUTION", "FINAL"),
        )
        for store_state, version_state, expected in cases:
            with self.subTest(store_state=store_state, version_state=version_state):
                self.assertEqual(policy.field_pair(store_state, version_state), expected)
                if expected == "IN_FLIGHT":
                    decision = policy.classify("2.0.0", [version("v", "1.0.0", store_state, version_state)], [])
                    self.assertEqual(decision.code, "APPLE_VERSION_IN_FLIGHT")


class ReviewRuleTests(unittest.TestCase):
    def test_unknown_value_or_missing_field_is_invalid(self):
        self.assertEqual(policy.classify("1.0.0", [version("v", "1.0.0", "FUTURE", "PREPARE_FOR_SUBMISSION")], []).code, "APPLE_RESPONSE_INVALID")
        incomplete = {"id": "v", "attributes": {"platform": "IOS", "appStoreState": "PREPARE_FOR_SUBMISSION"}}
        self.assertEqual(policy.classify("1.0.0", [incomplete], []).code, "APPLE_RESPONSE_INVALID")
        self.assertIsNone(policy.field_pair("NOT_A_STATE", "PREPARE_FOR_SUBMISSION"))

    def test_each_submission_state_and_unknown_submission(self):
        for state in SUBMISSION_STATES:
            decision = policy.classify("2.0.0", [], [submission("s", state)])
            with self.subTest(state=state):
                if state == "COMPLETE":
                    self.assertIsNone(decision.code)
                else:
                    self.assertEqual(decision.code, "APPLE_REVIEW_SUBMISSION_OPEN")
        self.assertEqual(policy.classify("2.0.0", [], [submission("s", "FUTURE")]).code, "APPLE_RESPONSE_INVALID")
        self.assertEqual(policy.classify("2.0.0", [], [{"id": "s", "attributes": {"platform": "IOS"}}]).code, "APPLE_RESPONSE_INVALID")

    def test_rules_in_order_and_each_rule(self):
        editable = version("edit", "2.0.0", "PREPARE_FOR_SUBMISSION", "PREPARE_FOR_SUBMISSION")
        inflight = version("fly", "1.0.0", "IN_REVIEW", "READY_FOR_DISTRIBUTION")
        self.assertEqual(policy.classify("2.0.0", [inflight], [submission("s", "IN_REVIEW")]).code, "APPLE_REVIEW_SUBMISSION_OPEN")
        self.assertEqual(policy.classify("2.0.0", [inflight], []).code, "APPLE_VERSION_IN_FLIGHT")
        self.assertEqual(policy.classify("2.0.0", [version("u", "1.0.0", "NOT_APPLICABLE", "PREPARE_FOR_SUBMISSION")], []).code, "APPLE_VERSION_STATE_UNSUPPORTED")
        self.assertEqual(policy.classify("2.0.0", [version("m", "1.0.0", "PREPARE_FOR_SUBMISSION", "READY_FOR_DISTRIBUTION")], []).code, "APPLE_VERSION_STATE_MISMATCH")
        other = version("other", "1.0.0", "REJECTED", "REJECTED")
        self.assertEqual(policy.classify("2.0.0", [editable, other], []).code, "APPLE_VERSION_CONFLICT")
        self.assertEqual(policy.classify("2.0.0", [version("old", "9.0.0", "READY_FOR_SALE", "READY_FOR_DISTRIBUTION")], []).code, "APPLE_VERSION_NOT_INCREASING")
        created = policy.classify("2.0.0", [version("done", "1.0.0", "READY_FOR_SALE", "READY_FOR_DISTRIBUTION")], [submission("s", "COMPLETE")])
        self.assertIsNone(created.code)
        self.assertIsNone(created.version_id)
        continued = policy.classify("2.0.0", [editable], [])
        self.assertIsNone(continued.code)
        self.assertEqual(continued.version_id, "edit")

    def test_active_blocks_and_mismatch_is_unknown(self):
        for store_state in STORE_ACTIVE:
            decision = policy.classify("3.0.0", [version("v", "1.0.0", store_state, "READY_FOR_DISTRIBUTION")], [])
            self.assertEqual(decision.code, "APPLE_VERSION_IN_FLIGHT")
        for version_state in VERSION_ACTIVE:
            decision = policy.classify("3.0.0", [version("v", "1.0.0", "READY_FOR_SALE", version_state)], [])
            self.assertEqual(decision.code, "APPLE_VERSION_IN_FLIGHT")
        mismatch = policy.classify("3.0.0", [version("v", "1.0.0", "REJECTED", "METADATA_REJECTED")], [])
        self.assertEqual(mismatch.code, "APPLE_VERSION_STATE_MISMATCH")


if __name__ == "__main__":
    unittest.main()
