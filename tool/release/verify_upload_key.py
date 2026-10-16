"""Compare an existing private-key entry with Play's PUBLIC upload certificate.

Only a public certificate is exported. No key creation, signing or store calls.
"""
import argparse
import getpass
import hashlib
import os
from pathlib import Path
import re
import shutil
import ssl
import subprocess
import sys
import tempfile
import warnings


class VerificationError(RuntimeError):
    pass


def certificate_der(data):
    if b"-----BEGIN CERTIFICATE-----" in data:
        matches = re.findall(rb"-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----", data, re.S)
        if len(matches) != 1:
            raise VerificationError("Expected one public Play upload certificate")
        return ssl.PEM_cert_to_DER_cert(matches[0].decode("ascii"))
    if not data or data[0] != 0x30:
        raise VerificationError("Expected a public X.509 certificate in DER or PEM format")
    return data


def inspect_upload_key(keystore, alias, play_certificate, password, keytool="keytool", *, expected_sha256=None):
    keystore = Path(keystore).resolve(strict=True)
    expected = None
    if play_certificate is not None:
        play_certificate = Path(play_certificate).resolve(strict=True)
        if keystore == play_certificate:
            raise VerificationError("Select Play's downloaded public upload certificate separately")
        expected = certificate_der(play_certificate.read_bytes())
    else:
        expected_sha256 = (expected_sha256 or "").replace(":", "").upper()
        if not re.fullmatch(r"[A-F0-9]{64}", expected_sha256):
            raise VerificationError("Expected the 64-hex SHA256 of Play's UPLOAD certificate")
    # The password is only in a child environment, never argv/stdout/stderr.
    child_env = {**os.environ, "PROKAT_KEY_VERIFY_PASSWORD": password}
    base = [keytool, "-J-Duser.language=en", "-J-Duser.country=US", "-keystore", str(keystore),
            "-alias", alias, "-storepass:env", "PROKAT_KEY_VERIFY_PASSWORD"]

    def run(args):
        result = subprocess.run(args, env=child_env, capture_output=True, timeout=60, check=False)
        if result.returncode:
            raise VerificationError("keytool failed: check the existing keystore password, alias and certificate format (output suppressed)")
        return result.stdout.decode("utf-8", errors="replace")

    with tempfile.TemporaryDirectory(prefix="prokat-public-cert-") as directory:
        output = Path(directory) / "upload.der"
        try:
            entry = run([*base, "-list", "-v"])
            if "PrivateKeyEntry" not in entry:
                raise VerificationError("Alias is not a private-key entry; a certificate-only entry cannot sign releases")
            run([*base, "-exportcert", "-file", str(output)])
            # Let keytool validate the downloaded PUBLIC certificate as X.509.
            if play_certificate is not None:
                run([keytool, "-printcert", "-file", str(play_certificate)])
            actual = output.read_bytes()
        finally:
            child_env.pop("PROKAT_KEY_VERIFY_PASSWORD", None)
    digest = hashlib.sha256(actual).hexdigest().upper()
    if (expected is not None and actual != expected) or (expected is None and digest != expected_sha256):
        raise VerificationError("Upload certificate MISMATCH. Do not replace/reset keys or upload a build; inspect the selected Play certificate/alias")
    return ":".join(digest[i:i + 2] for i in range(0, len(digest), 2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keystore", required=True)
    parser.add_argument("--alias", required=True)
    expected = parser.add_mutually_exclusive_group(required=True)
    expected.add_argument("--play-certificate")
    expected.add_argument("--expected-sha256")
    parser.add_argument("--password-env", help="Read password from this environment variable; never put the password itself in argv")
    args = parser.parse_args()
    if not args.password_env and not sys.stdin.isatty():
        raise VerificationError("Run interactively in a terminal: a hidden keystore password prompt is required")
    keytool = shutil.which("keytool")
    if not keytool:
        raise VerificationError("Install/use the existing JDK and expose keytool on PATH")
    if args.password_env:
        password = os.environ.get(args.password_env)
        if not password:
            raise VerificationError("Keystore password environment variable is missing/empty")
    else:
        with warnings.catch_warnings():
            warnings.simplefilter("error", getpass.GetPassWarning)
            password = getpass.getpass("Existing keystore password (hidden): ")
    fingerprint = inspect_upload_key(args.keystore, args.alias, args.play_certificate, password, keytool,
                                     expected_sha256=args.expected_sha256)
    print("VERIFIED: existing private-key entry matches Play's public UPLOAD certificate")
    print("ANDROID_UPLOAD_CERT_SHA256=" + fingerprint)
    print("No private key exported, keystore modified, build signed or store contacted. Key password is not verified by this certificate check.")


if __name__ == "__main__":
    try:
        main()
    except (VerificationError, OSError, ValueError, subprocess.SubprocessError, getpass.GetPassWarning) as error:
        detail = str(error) if isinstance(error, VerificationError) else type(error).__name__
        raise SystemExit("BLOCKED: " + detail) from None
