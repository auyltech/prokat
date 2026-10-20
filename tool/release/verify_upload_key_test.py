import hashlib
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
import unittest
import os

from verify_upload_key import VerificationError, certificate_der, inspect_upload_key


@unittest.skipUnless(shutil.which("keytool"), "JDK keytool is needed for throwaway certificate fixtures")
class UploadCertificateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="prokat-disposable-key-test-")
        cls.root = Path(cls.temp.name)
        cls.password = secrets.token_urlsafe(24)
        cls.keytool = shutil.which("keytool")
        cls.key = cls.root / "disposable.jks"
        env = {**os.environ, "PROKAT_FIXTURE_PASSWORD": cls.password}
        # This private identity is solely a temporary local test fixture.
        for alias in ("fixture", "other"):
            result = subprocess.run([cls.keytool, "-genkeypair", "-keystore", str(cls.key), "-storetype", "JKS",
                                     "-alias", alias, "-keyalg", "RSA", "-keysize", "2048", "-validity", "1",
                                     "-dname", "CN=Disposable PROKAT unit test", "-storepass:env", "PROKAT_FIXTURE_PASSWORD",
                                     "-keypass:env", "PROKAT_FIXTURE_PASSWORD", "-noprompt"], env=env, capture_output=True)
            if result.returncode:
                raise RuntimeError("Fixture keytool generation failed (output suppressed)")
            for suffix, flags in (("der", []), ("pem", ["-rfc"])):
                result = subprocess.run([cls.keytool, "-exportcert", "-keystore", str(cls.key), "-alias", alias,
                                         "-storepass:env", "PROKAT_FIXTURE_PASSWORD", "-file", str(cls.root / f"{alias}.{suffix}"), *flags], env=env, capture_output=True)
                if result.returncode:
                    raise RuntimeError("Fixture public certificate export failed")

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_matching_der_and_pem_without_changing_keystore(self):
        before = hashlib.sha256(self.key.read_bytes()).digest()
        for suffix in ("der", "pem"):
            fingerprint = inspect_upload_key(self.key, "fixture", self.root / f"fixture.{suffix}", self.password, self.keytool)
            self.assertEqual(len(fingerprint.replace(":", "")), 64)
        self.assertEqual(before, hashlib.sha256(self.key.read_bytes()).digest())

    def test_wrong_certificate_blocks(self):
        with self.assertRaisesRegex(VerificationError, "MISMATCH"):
            inspect_upload_key(self.key, "fixture", self.root / "other.der", self.password, self.keytool)

    def test_ci_fingerprint_matches_or_blocks(self):
        digest = hashlib.sha256((self.root / "fixture.der").read_bytes()).hexdigest()
        inspect_upload_key(self.key, "fixture", None, self.password, self.keytool, expected_sha256=digest)
        with self.assertRaisesRegex(VerificationError, "MISMATCH"):
            inspect_upload_key(self.key, "fixture", None, self.password, self.keytool, expected_sha256="0" * 64)

    def test_wrong_password_is_suppressed(self):
        wrong = "never-echo-this-fixture-password"
        with self.assertRaises(VerificationError) as error:
            inspect_upload_key(self.key, "fixture", self.root / "fixture.der", wrong, self.keytool)
        self.assertNotIn(wrong, str(error.exception))

    def test_missing_alias_blocks(self):
        with self.assertRaises(VerificationError):
            inspect_upload_key(self.key, "missing", self.root / "fixture.der", self.password, self.keytool)

    def test_invalid_public_file_blocks(self):
        with self.assertRaises(VerificationError):
            certificate_der(b"not a certificate")


if __name__ == "__main__":
    unittest.main()
