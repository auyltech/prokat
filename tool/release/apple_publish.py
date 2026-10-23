"""Pinned Codemagic CLI with fail-closed What's New updates, not a new publisher.

CLI 0.70.0 catches localization API errors and may continue to App Review.
Replace only that method: update existing locales, never create listing locales,
and stop before submission on missing translations or any metadata API failure.
"""
import contextlib
import copy
from importlib.metadata import version
import inspect
import io
import json
import sys
from types import SimpleNamespace

import apple_review_policy

CLI_VERSION = "0.70.0"
_GUARD_INSTALLED = False
_ORIGINAL_CONFIRM = None
_ORIGINAL_ITEM = None
_ORIGINAL_ENSURE = None
_ORIGINAL_CREATE_SUBMISSION = None
_GUARD = SimpleNamespace(version_id=None, submission_id=None, item_id=None)


class PublishCliError(RuntimeError):
    """Fixed, safe diagnostics only; never include argparse output or values."""


def require_supported_cli():
    try:
        if version("codemagic-cli-tools") == CLI_VERSION:
            return
    except Exception:
        pass
    raise PublishCliError("APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED")


def validate_publish_arguments(args):
    """Parse the entire generated argv with the pinned SDK, without invoking it.

    Do not instantiate AppStoreConnect, resolve credential environment defaults,
    create an API client, configure logging, invoke actions or launch altool.
    Explicit @file: Git localizations are parsed exactly as in real publishing.
    """
    require_supported_cli()
    try:
        from codemagic.tools.app_store_connect import AppStoreConnect
        from codemagic.tools.app_store_connect.arguments import Types

        # argparse errors can contain metadata, paths and argument values.
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            parsed = AppStoreConnect._setup_cli_options().parse_args(args)
            if not AppStoreConnect._validate_args(parsed):
                raise ValueError
        if parsed.action != "publish" or parsed.show_version:
            raise ValueError
        if not parsed.submit_to_app_store and (parsed.beta_group_names or parsed.submit_to_testflight):
            # Internal Automatic Distribution must not become manual assignment
            # or external Beta App Review. Production argument behavior is unchanged.
            raise ValueError
        # All three CLI options are attempt counts in 0.70.0, not extra retries.
        # Missing flags must not silently enable defaults (10 / 3 / 3).
        for flag, attribute, kind in (
            ("--altool-retries", "altool_retries_count", Types.AltoolRetriesCount),
            ("--api-server-error-retries", "server_error_retries", Types.ApiServerErrorRetries),
            ("--api-unauthorized-retries", "unauthorized_request_retries", Types.ApiUnauthorizedRetries),
        ):
            if args.count(flag) != 1 or kind.resolve_value(getattr(parsed, attribute)) != 1:
                raise ValueError
        return parsed
    except (Exception, SystemExit):
        raise PublishCliError("APPLE_PUBLISH_ARGUMENTS_INVALID") from None


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


def _block(code):
    raise SystemExit(f"BLOCKED: {code}; no further App Store mutation. Inspect build uploads; no reupload") from None


def _mutation(operation):
    """Run one store mutation. A raised error means the outcome is unknown.

    The request may already have reached Apple. The original exception can
    contain the response body, so it is not printed and the call is not retried.
    """
    try:
        return operation()
    except Exception:
        _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")


def _bound_id(value):
    return isinstance(value, str) and bool(value)


def _reset_guard():
    _GUARD.version_id = None
    _GUARD.submission_id = None
    _GUARD.item_id = None


def _resource_id(resource):
    identifier = getattr(resource, "id", None)
    return identifier if isinstance(identifier, str) and identifier else None


def _resource_version(resource):
    attributes = getattr(resource, "attributes", None)
    value = getattr(attributes, "versionString", None)
    if value is None and isinstance(attributes, dict):
        value = attributes.get("versionString")
    return value if isinstance(value, str) else None


def _parameter_names(method):
    return [parameter.name for parameter in inspect.signature(method).parameters.values()]


