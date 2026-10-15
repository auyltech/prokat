"""Small pre-push check; prints paths/counts, never matched secret values."""
import re
import subprocess
from pathlib import PurePosixPath

FORBIDDEN = {".p8", ".p12", ".jks", ".keystore", ".mobileprovision", ".pem"}


def main():
    result = subprocess.run(["git", "diff", "--cached", "--name-only", "--diff-filter=ACM", "-z"], capture_output=True, check=True)
    names = [n for n in result.stdout.decode("utf-8").split("\0") if n]
    for name in names:
        path = PurePosixPath(name)
        if path.suffix in FORBIDDEN or path.name in ("google-services.json", "GoogleService-Info.plist", "key.properties") or (path.name.startswith(".env") and not path.name.endswith(".example")):
            raise SystemExit(f"BLOCKED: credential/config file staged: {name}")
        content = subprocess.run(["git", "show", ":" + name], capture_output=True, check=True).stdout
        patterns = [rb"-----BEGIN (?:RSA |EC )?PRIVATE KEY-----", rb'"private_key"\s*:\s*"-----', rb"gh[pousr]_[A-Za-z0-9]{30,}", rb"github_pat_[A-Za-z0-9_]{50,}"]
        if any(re.search(pattern, content) for pattern in patterns):
            raise SystemExit(f"BLOCKED: possible private credential staged: {name}")
    print(f"VERIFIED: {len(names)} staged files checked for prohibited credential paths/key/token patterns (not a complete secret detector)")


if __name__ == "__main__":
    main()
