import Flutter
import HealthKit
import Foundation

@objc class HealthReadProbe: NSObject, FlutterPlugin {
  private let store = HKHealthStore()
  private static let channelName = "health_read_probe"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName,
                                       binaryMessenger: registrar.messenger())
    let instance = HealthReadProbe()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "probe",
          let args = call.arguments as? [String: Any],
          let id = args["id"] as? String,
          let intervalSec = args["interval"] as? Double,
          let qType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: id))
    else {
      result(FlutterError(code: "bad_args", message: "Invalid arguments", details: nil))
      return
    }

    // Build predicate for last `intervalSec` seconds window
    let now = Date()
    let start = now.addingTimeInterval(-intervalSec)
    let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)

    let query = HKSampleQuery(sampleType: qType,
                              predicate: predicate,
                              limit: 1,
                              sortDescriptors: nil) { _, samples, _ in
      // true if we received any samples in the window
      let hasData = !(samples?.isEmpty ?? true)
      result(hasData)
    }

    store.execute(query)
  }
} 