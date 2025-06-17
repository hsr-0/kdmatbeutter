import UIKit
import Flutter
import FirebaseCore

@main // ← تغيير من @UIApplicationMain إلى @main
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة Firebase (يجب أن تكون قبل register)
    FirebaseApp.configure()

    // تسيع plugins
    GeneratedPluginRegistrant.register(with: self)

    // إعدادات إضافية للـ window (اختياري)
    if #available(iOS 13.0, *) {
      window?.overrideUserInterfaceStyle = .light // إجبار الوضع الفاتح
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // إضافة هذه الدالة إذا كنت تستخدم Push Notifications
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}