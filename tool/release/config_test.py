"""Contract checks of the actual workflow files; does not trigger CI."""
import fnmatch
from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]


class WorkflowContractTests(unittest.TestCase):
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


if __name__ == "__main__":
    unittest.main()
