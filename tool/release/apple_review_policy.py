"""Classify App Store version and review-submission state.

Categories are assigned inside each field from that field's own values.
The same name in appStoreState and appVersionState is not the same status.
No network, subprocess, environment access, or other side effects.
"""

APP_VERSION_ACTIVE = frozenset({
    "WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "ACCEPTED",
    "PENDING_APPLE_RELEASE", "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_DISTRIBUTION", "WAITING_FOR_EXPORT_COMPLIANCE",
})
APP_VERSION_EDITABLE = frozenset({
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "INVALID_BINARY",
})
APP_VERSION_FINAL = frozenset({
    "READY_FOR_DISTRIBUTION", "REPLACED_WITH_NEW_VERSION",
})
APP_STORE_ACTIVE = frozenset({
    "WAITING_FOR_REVIEW", "IN_REVIEW", "READY_FOR_REVIEW", "ACCEPTED",
    "PENDING_APPLE_RELEASE", "PENDING_DEVELOPER_RELEASE",
    "PROCESSING_FOR_APP_STORE", "WAITING_FOR_EXPORT_COMPLIANCE",
})
APP_STORE_EDITABLE = frozenset({
    "PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
    "METADATA_REJECTED", "INVALID_BINARY",
})
APP_STORE_FINAL = frozenset({
    "READY_FOR_SALE", "REPLACED_WITH_NEW_VERSION", "REMOVED_FROM_SALE",
    "DEVELOPER_REMOVED_FROM_SALE",
})
APP_STORE_UNSUPPORTED = frozenset({
    "PENDING_CONTRACT", "PREORDER_READY_FOR_SALE", "NOT_APPLICABLE",
})
SUBMISSION_STATES = frozenset({
    "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES",
    "CANCELING", "COMPLETING", "COMPLETE",
})


class Decision:
    def __init__(self, code, stage, version_id=None):
        self.code = code
        self.stage = stage
        self.version_id = version_id

    @property
    def ok(self):
        return self.code is None


def _text(value):
    if isinstance(value, str):
        return value
    enum_value = getattr(value, "value", None)
    return enum_value if isinstance(enum_value, str) else None


def _read(item, name):
    if isinstance(item, dict):
        return item.get(name)
    return getattr(item, name, None)


def _attributes(item):
    return _read(item, "attributes")


def _attribute(item, name):
    attributes = _attributes(item)
    if isinstance(attributes, dict):
        return attributes.get(name)
    return getattr(attributes, name, None)


def _category(value, active, editable, final, unsupported=frozenset()):
    if value in active:
        return "ACTIVE"
    if value in editable:
        return "EDITABLE"
    if value in final:
        return "FINAL"
    if value in unsupported:
        return "UNSUPPORTED"
    return None


def field_pair(app_store_state, app_version_state):
    """Pair outcome for two known field values. None means the value is outside 6.1."""
    store = _category(app_store_state, APP_STORE_ACTIVE, APP_STORE_EDITABLE, APP_STORE_FINAL, APP_STORE_UNSUPPORTED)
    version = _category(app_version_state, APP_VERSION_ACTIVE, APP_VERSION_EDITABLE, APP_VERSION_FINAL)
    if store is None or version is None:
        return None
    if store == "ACTIVE" or version == "ACTIVE":
        return "IN_FLIGHT"
    if store == "UNSUPPORTED" or version == "UNSUPPORTED":
        return "UNSUPPORTED"
    if store == "EDITABLE" and version == "EDITABLE":
        return "EDITABLE" if app_store_state == app_version_state else "MISMATCH"
    if store == "FINAL" and version == "FINAL":
        return "FINAL"
    if {store, version} == {"EDITABLE", "FINAL"}:
        return "MISMATCH"
    return None


def _components(value):
    text = _text(value)
    if text is None or text.count(".") > 2:
        return None
    parts = text.split(".")
    if not parts or any(not part.isdecimal() for part in parts):
        return None
    numbers = [int(part) for part in parts]
    return tuple(numbers + [0] * (3 - len(numbers)))


def _version_record(item):
    identifier = _text(_read(item, "id"))
    version_string = _attribute(item, "versionString")
    platform = _text(_attribute(item, "platform"))
    store_state = _text(_attribute(item, "appStoreState"))
    version_state = _text(_attribute(item, "appVersionState"))
    if (not identifier or _text(version_string) is None or platform != "IOS" or
            store_state is None or version_state is None or _components(version_string) is None or
            field_pair(store_state, version_state) is None):
        return None
    return identifier, _text(version_string), field_pair(store_state, version_state)


def _submission_record(item):
    identifier = _text(_read(item, "id"))
    platform = _text(_attribute(item, "platform"))
    state = _text(_attribute(item, "state"))
    if not identifier or platform != "IOS" or state not in SUBMISSION_STATES:
        return None
    return state


def classify(target_version, versions, submissions):
    """R1-R7 in order. code is None only when publication may continue."""
    if not isinstance(versions, list) or not isinstance(submissions, list):
        return Decision("APPLE_RESPONSE_INVALID", "versions")
    target = _components(target_version)
    if target is None:
        return Decision("APPLE_RESPONSE_INVALID", "versions")
    parsed_versions = []
    for item in versions:
        parsed = _version_record(item)
        if parsed is None:
            return Decision("APPLE_RESPONSE_INVALID", "versions")
        parsed_versions.append(parsed)
    parsed_submissions = []
    for item in submissions:
        parsed = _submission_record(item)
        if parsed is None:
            return Decision("APPLE_RESPONSE_INVALID", "submissions")
        parsed_submissions.append(parsed)
    if any(state != "COMPLETE" for state in parsed_submissions):
        return Decision("APPLE_REVIEW_SUBMISSION_OPEN", "submissions")
    if any(outcome == "IN_FLIGHT" for _, _, outcome in parsed_versions):
        return Decision("APPLE_VERSION_IN_FLIGHT", "versions")
    for _, _, outcome in parsed_versions:
        if outcome == "UNSUPPORTED":
            return Decision("APPLE_VERSION_STATE_UNSUPPORTED", "versions")
        if outcome == "MISMATCH":
            return Decision("APPLE_VERSION_STATE_MISMATCH", "versions")
    editable = [(identifier, version_string) for identifier, version_string, outcome in parsed_versions if outcome == "EDITABLE"]
    if len(editable) > 1 or (len(editable) == 1 and editable[0][1] != _text(target_version)):
        return Decision("APPLE_VERSION_CONFLICT", "versions")
    for _, version_string, outcome in parsed_versions:
        if outcome == "FINAL" and _components(version_string) >= target:
            return Decision("APPLE_VERSION_NOT_INCREASING", "versions")
    if len(editable) == 1:
        return Decision(None, "versions", editable[0][0])
    return Decision(None, "versions")
