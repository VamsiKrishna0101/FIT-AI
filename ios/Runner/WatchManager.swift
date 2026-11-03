import Foundation
import WatchConnectivity
import HealthKit
import Flutter

@objc class WatchManager: NSObject, WCSessionDelegate {
    @objc static let shared = WatchManager()
    
    private var channel: FlutterMethodChannel?
    private var session: WCSession?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    @objc func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "setcraft/watch", binaryMessenger: registrar.messenger())
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let session = session, session.activationState == .activated else {
            result(FlutterError(code: "WATCH_UNAVAILABLE", message: "Watch connectivity is inactive or unsupported", details: nil))
            return
        }
        
        switch call.method {
        case "checkWatchState":
            result([
                "isPaired": session.isPaired,
                "isAppInstalled": session.isWatchAppInstalled,
                "isReachable": session.isReachable
            ])

        case "startWatchApp":
            guard HKHealthStore.isHealthDataAvailable() else {
                result(false)
                return
            }
            let config = HKWorkoutConfiguration()
            config.activityType = .traditionalStrengthTraining
            config.locationType = .indoor
            let store = HKHealthStore()
            store.startWatchApp(with: config) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("[WatchManager] startWatchApp error: \(error.localizedDescription)")
                    }
                    result(success)
                }
            }

        case "openWatchSettings":
            DispatchQueue.main.async {
                if let url = URL(string: "itms-watchs://"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:]) { success in
                        result(success)
                    }
                } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl, options: [:]) { success in
                        result(success)
                    }
                } else {
                    result(false)
                }
            }
            
        case "updateWorkoutState":
            if let payload = call.arguments as? [String: Any] {
                try? session.updateApplicationContext(payload)
                if session.isReachable {
                    session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
                }
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Payload must be a dictionary", details: nil))
            }
            
        case "updateRestState":
            if let payload = call.arguments as? [String: Any] {
                var context = session.receivedApplicationContext
                context["rest"] = payload
                try? session.updateApplicationContext(context)
                if session.isReachable {
                    session.sendMessage(["type": "REST_UPDATE", "rest": payload], replyHandler: nil, errorHandler: nil)
                }
                result(true)
            } else {
                // Clear rest
                var context = session.receivedApplicationContext
                context.removeValue(forKey: "rest")
                try? session.updateApplicationContext(context)
                if session.isReachable {
                    session.sendMessage(["type": "REST_UPDATE", "rest": NSNull()], replyHandler: nil, errorHandler: nil)
                }
                result(true)
            }
            
        case "clearSession":
            try? session.updateApplicationContext([:])
            if session.isReachable {
                session.sendMessage(["type": "SESSION_CLEARED"], replyHandler: nil, errorHandler: nil)
            }
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Session activated
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.routeWatchAction(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.routeWatchAction(applicationContext)
        }
    }
    
    private func routeWatchAction(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }
        
        switch action {
        case "LOG_SET":
            channel?.invokeMethod("onLogSet", arguments: payload)
            
        case "SELECT_EXERCISE":
            channel?.invokeMethod("onSelectExercise", arguments: payload)
            
        case "SKIP_EXERCISE":
            channel?.invokeMethod("onSkipExercise", arguments: payload)
            
        case "REST_CONTROL":
            channel?.invokeMethod("onRestControl", arguments: payload)
            
        case "BIOMETRIC_UPDATE":
            channel?.invokeMethod("onBiometricUpdate", arguments: payload)
            
        case "FINISH_WORKOUT":
            channel?.invokeMethod("onFinishWorkout", arguments: payload)
            
        default:
            break
        }
    }
}

