"""In-memory Apple GETs only; no credentials, altool, upload or actual sleep."""
import contextlib
import copy
import io
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import urllib.error
import urllib.parse

import ios_store as store

SENTINEL = 'PRIVATE_SYNTHETIC_ASC_SENTINEL'
BUILD = 'synthetic-build-id'
GROUP = 'synthetic-group-id'


def resource(kind, identifier, **attributes):
    return {'type': kind, 'id': identifier, 'attributes': attributes}


def page(items):
    return {'data': items, 'links': {'next': None}}


class AutomaticDistributionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.addCleanup(patch.stopall)
        self.root = Path(self.directory.name)
        self.context = {'platform': 'ios', 'channel': 'rc', 'destination': 'testflight',
                        'version': '1.2.3', 'build': 25, 'tag': 'rc/ios/v1.2.3+25'}
        self.config = {'app_id': store.RC_APP_ID, 'group': store.RC_GROUP, 'historical_floor': 24}
        self.groups = [resource('betaGroups', GROUP, name=store.RC_GROUP, isInternalGroup=True, hasAccessToAllBuilds=True)]
        self.app = resource('apps', store.RC_APP_ID, bundleId='com.auyltech.prokat', primaryLocale='ru')
        self.build = resource('builds', BUILD, version='25', processingState='VALID', expired=False)
        self.version = resource('preReleaseVersions', 'synthetic-version', version='1.2.3', platform='IOS')
        self.detail = resource('buildBetaDetails', 'synthetic-detail', internalBuildState='IN_BETA_TESTING')
        self.now, self.delays, self.requests, self.polls = 0, [], [], 0
        self.processing_delay = self.association_delay = self.internal_delay = self.discovery_delay = 0
        self.error = None
        self.discovery = [self.build]
        self.returned_build_id = BUILD
        patch.object(store, 'ROOT', self.root).start()
        patch.dict(store.os.environ, {'CM_BUILD_ID': 'fixture', 'CM_TAG': self.context['tag'],
                                     'TESTFLIGHT_GROUP': store.RC_GROUP}, clear=True).start()
        patch.object(store, 'prepare_apple_auth', return_value=(self.config, SENTINEL)).start()
        patch.object(store.time, 'monotonic', side_effect=lambda: self.now).start()
        patch.object(store.urllib.request, 'build_opener', return_value=SimpleNamespace(open=self.open_request)).start()
        self.publisher = patch.object(store.subprocess, 'run', side_effect=AssertionError('No publisher permitted')).start()
        self.addCleanup(self.publisher.assert_not_called)

    def open_request(self, request, timeout):
        self.requests.append(request)
        self.assertEqual(request.get_method(), 'GET')
        self.assertIsNone(request.data)
        self.assertGreater(timeout, 0)
        self.assertLessEqual(timeout, 15)
        if self.error:
            raise self.error
        parsed = urllib.parse.urlsplit(request.full_url)
        path = parsed.path
        if path == f'/v1/apps/{store.RC_APP_ID}':
            result = {'data': self.app}
        elif path == f'/v1/apps/{store.RC_APP_ID}/betaGroups':
            self.polls += 1
            result = page(self.groups)
        elif path.endswith('/buildUploads'):
            result = page([])
        elif path == f'/v1/betaGroups/{GROUP}/app' or path == f'/v1/builds/{BUILD}/app':
            result = {'data': self.app}
        elif path == '/v1/builds':
            query = urllib.parse.parse_qs(parsed.query)
            if 'filter[version]' in query:
                self.assertEqual(query['filter[app]'], [store.RC_APP_ID])
                self.assertEqual(query['filter[version]'], ['25'])
                self.assertEqual(query['filter[preReleaseVersion.version]'], ['1.2.3'])
                self.assertEqual(query['filter[preReleaseVersion.platform]'], ['IOS'])
                result = page([] if self.polls <= self.discovery_delay else self.discovery)
            else:
                result = page([])  # Existing pre-upload history is empty.
        elif path == f'/v1/builds/{BUILD}':
            item = copy.deepcopy(self.build)
            item['id'] = self.returned_build_id
            if self.polls <= self.processing_delay:
                item['attributes']['processingState'] = 'PROCESSING'
            result = {'data': item}
        elif path == f'/v1/builds/{BUILD}/preReleaseVersion':
            result = {'data': self.version}
        elif path == f'/v1/builds/{BUILD}/buildBetaDetail':
            item = copy.deepcopy(self.detail)
            if self.polls <= self.internal_delay:
                item['attributes']['internalBuildState'] = 'READY_FOR_BETA_TESTING'
            result = {'data': item}
        elif path == f'/v1/betaGroups/{GROUP}/relationships/builds':
            members = [] if self.polls <= self.association_delay else [{'type': 'builds', 'id': BUILD}]
            result = page(members)
        else:
            self.fail('Unexpected GET endpoint')
        return io.BytesIO(json.dumps(result).encode())

    def sleep(self, seconds):
        self.delays.append(seconds)
        self.now += seconds

    def confirm(self):
        with contextlib.redirect_stdout(io.StringIO()) as output, contextlib.redirect_stderr(io.StringIO()) as errors:
            try:
                result = store.confirm_testflight_distribution(self.context, GROUP, clock=lambda: self.now, sleep=self.sleep)
            finally:
                self.output = output.getvalue() + errors.getvalue()
                self.assertNotIn(SENTINEL, self.output)
        return result

    def assert_unconfirmed(self):
        with self.assertRaisesRegex(store.Blocked, '^TESTFLIGHT_DISTRIBUTION_UNCONFIRMED$'):
            self.confirm()
        self.assertNotIn('TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED', self.output)

    def test_valid_automatic_build_and_positive_relationship_pass_without_writes(self):
        with patch.object(Path, 'write_text') as text, patch.object(Path, 'write_bytes') as binary:
            self.assertEqual(self.confirm(), BUILD)
        text.assert_not_called()
        binary.assert_not_called()
        self.assertIn('TESTFLIGHT_INTERNAL_DISTRIBUTION_CONFIRMED', self.output)
        self.assertEqual(self.delays, [])
        self.assertEqual(self.polls, 1)

    def test_processing_internal_and_group_association_delays_poll_get_only(self):
        for field in ('processing_delay', 'internal_delay', 'association_delay'):
            self.polls, self.now, self.delays, self.requests = 0, 0, [], []
            setattr(self, field, 2)
            self.assertEqual(self.confirm(), BUILD)
            setattr(self, field, 0)
            self.assertEqual(self.polls, 3)
            self.assertEqual(self.delays, [20, 20])
            lookups = [r for r in self.requests if urllib.parse.urlsplit(r.full_url).path == '/v1/builds']
            self.assertEqual(len(lookups), 1)  # Exact lookup once; later polls pin the ID.

    def test_no_group_association_never_passes_on_has_access_flag_alone(self):
        self.association_delay = 10000
        self.assert_unconfirmed()
        self.assertLessEqual(self.polls, store.DISTRIBUTION_POLLS)
        self.assertEqual(self.now, store.DISTRIBUTION_TIMEOUT)

    def test_processing_never_completes_is_bounded(self):
        self.processing_delay = 10000
        self.assert_unconfirmed()
        self.assertEqual(self.now, store.DISTRIBUTION_TIMEOUT)

    def test_valid_empty_discovery_can_be_polled_but_never_uses_latest_build(self):
        self.discovery_delay = 2
        self.assertEqual(self.confirm(), BUILD)
        self.assertEqual(self.delays, [20, 20])
        self.assertEqual(self.polls, 3)

    def test_poll_count_is_finite_even_if_clock_does_not_advance(self):
        self.association_delay = 10000
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaisesRegex(
                store.Blocked, '^TESTFLIGHT_DISTRIBUTION_UNCONFIRMED$'):
            store.confirm_testflight_distribution(self.context, GROUP, clock=lambda: 0, sleep=lambda _: None)
        self.assertEqual(self.polls, store.DISTRIBUTION_POLLS)

    def test_wrong_id_build_number_version_platform_or_app_fail_closed(self):
        cases = ((self.build['attributes'], 'version', '26'),
                 (self.version['attributes'], 'version', '1.2.4'),
                 (self.version['attributes'], 'platform', 'TV_OS'),
                 (self.app['attributes'], 'bundleId', 'com.example.wrong'),
                 (self.app, 'id', '999999'))
        for target, field, value in cases:
            old = target[field]
            target[field] = value
            self.assert_unconfirmed()
            target[field] = old
        self.returned_build_id = 'wrong-build-id'
        self.assert_unconfirmed()

    def test_invalid_expired_and_unknown_states_fail_without_polling(self):
        for state in ('INVALID', 'FAILED', 'UNKNOWN', None):
            self.build['attributes']['processingState'] = state
            self.assert_unconfirmed()
        self.build['attributes']['processingState'] = 'VALID'
        self.build['attributes']['expired'] = True
        self.assert_unconfirmed()
        self.build['attributes']['expired'] = False
        self.detail['attributes']['internalBuildState'] = 'PROCESSING_EXCEPTION'
        self.assert_unconfirmed()
        self.assertEqual(self.delays, [])

    def test_duplicate_or_mismatched_build_discovery_is_not_latest_selection(self):
        self.discovery = [self.build, {**self.build, 'id': 'other-id'}]
        self.assert_unconfirmed()
        self.discovery = [resource('builds', BUILD, version='999')]
        self.assert_unconfirmed()

    def test_api_auth_forbidden_rate_limit_and_server_errors_are_not_polled(self):
        for status in (401, 403, 429, 503):
            self.requests.clear()
            self.error = urllib.error.HTTPError('https://api.appstoreconnect.apple.com/v1/apps/' + SENTINEL,
                                                status, SENTINEL, {}, io.BytesIO(SENTINEL.encode()))
            self.assert_unconfirmed()
            self.assertEqual(len(self.requests), 1)
            self.assertEqual(self.delays, [])

    def test_transport_timeout_and_unexpected_errors_fail_once_without_leaks(self):
        for error in (TimeoutError(SENTINEL), urllib.error.URLError(SENTINEL), RuntimeError(SENTINEL)):
            self.requests.clear()
            self.error = error
            self.assert_unconfirmed()
            self.assertEqual(len(self.requests), 1)
            self.assertEqual(self.delays, [])

    def test_preupload_manual_missing_ambiguous_or_unexpected_groups_block_publisher(self):
        release = self.root / 'build/release'
        release.mkdir(parents=True)
        (release / 'context.json').write_text(json.dumps(self.context))
        original = copy.deepcopy(self.groups[0])
        cases = ([], [original, {**original, 'id': 'duplicate'}],
                 [resource('betaGroups', GROUP, name=store.RC_GROUP, isInternalGroup=True, hasAccessToAllBuilds=False)],
                 [resource('betaGroups', GROUP, name=store.RC_GROUP, isInternalGroup=True)],
                 [resource('betaGroups', GROUP, name=store.RC_GROUP, isInternalGroup=False, hasAccessToAllBuilds=True)],
                 [resource('betaGroups', GROUP, name='Different group', isInternalGroup=True, hasAccessToAllBuilds=True)])
        for groups in cases:
            self.groups = groups
            with patch.object(store.sys, 'argv', ['ios_store.py', 'publish']), self.assertRaises(store.AppleCheckFailure):
                store.main()
            self.publisher.assert_not_called()
        self.groups = [original]
        self.config['app_id'] = '999999'
        with patch.object(store.sys, 'argv', ['ios_store.py', 'publish']), self.assertRaises(store.AppleCheckFailure):
            store.main()

    def test_late_ready_result_cannot_pass_after_deadline(self):
        original = self.open_request
        def late(request, timeout):
            result = original(request, timeout)
            if '/relationships/builds' in request.full_url:
                self.now = store.DISTRIBUTION_TIMEOUT + 1
            return result
        with patch.object(store.urllib.request, 'build_opener', return_value=SimpleNamespace(open=late)):
            self.assert_unconfirmed()

    def test_changed_group_id_or_mode_after_upload_is_not_accepted(self):
        self.groups[0]['id'] = 'replacement-group'
        self.assert_unconfirmed()
        self.groups[0]['id'] = GROUP
        self.groups[0]['attributes']['hasAccessToAllBuilds'] = False
        self.assert_unconfirmed()

    def test_official_group_relationship_is_fully_paginated(self):
        original = self.open_request
        def paginated(request, timeout):
            result = original(request, timeout)
            if '/relationships/builds' not in request.full_url:
                return result
            result.close()
            if 'cursor=second' in request.full_url:
                data = page([{'type': 'builds', 'id': BUILD}])
            else:
                data = {'data': [{'type': 'builds', 'id': 'old-build'}], 'links': {
                    'next': f'{store.API}/v1/betaGroups/{GROUP}/relationships/builds?limit=200&cursor=second'}}
            return io.BytesIO(json.dumps(data).encode())
        with patch.object(store.urllib.request, 'build_opener', return_value=SimpleNamespace(open=paginated)):
            self.assertEqual(self.confirm(), BUILD)
        self.assertEqual(len([r for r in self.requests if '/relationships/builds' in r.full_url]), 2)

    def test_unsafe_pagination_or_wrong_relationship_type_is_unconfirmed(self):
        original = self.open_request
        for kind in ('unsafe_url', 'wrong_type'):
            def invalid(request, timeout):
                result = original(request, timeout)
                if '/relationships/builds' not in request.full_url:
                    return result
                result.close()
                if kind == 'unsafe_url':
                    data = {'data': [], 'links': {'next': 'https://example.invalid/?secret=' + SENTINEL}}
                else:
                    data = page([{'type': 'apps', 'id': BUILD}])
                return io.BytesIO(json.dumps(data).encode())
            with patch.object(store.urllib.request, 'build_opener', return_value=SimpleNamespace(open=invalid)):
                self.assert_unconfirmed()
        self.assertTrue(all(urllib.parse.urlsplit(r.full_url).netloc == 'api.appstoreconnect.apple.com' for r in self.requests))


if __name__ == '__main__':
    unittest.main()
