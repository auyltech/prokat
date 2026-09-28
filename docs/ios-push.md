# iOS push

The iPhone build that completed APNs → FCM → `POST /notifications/device-token` → background delivery uses this FlutterFire set. Do not upgrade these packages on their own.

- `firebase_messaging` 16.7.0
- `firebase_core` 4.15.0
- `firebase_crashlytics` 5.4.0
- `firebase_app_check` 0.4.8

`firebase_core` 4.15.0 selects Firebase iOS SDK 12.19.0. After pulling, run `cd ios && pod install` so `Podfile.lock` matches that graph. Do not ship `firebase_messaging` 16.4.x / 16.6.x or Firebase iOS SDK 12.18.x.

## Xcode / Apple

Bundle ID stays `com.auyltech.prokat`. Signing team for the device build is `VT7KXG8NBR`. Do not change either in this setup.

- Push Notifications capability stays on. The signed app must contain `aps-environment` (`development` for a dev install, `production` for TestFlight / App Store).
- Background Modes in `ios/Runner/Info.plist`: `fetch` (Background fetch) and `remote-notification` (Remote notifications).
- Upload an APNs Authentication Key (`.p8`) for this team and bundle in Firebase Console → Cloud Messaging. Do not commit the key.
- Firebase method swizzling stays enabled. Do not set `FirebaseAppDelegateProxyEnabled` to `false`.
- `AppDelegate` calls `FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()` before `super.application(...)`. Do not add a second `registerForRemoteNotifications()` call.

The app asks for notification permission, waits for the APNs token (up to 10 attempts, 500 ms apart), and only then calls FCM `getToken()`. A later FCM token from `onTokenRefresh` is registered with the same backend call. Logout deactivates the current token while the session is still valid.

## TestFlight checklist

1. `flutter pub get` and `cd ios && pod install` on the Mac that archives.
2. Confirm the embedded pods are `firebase_messaging` 16.7.0 and Firebase iOS SDK 12.19.0.
3. Push Notifications capability is enabled for the archive's signing profile.
4. `aps-environment` on a TestFlight build is `production`, and the APNs key in Firebase covers production.
5. Background Modes `fetch` and `remote-notification` are in the archived `Info.plist`.
6. `FirebaseAppDelegateProxyEnabled` is absent or `true`.
7. Install once, allow notifications, and confirm a background push arrives.
8. Repeat after logout/login and after killing the app.
