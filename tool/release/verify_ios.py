"""Verify the actual exported IPA identity and distribution entitlements."""
import datetime
import json
import plistlib
import subprocess
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXPECTED_DOMAINS = {
    "applinks:prokat-bfbec.web.app", "applinks:prokat-bfbec.firebaseapp.com",
    "applinks:open.prokat.auyltech.kz",
}


def validate(info, entitlements, profile, context):
    if not isinstance(info.get("ITSAppUsesNonExemptEncryption"), bool):
        raise RuntimeError("U3 must resolve the app export compliance declaration before automated submission")
    if (info["CFBundleIdentifier"] != "com.auyltech.prokat" or
            info["CFBundleShortVersionString"] != context["version"] or
            info["CFBundleVersion"] != str(context["build"])):
        raise RuntimeError("IPA bundle/version differs from Git tag")
    if (entitlements.get("aps-environment") != "production" or
            entitlements.get("get-task-allow", False) or
            entitlements.get("application-identifier") != "VT7KXG8NBR.com.auyltech.prokat" or
            entitlements.get("com.apple.developer.team-identifier") != "VT7KXG8NBR" or
            set(entitlements.get("com.apple.developer.associated-domains", [])) != EXPECTED_DOMAINS):
        raise RuntimeError("IPA signing capabilities/team mismatch")
    if "ProvisionedDevices" in profile or profile.get("ProvisionsAllDevices") or profile["ExpirationDate"] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
        raise RuntimeError("Distribution profile expired or not App Store distribution")
    allowed = profile["Entitlements"]
    if (profile.get("TeamIdentifier") != ["VT7KXG8NBR"] or
            allowed.get("application-identifier") != "VT7KXG8NBR.com.auyltech.prokat" or
            allowed.get("com.apple.developer.team-identifier") != "VT7KXG8NBR" or
            allowed.get("get-task-allow", False) or
            allowed.get("aps-environment") != "production"):
        raise RuntimeError("Profile app/team/distribution/APNs mismatch")


def main():
    context = json.loads((ROOT / "build/release/context.json").read_text())
    ipas = list((ROOT / "build/ios/ipa").glob("*.ipa"))
    if len(ipas) != 1:
        raise RuntimeError("Expected exactly one IPA")
    with zipfile.ZipFile(ipas[0]) as archive:
        info = plistlib.loads(archive.read("Payload/Runner.app/Info.plist"))
    with tempfile.TemporaryDirectory(prefix="prokat-ipa-check-") as directory:
        subprocess.run(["ditto", "-x", "-k", str(ipas[0]), directory], check=True)
        app = Path(directory) / "Payload/Runner.app"
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
        signed = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)], check=True, capture_output=True)
        entitlements = plistlib.loads(signed.stdout)
        decoded = subprocess.run(["security", "cms", "-D", "-i", str(app / "embedded.mobileprovision")], check=True, capture_output=True)
        profile = plistlib.loads(decoded.stdout)
        validate(info, entitlements, profile, context)
        # Firebase initializeApp has Dart options, but the plist is required by
        # upload-symbols. It is deliberately supplied as a protected CI input.
        firebase = plistlib.loads((ROOT / "ios/Runner/GoogleService-Info.plist").read_bytes())
        if firebase["BUNDLE_ID"] != "com.auyltech.prokat" or firebase["GOOGLE_APP_ID"] != "1:1074557540622:ios:77d941fb94c43410845f5f" or firebase["PROJECT_ID"] != "prokat-bfbec":
            raise RuntimeError("Firebase iOS identity mismatch")
        print("VERIFIED: IPA signature, bundle, version, App Store profile, team, APNs and domains")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        detail = str(error) if isinstance(error, RuntimeError) else type(error).__name__
        raise SystemExit(f"BLOCKED: iOS artifact verification failed: {detail}") from None
