import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    // ── Health Permission Bridge (iOS-only) ────────────────────────────
    // Provides tri-state permission status per HK identifier:
    //   0 = notDetermined, 1 = denied, 2 = authorized
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.bee.health_permission_status",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        guard call.method == "check" else {
          result(FlutterMethodNotImplemented)
          return
        }
        // Temporary no-op implementation – returns empty map
        result([:])
      }
    }
    // ────────────────────────────────────────────────────────────────
    
    // ── Health Read Probe (lightweight query) ───────────────────────
    let probeChannel = FlutterMethodChannel(
      name: "health_read_probe",
      binaryMessenger: (window?.rootViewController as! FlutterViewController).binaryMessenger
    )

    probeChannel.setMethodCallHandler { call, result in
      guard call.method == "probe",
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let interval = args["interval"] as? Double,
            let qType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: id))
      else {
        result(FlutterError(code: "bad_args", message: nil, details: nil))
        return
      }

      let store = HKHealthStore()
      let now = Date()
      let start = now.addingTimeInterval(-interval)
      let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)

      let query = HKSampleQuery(sampleType: qType,
                                predicate: predicate,
                                limit: 1,
                                sortDescriptors: nil) { _, samples, _ in
        let hasData = !(samples?.isEmpty ?? true)
        result(hasData)
      }
      store.execute(query)
    }
    // ────────────────────────────────────────────────────────────────
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token registration
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Handle APNs registration failure
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    print("Failed to register for remote notifications: \(error)")
  }
}
