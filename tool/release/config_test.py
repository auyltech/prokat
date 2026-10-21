"""Contract checks of the actual workflow files; does not trigger CI."""
import fnmatch
import os
import re
from pathlib import Path
import shutil
import subprocess
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]


class WorkflowContractTests(unittest.TestCase):
    def test_release_signing_and_fail_fast_order(self):
        gradle = (ROOT / 'android/app/build.gradle.kts').read_text()
        self.assertNotIn('androiddebugkey', gradle)
        self.assertNotIn('debug.keystore', gradle)
        self.assertIn('PROKAT_RELEASE_CI', gradle)
        self.assertIn('signingConfig = signingConfigs.getByName("release")', gradle)
        steps = self.github['jobs']['release']['steps']
        scripts = '\n'.join(step.get('run', '') for step in steps)
        self.assertLess(scripts.index('play.rb preflight'), scripts.index('flutter build appbundle'))
        self.assertLess(scripts.index('verify_android.dart'), scripts.index('play.rb publish'))
        self.assertEqual(steps[-1]['if'], 'always()')
        self.assertIn('rm -f -- .env android/key.properties', steps[-1]['run'])
        for workflow in self.releases.values():
            scripts = [step['script'] for step in workflow['scripts']]
            ordered = ['release.dart ci', 'apple_diagnostic.py auth', 'ios_store.py validate-publish',
                       'flutter pub get', 'swiftpm_resolve.py resolve',
                       'flutter analyze', 'ios_store.py preflight', 'flutter build ipa',
                       'verify_ios.py', 'upload-symbols -gsp', 'ios_store.py publish']
            joined = '\n'.join(scripts)
            positions = [joined.index(command) for command in ordered]
            self.assertEqual(positions, sorted(positions))

    def test_exact_android_u2_input_inventory_and_prebuild_key_check(self):
        text = (ROOT / '.github/workflows/android-release.yml').read_text()
        secrets = set(re.findall(r'secrets\.([A-Z0-9_]+)', text))
        variables = set(re.findall(r'vars\.([A-Z0-9_]+)', text))
        self.assertEqual(secrets, {
            'ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD', 'ANDROID_KEY_ALIAS',
            'ANDROID_KEY_PASSWORD', 'PLAY_SERVICE_ACCOUNT_JSON_BASE64',
            'GOOGLE_SERVICES_JSON_BASE64', 'MAPBOX_PUBLIC_TOKEN', 'PRODUCTION_PUBLISHING_ENABLED',
        })
        self.assertEqual(variables, {'PLAY_HISTORICAL_MAX_BUILD', 'ANDROID_UPLOAD_CERT_SHA256'})
        self.assertLess(text.index('verify_upload_key.py'), text.index('flutter build appbundle'))

    def setUp(self):
        self.github = yaml.load((ROOT / ".github/workflows/android-release.yml").read_text(), Loader=yaml.BaseLoader)
        self.codemagic = yaml.load((ROOT / "codemagic.yaml").read_text(), Loader=yaml.BaseLoader)
        self.assertEqual(set(self.codemagic['workflows']), {'ios-rc', 'ios-production', 'ios-apple-diagnostic'})
        self.releases = {name: self.codemagic['workflows'][name] for name in ('ios-rc', 'ios-production')}

    def test_release_events_are_only_platform_tag_events(self):
        self.assertEqual(list(self.github["on"]), ["push"])
        self.assertEqual(list(self.github["on"]["push"]), ["tags"])
        for workflow in self.releases.values():
            self.assertEqual(workflow["triggering"]["events"], ["tag"])
            self.assertNotIn("branch_patterns", workflow["triggering"])

    def test_tag_trigger_isolation(self):
        patterns = {"android": self.github["on"]["push"]["tags"]}
        for name, workflow in self.releases.items():
            patterns[name] = [p["pattern"] for p in workflow["triggering"]["tag_patterns"] if p["include"] == "true"]
        for tag, expected in {
            "android/v1.8.0+108": ["android"], "rc/android/v1.8.0+107": ["android"],
            "ios/v1.8.0+108": ["ios-production"], "rc/ios/v1.8.0+107": ["ios-rc"],
            "main": [], "dev": [], "v1.8.0+108": [], "other/ios/v1.8.0+108": [],
        }.items():
            with self.subTest(tag=tag):
                actual = [provider for provider, globs in patterns.items() if any(fnmatch.fnmatchcase(tag, glob) for glob in globs)]
                self.assertEqual(actual, expected)

    def test_both_providers_supply_history_and_invoke_shared_source_guard(self):
        steps = self.github['jobs']['release']['steps']
        self.assertEqual(steps[0]['with']['fetch-depth'], '0')
        android = '\n'.join(step.get('run', '') for step in steps)
        self.assertLess(android.index('release.dart ci'), android.index('inputs.dart android'))
        for workflow in self.releases.values():
            source = workflow['scripts'][0]['script']
            self.assertIn('--is-shallow-repository', source)
            self.assertIn('fetch --unshallow origin', source)
            self.assertIn('main:refs/remotes/origin/main', source)
            self.assertIn('release.dart ci', source)

    def test_cost_artifact_and_production_contract(self):
        self.assertEqual(self.github["permissions"], {"contents": "read"})
        self.assertEqual(self.github["jobs"]["release"]["runs-on"], "ubuntu-24.04")
        text = (ROOT / ".github/workflows/android-release.yml").read_text()
        self.assertNotIn("upload-artifact", text)
        self.assertIn("secrets.PRODUCTION_PUBLISHING_ENABLED", text)
        for name, workflow in self.releases.items():
            self.assertEqual(workflow["instance_type"], "mac_mini_m2")
            self.assertEqual(workflow["max_build_duration"], '90')
            self.assertEqual(workflow["artifacts"], ["build/release/ios-symbols.zip", "build/ios/ipa/*.ipa"])
            self.assertEqual(workflow["environment"]["vars"]["RELEASE_EXPECTED_CHANNEL"], "rc" if name == "ios-rc" else "production")
            self.assertIn("release.dart ci", workflow["scripts"][0]["script"])
            self.assertIn("check_toolchain.dart ios", workflow["scripts"][0]["script"])
            auth = workflow['scripts'][1]['script']
            self.assertIn('requirements-apple.txt', auth)
            self.assertIn('apple_diagnostic.py auth --channel "$RELEASE_EXPECTED_CHANNEL"', auth)
            self.assertNotIn(' check ', auth)
            self.assertIn('set +x', auth)
            dependencies = workflow['scripts'][2]['script']
            self.assertLess(dependencies.index('requirements.txt'), dependencies.index('ios_store.py validate-publish'))
            self.assertLess(dependencies.index('ios_store.py validate-publish'), dependencies.index('flutter pub get'))
            self.assertIn('python3 -B tool/release/swiftpm_resolve.py start', workflow['scripts'][0]['script'])
            self.assertEqual(dependencies.count('swiftpm_resolve.py resolve'), 1)
            self.assertNotIn('xcodebuild -resolvePackageDependencies', dependencies)
            self.assertIn('pod install --deployment', dependencies)
            self.assertIn('SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols', workflow['scripts'][6]['script'])
            self.assertIn('test -n "${CM_TAG:-}"', workflow['scripts'][0]['script'])
            self.assertIn('--revision "$CM_COMMIT"', workflow['scripts'][0]['script'])
        self.assertEqual(self.releases['ios-rc']['scripts'][2], self.releases['ios-production']['scripts'][2])

    def test_diagnostic_is_manual_main_only_without_release_capabilities(self):
        workflow = self.codemagic['workflows']['ios-apple-diagnostic']
        self.assertEqual(set(workflow), {'name', 'instance_type', 'max_build_duration', 'integrations', 'environment', 'scripts'})
        self.assertEqual(workflow['name'], 'iOS Apple GET-only diagnostic')
        self.assertEqual(workflow['instance_type'], 'mac_mini_m2')
        self.assertEqual(workflow['max_build_duration'], '5')
        self.assertEqual(workflow['integrations'], {'app_store_connect': 'prokat-app-store'})
        self.assertEqual(workflow['environment'], {'groups': ['prokat-ios-release']})
        self.assertEqual(len(workflow['scripts']), 3)
        source, dependencies, check = [step['script'] for step in workflow['scripts']]
        for condition in ('"${CM_BRANCH:-}" != main', '"${CM_REPO_SLUG:-}" != auyltech/prokat',
                          '"${CM_PULL_REQUEST:-}" != false', '"${CM_TRIGGER_SOURCE:-}" != api',
                          '[ -n "${CM_TAG:-}" ]', 'git rev-parse HEAD', '"$actual_commit" = "${CM_COMMIT:-}"'):
            self.assertIn(condition, source)
        self.assertIn('requirements-apple.txt', dependencies)
        self.assertIn('--isolated install', dependencies)
        self.assertIn('--only-binary=:all:', dependencies)
        self.assertIn('python3 -B tool/release/apple_diagnostic.py check --build 20', check)
        scripts = '\n'.join((source, dependencies, check))
        for forbidden in ('requirements.txt', 'ios_store.py', 'apple_publish', 'flutter', 'pod install',
                          'xcode', 'upload-symbols', 'printenv', 'export CM_', 'set -x'):
            self.assertNotIn(forbidden, scripts)
        for script in (source, dependencies, check):
            self.assertTrue(script.startswith('set +x\nset -euo pipefail\n'))

    def test_swiftpm_retry_is_shared_and_never_wraps_publishing_or_diagnostic(self):
        for workflow in self.releases.values():
            scripts = [step['script'] for step in workflow['scripts']]
            self.assertEqual(sum(script.count('swiftpm_resolve.py resolve') for script in scripts), 1)
            self.assertEqual(sum(script.count('swiftpm_resolve.py start') for script in scripts), 1)
            self.assertEqual(sum(script.count('ios_store.py publish') for script in scripts), 1)
            self.assertIn('git diff --exit-code -- pubspec.lock ios/Podfile.lock', scripts[2])
            self.assertIn('pod install --deployment', scripts[2])
            self.assertNotIn('cache', workflow)
            for script in scripts[3:]:
                self.assertNotIn('swiftpm_resolve.py', script)
            for forbidden in ('swift package update', 'rm -rf', '-skipPackage', '-disablePackage'):
                self.assertNotIn(forbidden, '\n'.join(scripts))
        diagnostic = self.codemagic['workflows']['ios-apple-diagnostic']
        self.assertNotIn('swiftpm_resolve.py', '\n'.join(step['script'] for step in diagnostic['scripts']))

    def test_ipa_recovery_artifact_has_no_cleanup_or_additional_storage(self):
        from apple_publish import CLI_VERSION
        self.assertIn('codemagic-cli-tools==' + CLI_VERSION, (ROOT / 'tool/release/requirements.txt').read_text())
        for workflow in self.releases.values():
            scripts = '\n'.join(step['script'] for step in workflow['scripts'])
            self.assertIn('build/ios/ipa/*.ipa', workflow['artifacts'])
            self.assertEqual(scripts.count('ios_store.py validate-publish'), 1)
            self.assertEqual(scripts.count('ios_store.py publish'), 1)
            for forbidden in ('rm -f -- build/ios/ipa', 'rm -rf build/ios', 'aws s3', 'gsutil', 'post_publish'):
                self.assertNotIn(forbidden, scripts)
            self.assertNotIn('publishing', workflow)
        self.assertNotIn('upload-artifact', (ROOT / '.github/workflows/android-release.yml').read_text())

    def test_manual_source_guard_executes_before_dependencies(self):
        git_bash = Path('C:/Program Files/Git/bin/bash.exe')
        bash = str(git_bash) if os.name == 'nt' and git_bash.is_file() else shutil.which('bash')
        if not bash:
            self.skipTest('Bash unavailable; static guard contract still checked')
        source = self.codemagic['workflows']['ios-apple-diagnostic']['scripts'][0]['script']
        sha = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=ROOT, check=True,
                             capture_output=True, text=True).stdout.strip()
        env = {**os.environ, 'CM_BRANCH': 'main', 'CM_REPO_SLUG': 'auyltech/prokat',
               'CM_PULL_REQUEST': 'false', 'CM_TRIGGER_SOURCE': 'api', 'CM_TAG': '', 'CM_COMMIT': sha}
        cases = [({}, 0), ({'CM_BRANCH': 'dev'}, 1), ({'CM_REPO_SLUG': 'other/prokat'}, 1),
                 ({'CM_PULL_REQUEST': 'true'}, 1), ({'CM_TRIGGER_SOURCE': 'webhook'}, 1),
                 ({'CM_TAG': 'rc/ios/v1.2.3+20'}, 1), ({'CM_COMMIT': '0' * 40}, 1),
                 ({'CM_COMMIT': ''}, 1)]
        for overrides, expected in cases:
            with self.subTest(fields=list(overrides)):
                result = subprocess.run([bash, '-c', source], cwd=ROOT, env={**env, **overrides},
                                        capture_output=True, text=True, timeout=15)
                self.assertEqual(result.returncode, expected)
                self.assertEqual(result.stderr, '')
                self.assertEqual(result.stdout, '' if expected == 0 else 'BLOCKED: APPLE_SOURCE_CONTEXT_INVALID\n')


if __name__ == "__main__":
    unittest.main()