def install_submission_guards():
    """Replace the four production mutation methods. The API confirm is not atomic."""
    global _GUARD_INSTALLED, _ORIGINAL_CONFIRM, _ORIGINAL_ITEM, _ORIGINAL_ENSURE, _ORIGINAL_CREATE_SUBMISSION
    from codemagic.tools.app_store_connect import AppStoreConnect
    from codemagic.tools.app_store_connect.action_groups.review_submission_items_actions_group import ReviewSubmissionItemsActionGroup
    from codemagic.tools.app_store_connect.action_groups.review_submissions_actions_group import ReviewSubmissionsActionGroup
    from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction

    methods = {
        "ensure": (SubmitToAppStoreAction, "_ensure_app_store_version",
                   ["self", "app", "build", "app_store_version_info"]),
        "submission": (SubmitToAppStoreAction, "_create_review_submission", ["self", "app", "platform"]),
        "item": (ReviewSubmissionItemsActionGroup, "create_review_submission_item", [
            "self", "review_submission_id", "app_custom_product_page_version_id", "app_event_id",
            "app_store_version_id", "app_store_version_experiment_id", "should_print"]),
        "confirm": (ReviewSubmissionsActionGroup, "confirm_review_submission",
                    ["self", "review_submission_id", "should_print"]),
    }
    resolved = {}
    for key, (owner, name, expected_names) in methods.items():
        try:
            method = getattr(owner, name)
            resolved_on_client = getattr(AppStoreConnect, name)
        except AttributeError:
            raise PublishCliError("APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED") from None
        if not callable(method) or _parameter_names(method) != expected_names or resolved_on_client is not method:
            raise PublishCliError("APPLE_PUBLISH_CLI_VERSION_UNSUPPORTED")
        resolved[key] = method
    if _GUARD_INSTALLED:
        return
    _ORIGINAL_ENSURE = resolved["ensure"]
    _ORIGINAL_CREATE_SUBMISSION = resolved["submission"]
    _ORIGINAL_ITEM = resolved["item"]
    _ORIGINAL_CONFIRM = resolved["confirm"]
    SubmitToAppStoreAction._ensure_app_store_version = guarded_ensure_version
    SubmitToAppStoreAction._create_review_submission = guarded_create_submission
    ReviewSubmissionItemsActionGroup.create_review_submission_item = guarded_create_item
    ReviewSubmissionsActionGroup.confirm_review_submission = guarded_confirm
    _GUARD_INSTALLED = True


def restore_submission_guards():
    global _GUARD_INSTALLED, _ORIGINAL_CONFIRM, _ORIGINAL_ITEM, _ORIGINAL_ENSURE, _ORIGINAL_CREATE_SUBMISSION
    if not _GUARD_INSTALLED:
        _reset_guard()
        return
    from codemagic.tools.app_store_connect.action_groups.review_submission_items_actions_group import ReviewSubmissionItemsActionGroup
    from codemagic.tools.app_store_connect.action_groups.review_submissions_actions_group import ReviewSubmissionsActionGroup
    from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
    SubmitToAppStoreAction._ensure_app_store_version = _ORIGINAL_ENSURE
    SubmitToAppStoreAction._create_review_submission = _ORIGINAL_CREATE_SUBMISSION
    ReviewSubmissionItemsActionGroup.create_review_submission_item = _ORIGINAL_ITEM
    ReviewSubmissionsActionGroup.confirm_review_submission = _ORIGINAL_CONFIRM
    _ORIGINAL_ENSURE = None
    _ORIGINAL_CREATE_SUBMISSION = None
    _ORIGINAL_CONFIRM = None
    _ORIGINAL_ITEM = None
    _GUARD_INSTALLED = False
    _reset_guard()


def _submission_views(items):
    views = []
    for item in items:
        state = apple_review_policy._text(apple_review_policy._attribute(item, "state"))
        platform = apple_review_policy._text(apple_review_policy._attribute(item, "platform"))
        identifier = apple_review_policy._text(apple_review_policy._read(item, "id"))
        views.append({"id": identifier, "attributes": {"platform": platform, "state": state}})
    return views


def _version_views(items):
    views = []
    for item in items:
        views.append({
            "id": apple_review_policy._text(apple_review_policy._read(item, "id")),
            "attributes": {
                "versionString": apple_review_policy._text(apple_review_policy._attribute(item, "versionString")),
                "platform": apple_review_policy._text(apple_review_policy._attribute(item, "platform")),
                "appStoreState": apple_review_policy._text(apple_review_policy._attribute(item, "appStoreState")),
                "appVersionState": apple_review_policy._text(apple_review_policy._attribute(item, "appVersionState")),
            },
        })
    return views


def guarded_ensure_version(self, app, build, app_store_version_info):
    if _GUARD.version_id is not None or _GUARD.submission_id is not None or _GUARD.item_id is not None:
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    _reset_guard()
    from codemagic.apple.app_store_connect.versioning.app_store_versions import AppStoreVersions
    from codemagic.apple.app_store_connect.versioning.review_submissions import ReviewSubmissions
    from codemagic.apple.resources import Platform
    try:
        versions = self.api_client.apps.list_app_store_versions_data(
            app, resource_filter=AppStoreVersions.Filter(platform=Platform.IOS))
        submissions = self.api_client.review_submissions.list(
            ReviewSubmissions.Filter(app=app.id, platform=Platform.IOS))
    except Exception:
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    decision = apple_review_policy.classify(
        getattr(app_store_version_info, "version_string", None), _version_views(versions), _submission_views(submissions))
    if not decision.ok:
        _block(decision.code)
    if decision.version_id is None:
        result = _mutation(lambda: self.create_app_store_version(
            build.id,
            platform=app_store_version_info.platform,
            copyright=getattr(app_store_version_info, "copyright", None),
            earliest_release_date=getattr(app_store_version_info, "earliest_release_date", None),
            release_type=getattr(app_store_version_info, "release_type", None),
            version_string=app_store_version_info.version_string,
        ))
        if not getattr(result, "created", False):
            _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    else:
        approved = SimpleNamespace(id=decision.version_id, attributes=SimpleNamespace(appStoreState="PREPARE_FOR_SUBMISSION"))
        result = _mutation(lambda: self._update_existing_app_store_version(approved, build, app_store_version_info))
        if getattr(result, "created", False) or _resource_id(result) != decision.version_id:
            _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    if _resource_version(result) != app_store_version_info.version_string:
        _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    _GUARD.version_id = _resource_id(result)
    if _GUARD.version_id is None:
        _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    return result


