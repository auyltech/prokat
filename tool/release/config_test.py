"""Contract checks of the actual workflow files; does not trigger CI."""
import fnmatch
import re
from pathlib import Path
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
        for workflow in self.codemagic['workflows'].values():
            scripts = [step['script'] for step in workflow['scripts']]
            self.assertIn('ios_store.py preflight', scripts[3])
            self.assertIn('verify_ios.py', scripts[4])
            self.assertIn('upload-symbols', scripts[5])
            self.assertIn('ios_store.py publish', scripts[6])

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

    def test_release_events_are_only_platform_tag_events(self):
        self.assertEqual(list(self.github["on"]), ["push"])
        self.assertEqual(list(self.github["on"]["push"]), ["tags"])
        for workflow in self.codemagic["workflows"].values():
            self.assertEqual(workflow["triggering"]["events"], ["tag"])
            self.assertNotIn("branch_patterns", workflow["triggering"])

    def test_tag_trigger_isolation(self):
        patterns = {"android": self.github["on"]["push"]["tags"]}
        for name, workflow in self.codemagic["workflows"].items():
            patterns[name] = [p["pattern"] for p in workflow["triggering"]["tag_patterns"] if p["include"] == "true"]
        for tag, expected in {
            "android/v1.8.0+108": ["android"], "rc/android/v1.8.0+107": ["android"],
            "ios/v1.8.0+108": ["ios-production"], "rc/ios/v1.8.0+107": ["ios-rc"],
            "main": [], "dev": [], "v1.8.0+108": [], "other/ios/v1.8.0+108": [],
        }.items():
            with self.subTest(tag=tag):
                actual = [provider for provider, globs in patterns.items() if any(fnmatch.fnmatchcase(tag, glob) for glob in globs)]
                self.assertEqual(actual, expected)

    def test_cost_artifact_and_production_contract(self):
        self.assertEqual(self.github["permissions"], {"contents": "read"})
        self.assertEqual(self.github["jobs"]["release"]["runs-on"], "ubuntu-24.04")
        text = (ROOT / ".github/workflows/android-release.yml").read_text()
        self.assertNotIn("upload-artifact", text)
        self.assertIn("secrets.PRODUCTION_PUBLISHING_ENABLED", text)
        for name, workflow in self.codemagic["workflows"].items():
            self.assertEqual(workflow["instance_type"], "mac_mini_m2")
            self.assertEqual(workflow["artifacts"], ["build/release/ios-symbols.zip"])
            self.assertEqual(workflow["environment"]["vars"]["RELEASE_EXPECTED_CHANNEL"], "rc" if name == "ios-rc" else "production")
            self.assertIn("release.dart ci", workflow["scripts"][0]["script"])
            self.assertIn("check_toolchain.dart ios", workflow["scripts"][0]["script"])
            dependencies = workflow['scripts'][1]['script']
            self.assertIn('-onlyUsePackageVersionsFromResolvedFile', dependencies)
            self.assertIn('pod install --deployment', dependencies)
            self.assertIn('SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols', workflow['scripts'][5]['script'])


if __name__ == "__main__":
    unittest.main()
