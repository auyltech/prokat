"""Synthetic resolver logs, fake clocks/runners and disposable lock fixtures only."""
import contextlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import swiftpm_resolve as swiftpm

SENTINEL = "PRIVATE_SWIFTPM_TEST_SENTINEL_NEVER_LOG"
SUMMARY = "xcodebuild: error: Could not resolve package dependencies:\n"
TIMEOUT = SUMMARY + "failed downloading 'https://example.invalid/sdk.zip'\ndownloadError(\"The request timed out.\")"


class FakeClock:
    def __init__(self):
        self.now = 0
        self.delays = []

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.delays.append(seconds)
        self.now += seconds


class SwiftPMRetryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.baseline = {}
        for path in swiftpm.LOCKS:
            value = ("synthetic locked content: " + path).encode()
            file = self.root / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(value)
            self.baseline[path] = value
        self.clock = FakeClock()
        self.messages = []
        self.calls = []

    def run_resolve(self, results, *, durations=None, mutate=None, started=0):
        results = iter(results)
        durations = iter(durations or [0, 0, 0])

        def runner(root, timeout):
            self.calls.append((root, timeout))
            self.clock.now += next(durations)
            if mutate:
                mutate(len(self.calls))
            return next(results)

        status = swiftpm.resolve(self.root, started, runner=runner, clock=self.clock, sleep=self.clock.sleep,
                                 emit=self.messages.append, baseline_loader=lambda root: self.baseline)
        self.assertNotIn(SENTINEL, "\n".join(self.messages))
        self.assertTrue(all(timeout == 600 for _, timeout in self.calls))
        return status

    def test_first_attempt_success(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(0, SENTINEL)]), 0)
        self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])
        self.assertEqual(self.messages, ["SwiftPM resolution attempt 1/3", "SwiftPM dependencies resolved successfully"])

    def test_one_timeout_then_success(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT + SENTINEL), swiftpm.Attempt(0, "")]), 0)
        self.assertEqual(len(self.calls), 2)
        self.assertEqual(self.clock.delays, [15])

    def test_two_timeouts_then_success(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)] * 2 + [swiftpm.Attempt(0, "")], durations=[222, 222, 222]), 0)
        self.assertEqual(len(self.calls), 3)
        self.assertEqual(self.clock.delays, [15, 45])
        self.assertEqual(self.clock.now, 726)

    def test_three_timeouts_preserve_original_exit_code(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)] * 3), 74)
        self.assertEqual(len(self.calls), 3)
        self.assertEqual(self.clock.delays, [15, 45])
        self.assertEqual(self.messages[-1], "SwiftPM resolution failed: retry limit reached")

    def test_incident_order_with_summary_after_download_error_is_retryable(self):
        output = ("failed downloading 'https://example.invalid/recaptcha-sdk-xcframework.xcframework.zip'\n"
                  'downloadError("The request timed out.")\n'
                  'xcodebuild: error: Could not resolve package dependencies\n')
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, output), swiftpm.Attempt(0, "")]), 0)
        self.assertEqual(len(self.calls), 2)
        self.assertEqual(self.clock.delays, [15])

    def test_manifest_compatibility_checksum_signing_and_unknown_errors_do_not_retry(self):
        failures = ("error: Invalid manifest", "error: Package.swift:10: syntax error",
                    "error: incompatible package version", "error: no versions of package match 1.2.3",
                    "error: SDK checksum does not match", "error: invalid SDK signature",
                    "error: certificate verification failed", "error: project does not exist",
                    "error: Package.resolved file is required", "error: unexpected opaque failure")
        for failure in failures:
            with self.subTest(failure=failure):
                self.calls.clear()
                self.assertEqual(self.run_resolve([swiftpm.Attempt(74, SUMMARY + failure)]), 74)
                self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])

    def test_exit_74_without_network_or_unknown_exit_with_network_never_retries(self):
        for result in (swiftpm.Attempt(74, ""), swiftpm.Attempt(74, SENTINEL), swiftpm.Attempt(91, TIMEOUT),
                       swiftpm.Attempt(65, TIMEOUT), swiftpm.Attempt(-15, TIMEOUT)):
            self.calls.clear()
            self.assertEqual(self.run_resolve([result]), result.returncode if result.returncode > 0 else 143)
            self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])

    def test_http_errors_and_connection_failures_are_narrowly_classified(self):
        for failure in ("HTTP 429", "HTTP 502", "HTTP 503", "HTTP/2 504", "badResponseStatusCode(503)",
                        "Connection reset by peer", "Connection interrupted", "Could not resolve host",
                        "Temporary failure in name resolution", "Network is unreachable", "NSURLErrorDomain Code=-1009"):
            with self.subTest(kind=failure):
                result = swiftpm.Attempt(74, SUMMARY + "failed downloading 'https://example.invalid/sdk.zip'\ndownloadError(\"" + failure + "\")")
                self.assertTrue(swiftpm.transient_download_failure(result))
        for failure in ("HTTP 401", "HTTP 403", "HTTP 404", "HTTP 500", "unknown status 503", "checksum mismatch"):
            self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, SUMMARY + "downloadError(\"" + failure + "\")")))

    def test_http_503_then_success_runs_exactly_twice(self):
        log = SUMMARY + "failed downloading 'https://example.invalid/sdk.zip'\ndownloadError(\"HTTP 503\")"
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, log), swiftpm.Attempt(0, "")]), 0)
        self.assertEqual(len(self.calls), 2)
        self.assertEqual(self.clock.delays, [15])

    def test_mixed_or_unrelated_network_message_does_not_hide_unknown_errors(self):
        for text in (TIMEOUT + "\nerror: unknown project failure", TIMEOUT + "\nchecksum mismatch",
                     TIMEOUT + "\nsome unexpected failure", "warning: The request timed out\nerror: bad project"):
            self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, text)))

    def test_lock_change_stops_before_backoff_even_with_network_error(self):
        def mutate(attempt):
            (self.root / swiftpm.LOCKS[2]).write_text("changed")
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)], mutate=mutate), 1)
        self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])
        self.assertEqual(self.messages[-1], "BLOCKED: SWIFTPM_LOCK_GUARD_FAILED")

    def test_lock_change_after_success_is_not_success(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(0, "")], mutate=lambda _: (self.root / swiftpm.LOCKS[1]).unlink()), 1)
        self.assertNotIn("SwiftPM dependencies resolved successfully", self.messages)

    def test_missing_or_already_changed_lock_stops_before_command(self):
        (self.root / swiftpm.LOCKS[0]).unlink()
        self.assertEqual(self.run_resolve([]), 1)
        self.assertEqual(self.calls, [])

    def test_locks_rechecked_after_backoff(self):
        def delay(seconds):
            self.clock.now += seconds
            self.clock.delays.append(seconds)
            (self.root / swiftpm.LOCKS[3]).write_text("drift during sleep")
        with patch.object(self.clock, "sleep", side_effect=delay):
            self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)]), 1)
        self.assertEqual(len(self.calls), 1)

    def test_budget_reserves_full_attempt_and_counts_previous_attempts_and_backoff(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)] * 3, durations=[590, 590, 590]), 74)
        self.assertEqual(len(self.calls), 3)
        self.assertEqual(self.clock.now, 1830)

    def test_insufficient_phase_budget_stops_before_retry_and_preserves_error(self):
        self.clock.now = 2900  # Only 700 seconds left in the source-script phase.
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)], durations=[222]), 74)
        self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])
        self.assertEqual(self.messages[-1], "SwiftPM resolution failed: insufficient time budget")

    def test_initial_budget_exhausted_never_starts_a_command(self):
        self.clock.now = 3600
        self.assertEqual(self.run_resolve([]), 75)
        self.assertEqual(self.calls, [])

    def test_late_success_cannot_pass_an_exhausted_deadline(self):
        self.clock.now = 2900
        self.assertEqual(self.run_resolve([swiftpm.Attempt(0, "")], durations=[701]), 75)
        self.assertNotIn("SwiftPM dependencies resolved successfully", self.messages)

    def test_missing_timer_or_wrong_context_never_runs_the_resolver(self):
        env = {"CI": "true", "CM_BUILD_ID": "synthetic-build", "CM_COMMIT": "a" * 40}
        with patch.object(swiftpm, "resolve") as resolve, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(swiftpm.main(["resolve"], root=self.root, env=env), 1)
            self.assertEqual(swiftpm.main(["start"], root=self.root, env={**env, "CI": "false"}), 1)
        resolve.assert_not_called()

    def test_overslept_budget_stops_before_next_attempt(self):
        def delay(_):
            self.clock.now += swiftpm.TOTAL_SECONDS
        with patch.object(self.clock, "sleep", side_effect=delay):
            self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)]), 74)
        self.assertEqual(len(self.calls), 1)

    def test_outer_timeout_is_not_retried_based_on_partial_network_output(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(124, TIMEOUT, timed_out=True)], durations=[600]), 124)
        self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])

    def test_baseline_is_head_not_current_worktree_and_git_errors_are_sanitized(self):
        def git(args, **kwargs):
            path = args[-1].removeprefix("HEAD:")
            return SimpleNamespace(returncode=0, stdout=self.baseline[path], stderr=SENTINEL.encode())
        with patch.object(swiftpm.subprocess, "run", side_effect=git) as run:
            self.assertEqual(swiftpm.locked_inputs(self.root), self.baseline)
            self.assertEqual(run.call_count, 4)
            (self.root / swiftpm.LOCKS[0]).write_text("dirty before first resolve")
            with self.assertRaises(swiftpm.LockFailure):
                swiftpm.locked_inputs(self.root)

    def test_exact_runner_command_and_output_capture_no_tee_no_publish(self):
        process = SimpleNamespace(returncode=74, communicate=lambda **kwargs: (TIMEOUT.encode(), None))
        with patch.object(swiftpm.subprocess, "Popen", return_value=process) as popen:
            result = swiftpm.run_xcodebuild(self.root, 600)
        self.assertEqual(result.returncode, 74)
        args, kwargs = popen.call_args
        self.assertEqual(args[0], swiftpm.command(self.root))
        self.assertEqual(args[0][0:2], ["xcodebuild", "-resolvePackageDependencies"])
        self.assertIn("-onlyUsePackageVersionsFromResolvedFile", args[0])
        self.assertEqual(kwargs['stdout'], subprocess.PIPE)
        self.assertEqual(kwargs['stderr'], subprocess.STDOUT)
        self.assertTrue(kwargs['start_new_session'])
        self.assertNotIn('shell', kwargs)
        for forbidden in ('publish', 'ipa', 'archive', 'update', '--create'):
            self.assertNotIn(forbidden, args[0])

    def test_runner_timeout_cleans_process_group_and_does_not_print_partial_log(self):
        process = SimpleNamespace(communicate=lambda **kwargs: (_ for _ in ()).throw(
            subprocess.TimeoutExpired(SENTINEL, 600, output=SENTINEL.encode())))
        with patch.object(swiftpm.subprocess, "Popen", return_value=process), \
                patch.object(swiftpm, "stop_process") as stop:
            # Keep partial output in memory for the safe projection, never print it raw.
            self.assertEqual(swiftpm.run_xcodebuild(self.root, 600), swiftpm.Attempt(124, SENTINEL, True))
        stop.assert_called_once_with(process)

    def test_posix_timeout_cleanup_signals_the_entire_process_group(self):
        process = SimpleNamespace(pid=321)
        with patch.object(process, 'communicate', create=True, side_effect=[subprocess.TimeoutExpired('synthetic', 5), (b'', None)]) as wait, \
                patch.object(swiftpm.os, 'name', 'posix'), patch.object(swiftpm.os, 'killpg', create=True) as kill, \
                patch.object(swiftpm.signal, 'SIGKILL', 9, create=True):
            swiftpm.stop_process(process)
            self.assertEqual(kill.call_args_list[0].args, (321, swiftpm.signal.SIGTERM))
            self.assertEqual(kill.call_args_list[1].args, (321, 9))
            self.assertEqual(wait.call_count, 2)

    def test_clock_identity_is_bound_to_build_and_cannot_be_reset(self):
        env = {"CI": "true", "CM_BUILD_ID": "synthetic-build", "CM_COMMIT": "a" * 40}
        with patch.object(swiftpm.time, "monotonic", return_value=100), contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(swiftpm.main(["start"], root=self.root, env=env), 0)
            self.assertEqual(swiftpm.main(["start"], root=self.root, env=env), 1)
            with patch.object(swiftpm, "resolve", return_value=0) as resolve:
                self.assertEqual(swiftpm.main(["resolve"], root=self.root, env=env), 0)
                resolve.assert_called_once_with(self.root, 100)
            self.assertEqual(swiftpm.main(["resolve"], root=self.root, env={**env, "CM_BUILD_ID": SENTINEL}), 1)
        self.assertNotIn(SENTINEL, output.getvalue())
        self.assertEqual(set(json.loads((self.root / swiftpm.CLOCK_FILE).read_text())), {'build_id', 'commit', 'started'})

    def test_unexpected_runner_errors_and_invalid_cli_do_not_leak_or_publish(self):
        env = {"CI": "true", "CM_BUILD_ID": "synthetic", "CM_COMMIT": "a" * 40}
        with contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(swiftpm.main([SENTINEL], root=self.root, env=env), 1)
            self.assertEqual(swiftpm.main(["start"], root=self.root, env=env), 0)
            with patch.object(swiftpm, "resolve", side_effect=RuntimeError(SENTINEL)):
                self.assertEqual(swiftpm.main(["resolve"], root=self.root, env=env), 1)
        self.assertNotIn(SENTINEL, output.getvalue())

    def test_stdout_stderr_do_not_expose_captured_url_or_environment(self):
        secret_log = TIMEOUT.replace('example.invalid', SENTINEL + '@example.invalid')
        with contextlib.redirect_stdout(io.StringIO()) as stdout, \
                contextlib.redirect_stderr(io.StringIO()) as stderr, \
                patch.dict(swiftpm.os.environ, {'SECRET_SYNTHETIC_VALUE': SENTINEL}):
            self.assertEqual(swiftpm.resolve(
                self.root, 0, runner=lambda *_: swiftpm.Attempt(74, secret_log),
                clock=self.clock, sleep=self.clock.sleep,
                baseline_loader=lambda _: self.baseline), 74)
        self.assertEqual(stderr.getvalue(), '')
        self.assertNotIn(SENTINEL, stdout.getvalue())
        self.assertNotIn('example.invalid', stdout.getvalue())
        self.assertIn('SwiftPM resolution attempt 3/3', stdout.getvalue())

    def test_url_signature_and_403_are_not_semantic_permanent_errors(self):
        for url in ('https://example.invalid/signature-sdk.zip', 'https://example.invalid/403/sdk.zip',
                    'https://signature.invalid/sdk.zip?signature=403&token=' + SENTINEL):
            output = TIMEOUT.replace('https://example.invalid/sdk.zip', url)
            for progress in ('', 'Fetching ' + url + '\n'):
                with self.subTest(url=url, progress=bool(progress)):
                    self.calls.clear()
                    self.clock.delays.clear()
                    self.assertEqual(self.run_resolve([swiftpm.Attempt(74, progress + output), swiftpm.Attempt(0, '')]), 0)
                    self.assertEqual(len(self.calls), 2)
                    self.assertEqual(self.clock.delays, [15])

    def test_real_http_403_and_signature_failures_block_in_any_position(self):
        failures = ('downloadError("HTTP 403")', 'error: invalid SDK signature', 'error: checksum mismatch',
                    'error: Invalid manifest', 'error: incompatible package version')
        for failure in failures:
            for text in (failure + '\n' + TIMEOUT, TIMEOUT + '\n' + failure):
                with self.subTest(failure=failure):
                    self.calls.clear()
                    result = swiftpm.Attempt(74, text)
                    self.assertEqual(swiftpm.classify_failure(result), swiftpm.Classification(False, 'MIXED_ERROR'))
                    self.assertEqual(self.run_resolve([result]), 74)
                    self.assertEqual(len(self.calls), 1)
        self.assertEqual(self.clock.delays, [])

    def test_only_known_xcode_footer_is_allowed_after_summary(self):
        for footer in ('Writing error result bundle to /synthetic/tmp/ResultBundle.xcresult',
                       'Writing error result bundle to "/synthetic/path with spaces/ResultBundle.xcresult"',
                       'Writing error result bundle to /synthetic/signature/403/ResultBundle.xcresult'):
            self.calls.clear()
            self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT + '\n' + footer), swiftpm.Attempt(0, '')]), 0)
            self.assertEqual(len(self.calls), 2)
        for footer in ('Writing error result bundle to /synthetic/result.txt', 'arbitrary unknown footer',
                       'Writing error result bundle to /synthetic/result.xcresult; unknown failure'):
            decision = swiftpm.classify_failure(swiftpm.Attempt(74, TIMEOUT + '\n' + footer))
            self.assertEqual(decision, swiftpm.Classification(False, 'MIXED_ERROR'))
        # Footer paths cannot supply positive network evidence either.
        no_timeout = SUMMARY + "failed downloading 'https://example.invalid/sdk.zip'\n"
        footer = 'Writing error result bundle to "/synthetic/The request timed out.xcresult"'
        self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, no_timeout + footer)))

    def test_alternative_network_messages_require_download_context(self):
        timeouts = ('The request timed out', 'Timeout was reached', 'Operation timed out',
                    'NSURLErrorDomain error -1001')
        network = ('Connection reset by peer', 'Connection interrupted', 'Could not resolve host',
                   'Temporary failure in name resolution', 'A server with the specified hostname could not be found.',
                   'The Internet connection appears to be offline.', 'NSURLErrorDomain error -1003',
                   'HTTP 429', 'HTTP 502', 'HTTP 503', 'HTTP 504')
        for message in timeouts + network:
            output = SUMMARY + 'downloadError("' + message + '")'
            reason = 'TRANSIENT_DOWNLOAD_TIMEOUT' if message in timeouts else 'TRANSIENT_NETWORK_ERROR'
            with self.subTest(message=message):
                self.assertEqual(swiftpm.classify_failure(swiftpm.Attempt(74, output)), swiftpm.Classification(True, reason))
                self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, SUMMARY + 'error: ' + message)))
        for message in ('unknown status 503', 'HTTP 500', 'An unknown network error occurred'):
            self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, SUMMARY + 'downloadError("' + message + '")')))

    def test_structured_messages_report_actual_retry_decisions_and_exit(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(74, TIMEOUT)] * 3), 74)
        fields = [message for message in self.messages if message.startswith('SWIFTPM_FAILURE ')]
        self.assertEqual(fields, [
            'SWIFTPM_FAILURE attempt=1/3 child_exit=74 retry=yes reason=TRANSIENT_DOWNLOAD_TIMEOUT',
            'SWIFTPM_FAILURE attempt=2/3 child_exit=74 retry=yes reason=TRANSIENT_DOWNLOAD_TIMEOUT',
            'SWIFTPM_FAILURE attempt=3/3 child_exit=74 retry=no reason=TRANSIENT_DOWNLOAD_TIMEOUT',
        ])

    def test_unknown_and_permanent_failures_have_distinct_reasons(self):
        for output, reason in ((SENTINEL, 'UNCLASSIFIED_OUTPUT'),
                               ('error: invalid manifest', 'PERMANENT_RESOLUTION_ERROR')):
            self.assertEqual(swiftpm.classify_failure(swiftpm.Attempt(74, output)), swiftpm.Classification(False, reason))
        self.assertEqual(swiftpm.classify_failure(swiftpm.Attempt(91, TIMEOUT)), swiftpm.Classification(False, 'UNSUPPORTED_EXIT_CODE'))

    def test_output_limit_cannot_enable_retry_based_only_on_tail(self):
        result = swiftpm.Attempt(74, ('x' * (swiftpm.OUTPUT_LIMIT + 1)) + '\n' + TIMEOUT + SENTINEL)
        self.assertEqual(swiftpm.classify_failure(result), swiftpm.Classification(False, 'OUTPUT_LIMIT_EXCEEDED'))
        self.assertEqual(self.run_resolve([result]), 74)
        self.assertEqual(len(self.calls), 1)
        self.assertLess(len('\n'.join(self.messages).encode()), 10000)
        self.assertIn('reason=OUTPUT_LIMIT_EXCEEDED', '\n'.join(self.messages))

    def test_safe_tail_projects_constants_and_never_echoes_sensitive_substrings(self):
        jwt = 'eyJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJTWU5USEVUSUMifQ.SYNTHETIC_SIGNATURE'
        payload = '\n'.join((
            '\x1b[31mAuthorization: Bearer ' + jwt + '\x1b[0m',
            'https://SYNTHETIC_USER:SYNTHETIC_PASSWORD@example.invalid/sdk.zip?token=' + SENTINEL,
            '-----BEGIN ' + 'PRIVATE KEY-----', SENTINEL, '-----END ' + 'PRIVATE KEY-----',
            'APP_STORE_CONNECT_PRIVATE_KEY=' + SENTINEL,
            '/Users/' + SENTINEL + '/AuthKey.p8', 'C:\\Users\\' + SENTINEL + '\\private.p8',
            '\x1b]8;;https://example.invalid/?token=' + SENTINEL + '\x07click\x1b]8;;\x07',
            TIMEOUT, 'Writing error result bundle to /Users/' + SENTINEL + '/result.xcresult',
        ))
        with contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr:
            swiftpm.diagnose_failure(1, swiftpm.Attempt(74, payload), False, 'MIXED_ERROR', swiftpm.log)
        output = stdout.getvalue() + stderr.getvalue()
        for sensitive in (SENTINEL, jwt, 'SYNTHETIC_USER', 'SYNTHETIC_PASSWORD', 'example.invalid',
                          'https://', 'Authorization', 'PRIVATE KEY', '/Users/', 'C:\\Users', '\x1b'):
            self.assertNotIn(sensitive, output)
        self.assertIn('[DOWNLOAD_TIMEOUT_TEXT_REDACTED]', output)
        self.assertIn('[PATH_REDACTED]', output)
        self.assertEqual(stderr.getvalue(), '')

    def test_tail_limits_and_unknown_format_suppression(self):
        tail = swiftpm.safe_diagnostic_tail((SENTINEL + '\n') * 1000)
        self.assertLessEqual(len(tail.splitlines()), 20)
        self.assertLessEqual(len(tail.encode('utf-8')), 8192)
        self.assertNotIn(SENTINEL, tail)
        self.assertEqual(set(tail.splitlines()), {'[UNCLASSIFIED_LINE_REDACTED]'})
        self.assertEqual(swiftpm.safe_diagnostic_tail(''), '')

    def test_projection_is_never_the_classifiers_input(self):
        with patch.object(swiftpm, 'safe_diagnostic_tail', return_value='error: invalid manifest') as tail:
            self.assertTrue(swiftpm.classify_failure(swiftpm.Attempt(74, TIMEOUT)).retryable)
        tail.assert_not_called()

    def test_display_types_are_fixed_and_do_not_grant_retry_permission(self):
        for message, label in (('invalid manifest', 'MANIFEST_ERROR'), ('checksum mismatch', 'CHECKSUM_ERROR'),
                               ('invalid signature', 'SIGNATURE_ERROR'), ('HTTP 403', 'ACCESS_ERROR'),
                               ('incompatible version', 'VERSION_ERROR'), ('project does not exist', 'CONFIGURATION_ERROR')):
            output = 'error: ' + message + ' ' + SENTINEL
            self.assertEqual(swiftpm.safe_diagnostic_tail(output), '[' + label + '_TEXT_REDACTED]')
            self.assertFalse(swiftpm.transient_download_failure(swiftpm.Attempt(74, output)))

    def test_spawn_and_internal_errors_are_fixed_fail_closed_and_do_not_retry(self):
        for error, reason in ((FileNotFoundError(SENTINEL), 'SPAWN_FAILED'), (RuntimeError(SENTINEL), 'INTERNAL_ERROR')):
            messages = []
            with patch.object(swiftpm.subprocess, 'Popen', side_effect=error) as popen:
                status = swiftpm.resolve(self.root, 0, runner=swiftpm.run_xcodebuild, clock=self.clock,
                                         sleep=self.clock.sleep, emit=messages.append, baseline_loader=lambda _: self.baseline)
            self.assertEqual(status, 1)
            popen.assert_called_once()
            self.assertIn('SWIFTPM_FAILURE attempt=1/3 child_exit=NONE retry=no reason=' + reason, messages)
            self.assertNotIn(SENTINEL, '\n'.join(messages))
            self.assertEqual(self.clock.delays, [])

    def test_guard_timeout_budget_and_interrupt_have_structured_reasons(self):
        self.assertEqual(self.run_resolve([swiftpm.Attempt(124, TIMEOUT, True)]), 124)
        self.assertIn('reason=PROCESS_TIMEOUT', '\n'.join(self.messages))
        self.messages.clear()
        self.clock.now = 3600
        self.assertEqual(self.run_resolve([]), 75)
        self.assertIn('SWIFTPM_FAILURE attempt=0/3 child_exit=NONE retry=no reason=TIME_BUDGET_EXHAUSTED', self.messages)
        self.messages.clear()
        self.clock.now = 0
        (self.root / swiftpm.LOCKS[0]).unlink()
        self.assertEqual(self.run_resolve([]), 1)
        self.assertIn('reason=LOCK_GUARD_FAILED', '\n'.join(self.messages))
        for path, value in self.baseline.items():
            (self.root / path).write_bytes(value)
        with patch.object(swiftpm, 'run_xcodebuild', side_effect=KeyboardInterrupt) as runner:
            status = swiftpm.resolve(self.root, 0, runner=runner, clock=self.clock, emit=self.messages.append,
                                     baseline_loader=lambda _: self.baseline)
        self.assertEqual(status, 130)
        self.assertIn('reason=INTERRUPTED', '\n'.join(self.messages))

    def test_unknown_diagnostic_reason_cannot_inject_text(self):
        messages = []
        swiftpm.diagnose_failure(SENTINEL, None, True, SENTINEL, messages.append)
        self.assertEqual(messages, ['SWIFTPM_FAILURE attempt=0/3 child_exit=NONE retry=no reason=INTERNAL_ERROR'])

    def test_merged_child_stream_to_resolve_never_writes_or_leaks_raw_output(self):
        payload = TIMEOUT + '\nAuthorization: Bearer ' + SENTINEL + '\nhttps://user:password@example.invalid/?token=' + SENTINEL
        process = SimpleNamespace(returncode=74, communicate=lambda **_: (payload.encode(), None))
        before = {path: path.read_bytes() for path in self.root.rglob('*') if path.is_file()}
        with patch.object(swiftpm.subprocess, 'Popen', return_value=process) as popen, \
                patch.object(Path, 'write_text', side_effect=AssertionError('No log/credential writes')) as text_write, \
                patch.object(Path, 'write_bytes', side_effect=AssertionError('No log/credential writes')) as byte_write, \
                contextlib.redirect_stdout(io.StringIO()) as stdout, contextlib.redirect_stderr(io.StringIO()) as stderr:
            status = swiftpm.resolve(self.root, 0, runner=swiftpm.run_xcodebuild, clock=self.clock,
                                     sleep=self.clock.sleep, baseline_loader=lambda _: self.baseline)
        self.assertEqual(status, 74)
        popen.assert_called_once()
        self.assertEqual(popen.call_args.kwargs['stderr'], subprocess.STDOUT)
        text_write.assert_not_called()
        byte_write.assert_not_called()
        self.assertEqual({path: path.read_bytes() for path in self.root.rglob('*') if path.is_file()}, before)
        for secret in (SENTINEL, 'https://', 'example.invalid', 'password', 'Authorization'):
            self.assertNotIn(secret, stdout.getvalue() + stderr.getvalue())
        self.assertIn('child_exit=74 retry=no reason=MIXED_ERROR', stdout.getvalue())

    def test_original_time_limits_and_backoff_constants_are_unchanged(self):
        self.assertEqual(swiftpm.ATTEMPT_SECONDS, 600)
        self.assertEqual(swiftpm.CLEANUP_SECONDS, 10)
        self.assertEqual(swiftpm.TOTAL_SECONDS, 1920)
        self.assertEqual(swiftpm.DEPENDENCY_PHASE_SECONDS, 3600)
        self.assertEqual(swiftpm.BACKOFFS, (15, 45))


if __name__ == "__main__":
    unittest.main()
