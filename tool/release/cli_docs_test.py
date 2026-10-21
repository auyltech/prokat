"""Offline owner CLI/documentation contract checks; never launches a release."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class CliDocumentationTests(unittest.TestCase):
    def test_apple_diagnostics_documented_without_credential_or_release_overrides(self):
        guide = (ROOT / 'docs/ci-cd/IOS_CI_DIAGNOSTICS.md').read_text(encoding='utf-8')
        import ios_store
        for code in ios_store.FAILURE_CODES:
            self.assertIn(code, guide)
        for code, stage in ios_store.SUCCESS_EVENTS:
            self.assertIn(code, guide)
        for command in ('auth --channel rc', 'auth --channel production', 'check --build 20'):
            self.assertIn(command, guide)
        for path in ('CICD-README.md', 'tool/release/README.md', 'docs/ci-cd/RELEASE_RUNBOOK.md',
                     'docs/ci-cd/MANUAL_SETUP.md', 'docs/ci-cd/OWNER_CHECKLIST.md', 'docs/ci-cd/VERIFICATION.md'):
            self.assertIn('IOS_CI_DIAGNOSTICS', (ROOT / path).read_text(encoding='utf-8'))

    def test_isolated_python_pem_contract_is_documented(self):
        for path in ('CICD-README.md', 'tool/release/README.md', 'docs/ci-cd/IOS_CI_DIAGNOSTICS.md',
                     'docs/ci-cd/MANUAL_SETUP.md', 'docs/ci-cd/OWNER_CHECKLIST.md'):
            text = (ROOT / path).read_text(encoding='utf-8')
            self.assertIn('PROKAT_ASC_PRIVATE_KEY_PEM', text)
        guide = (ROOT / 'docs/ci-cd/IOS_CI_DIAGNOSTICS.md').read_text(encoding='utf-8')
        self.assertIn('no fallback', guide)

    def test_owner_commands_and_flags_exist(self):
        readme = (ROOT / 'CICD-README.md').read_text(encoding='utf-8')
        script = (ROOT / 'tool/release/prokat-release.ps1').read_text(encoding='utf-8')
        for channel in ('rc', 'prod'):
            for platform in ('android', 'ios'):
                name = f'prokat-{channel}-{platform}'
                self.assertIn(name, readme)
                self.assertIn(f'function {name} {{ [CmdletBinding()] param([switch]$DryRun)', script)
        self.assertIn("$cliArgs += '--dry-run'", script)
        self.assertIn('1.2.3+22', readme)
        self.assertIn('1.2.4+23', readme)

    def test_current_guides_have_no_manual_tag_creation(self):
        for path in ('CICD-README.md', 'docs/ci-cd/RELEASE_RUNBOOK.md',
                     'docs/ci-cd/MANUAL_SETUP.md', 'releases/README.md',
                     'tool/release/README.md'):
            text = (ROOT / path).read_text(encoding='utf-8')
            self.assertNotRegex(text, r'git\s+tag\s+-a')
            self.assertNotRegex(text, r'git\s+push\s+--(?:tags|force)')

    def test_current_documentation_local_links_resolve(self):
        for path in [ROOT / 'CICD-README.md', ROOT / 'releases/README.md',
                     ROOT / 'tool/release/README.md',
                     *sorted((ROOT / 'docs/ci-cd').glob('*.md'))]:
            text = path.read_text(encoding='utf-8')
            for target in re.findall(r'\]\(([^)\s]+)\)', text):
                if '://' in target or target.startswith('#'):
                    continue
                local = target.split('#', 1)[0]
                self.assertTrue((path.parent / local).exists(), f'{path.name}: {target}')

    def test_historical_evidence_has_current_workflow_pointer(self):
        for name in ('PLAN.md', 'VERIFICATION.md', 'RC_1.2.3_PREPARATION.md'):
            text = (ROOT / 'docs/ci-cd' / name).read_text(encoding='utf-8')
            self.assertIn('CICD-README.md', text[:1200])


if __name__ == '__main__':
    unittest.main()
