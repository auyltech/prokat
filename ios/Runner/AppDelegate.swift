import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var didRequestRemoteNotifications = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    NSLog(
      "%@",
      "[push-diag] didFinishLaunching isRegisteredForRemoteNotifications=\(application.isRegisteredForRemoteNotifications)"
        as NSString
    )
    return result
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    guard !didRequestRemoteNotifications else {
      return
    }
    didRequestRemoteNotifications = true
    NSLog(
      "%@",
      "[push-diag] before registerForRemoteNotifications isRegisteredForRemoteNotifications=\(application.isRegisteredForRemoteNotifications)"
        as NSString
    )
    application.registerForRemoteNotifications()
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    NSLog(
      "%@",
      "[push-diag] didRegisterForRemoteNotifications token present len=\(deviceToken.count)"
        as NSString
    )
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog(
      "%@",
      "[push-diag] didFailToRegisterForRemoteNotifications error=\(error)" as NSString
    )
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