def guarded_create_submission(self, app, platform):
    if _GUARD.version_id is None or _GUARD.submission_id is not None or _GUARD.item_id is not None:
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    from codemagic.apple.app_store_connect.versioning.review_submissions import ReviewSubmissions
    try:
        existing = self.api_client.review_submissions.list(ReviewSubmissions.Filter(app=app.id, platform=platform))
    except Exception:
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    decision = apple_review_policy.classify("1.0.0", [], _submission_views(existing))
    if decision.code == "APPLE_RESPONSE_INVALID":
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    if not decision.ok:
        _block(decision.code)
    created = _mutation(lambda: self.api_client.review_submissions.create(platform, app))
    if not getattr(created, "created", False) or not _resource_id(created):
        _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    _GUARD.submission_id = _resource_id(created)
    return created


def guarded_create_item(self, review_submission_id, app_custom_product_page_version_id=None, app_event_id=None,
                        app_store_version_id=None, app_store_version_experiment_id=None, should_print=True):
    if (not _bound_id(_GUARD.version_id) or not _bound_id(_GUARD.submission_id) or
            _GUARD.item_id is not None or review_submission_id != _GUARD.submission_id or
            app_store_version_id != _GUARD.version_id or app_custom_product_page_version_id or
            app_event_id or app_store_version_experiment_id):
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    created = _mutation(lambda: _ORIGINAL_ITEM(
        self, review_submission_id, app_custom_product_page_version_id, app_event_id,
        app_store_version_id, app_store_version_experiment_id, should_print))
    identifier = _resource_id(created)
    if not getattr(created, "created", False) or not identifier:
        _block("APPLE_SUBMISSION_OUTCOME_UNKNOWN")
    _GUARD.item_id = identifier
    return created


def guarded_confirm(self, review_submission_id, should_print=True):
    # list_items and the following PATCH are separate requests. This is not an atomic confirm.
    if not _bound_id(_GUARD.submission_id) or review_submission_id != _GUARD.submission_id or not _bound_id(_GUARD.item_id):
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    try:
        before = self.api_client.review_submissions.list_items(_GUARD.submission_id)
    except Exception:
        _block("APPLE_SUBMISSION_GUARD_FAILED")
    if [_resource_id(item) for item in before] != [_GUARD.item_id]:
        _block("APPLE_SUBMISSION_ITEMS_CHANGED")
    result = _mutation(lambda: _ORIGINAL_CONFIRM(self, review_submission_id, should_print=should_print))
    try:
        after = self.api_client.review_submissions.list_items(_GUARD.submission_id)
        confirmed = [_resource_id(item) for item in after] == [_GUARD.item_id]
    except Exception:
        confirmed = False
    if not confirmed:
        print("APPLE_SUBMISSION_ITEMS_CHANGED_AFTER_CONFIRM", flush=True)
        raise SystemExit(1)
    print("APPLE_REVIEW_SUBMISSION_CONFIRMED", flush=True)
    return result


def _publisher_context(parsed):
    import ios_store as store

    try:
        context = json.loads((store.ROOT / "build/release/context.json").read_text(encoding="utf-8"))
        tag = context["tag"]
        channel = context["channel"]
        platform = context["platform"]
    except Exception:
        raise SystemExit("BLOCKED: APPLE_PUBLISH_CONTEXT_INVALID") from None
    if platform != "ios" or channel not in ("rc", "production") or not isinstance(tag, str) or not tag:
        raise SystemExit("BLOCKED: APPLE_PUBLISH_CONTEXT_INVALID") from None
    if bool(parsed.submit_to_app_store) != (channel == "production"):
        raise SystemExit("BLOCKED: APPLE_PUBLISH_CONTEXT_INVALID") from None
    return tag


def main():
    try:
        parsed = validate_publish_arguments(sys.argv[1:])
        if parsed.submit_to_app_store:
            install_submission_guards()
    except PublishCliError as error:
        raise SystemExit(f"BLOCKED: {error}") from None
    tag = _publisher_context(parsed)
    from codemagic.tools.app_store_connect import AppStoreConnect
    from codemagic.tools.app_store_connect.actions.submit_to_app_store_action import SubmitToAppStoreAction
    SubmitToAppStoreAction._create_or_update_app_store_version_localizations = strict_localizations
    # Control has reached the publisher. This does not prove a store mutation.
    print(f"PUBLISHER_INVOKED platform=ios tag={tag}", flush=True)
    AppStoreConnect.invoke_cli()


if __name__ == "__main__":
    main()
