import Flutter
import UIKit
import UserNotifications
import HealthKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let hydrationTilt = HydrationTiltStream()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let motionRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SetcraftHydrationMotion") {
      FlutterEventChannel(name: "setcraft/hydration_motion", binaryMessenger: motionRegistrar.messenger())
        .setStreamHandler(hydrationTilt)
      let control = FlutterMethodChannel(name: "setcraft/hydration_motion_control", binaryMessenger: motionRegistrar.messenger())
      control.setMethodCallHandler { [weak self] call, result in
        if call.method == "isAvailable" { result(self?.hydrationTilt.available ?? false) }
        else { result(FlutterMethodNotImplemented) }
      }
    }
    if let credentialsRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SetcraftCredentials") {
      let credentials = FlutterMethodChannel(name: "setcraft/credentials", binaryMessenger: credentialsRegistrar.messenger())
      credentials.setMethodCallHandler { call, result in
        guard call.method == "copyToken", let args = call.arguments as? [String: Any],
              let value = args["value"] as? String, value.hasPrefix("sc_mcp_"), value.count <= 150 else {
          result(FlutterError(code: "INVALID_TOKEN", message: "Could not copy this token.", details: nil))
          return
        }
        UIPasteboard.general.setItems([[UIPasteboard.typeAutomatic: value]],
          options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(300)])
        result(nil)
      }
    }

    if let navigationRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "FitAINavigation") {
      let navigationChannel = FlutterMethodChannel(
        name: "fitai/navigation", binaryMessenger: navigationRegistrar.messenger())

      navigationChannel.setMethodCallHandler { call, result in
        guard call.method == "supportsLiquidGlass" else {
          result(FlutterMethodNotImplemented)
          return
        }

        if #available(iOS 26.0, *) {
          result(true)
        } else {
          result(false)
        }
      }
    }

    if let watchRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SetcraftWatchManager") {
      WatchManager.shared.register(with: watchRegistrar)
    }

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

private final class HydrationTiltStream: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()
  private var sink: FlutterEventSink?
  private var observers: [NSObjectProtocol] = []
  private var lastX = Double.nan, lastY = Double.nan, lastZ = Double.nan
  var available: Bool { motion.isDeviceMotionAvailable }

  override init() {
    super.init()
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
      object: nil, queue: .main) { [weak self] _ in self?.motion.stopDeviceMotionUpdates() })
    observers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
      object: nil, queue: .main) { [weak self] _ in self?.start() })
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    lastX = .nan; lastY = .nan; lastZ = .nan
    start()
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopDeviceMotionUpdates()
    sink = nil
    return nil
  }
  private func start() {
    guard available, sink != nil, UIApplication.shared.applicationState == .active else { return }
    motion.stopDeviceMotionUpdates()
    motion.deviceMotionUpdateInterval = 1.0 / 30.0
    motion.startDeviceMotionUpdates(to: .main) { [weak self] sample, error in
      guard let self = self, let sample = sample, error == nil else { return }
      let x = sample.gravity.x, y = sample.gravity.y, z = sample.gravity.z
      guard x.isFinite, y.isFinite, z.isFinite else { return }
      if self.lastX.isFinite && abs(x - self.lastX) + abs(y - self.lastY) + abs(z - self.lastZ) < 0.003 { return }
      self.lastX = x; self.lastY = y; self.lastZ = z
      self.sink?([x, y, z])
    }
  }
  deinit {
    motion.stopDeviceMotionUpdates()
    observers.forEach { NotificationCenter.default.removeObserver($0) }
  }
}
