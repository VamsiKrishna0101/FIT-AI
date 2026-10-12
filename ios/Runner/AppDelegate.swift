import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FitAIHealthTotals") else { return }
    let channel = FlutterMethodChannel(name: "fitai/health_ui", binaryMessenger: registrar.messenger())
    let store = HKHealthStore()
    channel.setMethodCallHandler { call, result in
      guard call.method == "activeEnergyTotal" || call.method == "stepTotal" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard HKHealthStore.isHealthDataAvailable(),
        let args = call.arguments as? [String: Any],
        let start = args["start"] as? NSNumber, let end = args["end"] as? NSNumber,
        end.doubleValue > start.doubleValue,
        let type = HKQuantityType.quantityType(forIdentifier: call.method == "stepTotal" ? .stepCount : .activeEnergyBurned) else {
        result(FlutterError(code: "UNAVAILABLE", message: "Health data is unavailable.", details: nil))
        return
      }
      let predicate = HKQuery.predicateForSamples(
        withStart: Date(timeIntervalSince1970: start.doubleValue / 1000),
        end: Date(timeIntervalSince1970: end.doubleValue / 1000), options: [])
      let unit: HKUnit = call.method == "stepTotal" ? .count() : .kilocalorie()
      let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
        options: .cumulativeSum) { _, statistics, error in
        DispatchQueue.main.async {
          if error != nil {
            result(FlutterError(code: "READ_FAILED", message: "This movement reading is unavailable.", details: nil))
          } else {
            result(statistics?.sumQuantity()?.doubleValue(for: unit))
          }
        }
      }
      store.execute(query)
    }
  }
}
