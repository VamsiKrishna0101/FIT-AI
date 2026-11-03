import Foundation
import SwiftUI
import WatchConnectivity
import HealthKit

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    static let shared = WorkoutManager()
    
    // MARK: - Published State
    @Published var snapshot: WatchWorkoutSnapshot?
    @Published var activeItemIndex: Int = 0
    @Published var rest: WatchRestPayload?
    @Published var isSessionActive: Bool = false
    @Published var heartRate: Double = 0
    @Published var hrZone: Int = 1
    @Published var activeCalories: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var isConnectedToPhone: Bool = false
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var session: WCSession?
    private var workoutSession: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Workout Lifecycle
    
    func startHealthKitWorkout() {
        guard HKHealthStore.isHealthDataAvailable(), workoutSession == nil else { return }
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, _ in
            guard success, let self = self else { return }
            
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .traditionalStrengthTraining
            configuration.locationType = .indoor
            
            do {
                self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
                self.builder = self.workoutSession?.associatedWorkoutBuilder()
                
                self.workoutSession?.delegate = self
                self.builder?.delegate = self
                
                self.builder?.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: configuration)
                
                let startDate = Date()
                self.workoutSession?.startActivity(with: startDate)
                self.builder?.beginCollection(withStart: startDate) { _, _ in }
                
                DispatchQueue.main.async {
                    self.isSessionActive = true
                    self.startTimer()
                }
            } catch {
                print("Failed to start HealthKit workout session: \(error.localizedDescription)")
            }
        }
    }
    
    func endHealthKitWorkout() {
        workoutSession?.end()
        builder?.endCollection(withEnd: Date()) { [weak self] success, _ in
            self?.builder?.finishWorkout { _, _ in
                DispatchQueue.main.async {
                    self?.workoutSession = nil
                    self?.builder = nil
                    self?.isSessionActive = false
                    self?.timer?.invalidate()
                    self?.timer = nil
                }
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        elapsedSeconds = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedSeconds += 1
            if self.elapsedSeconds % 5 == 0 {
                self.broadcastBiometricsToPhone()
            }
        }
    }
    
    // MARK: - User Actions Sent to Phone
    
    func logSet(itemId: String, setNumber: Int, weight: Double, reps: Int) {
        WKInterfaceDevice.current().play(.success)
        let payload: [String: Any] = [
            "action": "LOG_SET",
            "itemId": itemId,
            "setNumber": setNumber,
            "weight": weight,
            "reps": reps
        ]
        sendToPhone(payload)
    }
    
    func selectExercise(itemId: String) {
        WKInterfaceDevice.current().play(.click)
        let payload: [String: Any] = [
            "action": "SELECT_EXERCISE",
            "itemId": itemId
        ]
        sendToPhone(payload)
    }
    
    func skipExercise(itemId: String) {
        WKInterfaceDevice.current().play(.directionDown)
        let payload: [String: Any] = [
            "action": "SKIP_EXERCISE",
            "itemId": itemId
        ]
        sendToPhone(payload)
    }
    
    func controlRest(operation: String) {
        WKInterfaceDevice.current().play(.click)
        let payload: [String: Any] = [
            "action": "REST_CONTROL",
            "operation": operation
        ]
        sendToPhone(payload)
    }
    
    func finishWorkout() {
        WKInterfaceDevice.current().play(.stop)
        endHealthKitWorkout()
        let payload: [String: Any] = [
            "action": "FINISH_WORKOUT"
        ]
        sendToPhone(payload)
    }
    
    private func broadcastBiometricsToPhone() {
        let payload: [String: Any] = [
            "action": "BIOMETRIC_UPDATE",
            "heartRate": Int(heartRate),
            "hrZone": hrZone,
            "activeCalories": activeCalories,
            "elapsedSeconds": elapsedSeconds
        ]
        sendToPhone(payload)
    }
    
    private func sendToPhone(_ payload: [String: Any]) {
        guard let session = session, session.activationState == .activated else { return }
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = activationState == .activated && session.isCompanionAppInstalled
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleIncomingPayload(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleIncomingPayload(applicationContext)
        }
    }
    
    private func handleIncomingPayload(_ payload: [String: Any]) {
        if let type = payload["type"] as? String {
            if type == "SESSION_CLEARED" {
                self.snapshot = nil
                self.rest = nil
                self.endHealthKitWorkout()
                return
            } else if type == "REST_UPDATE" {
                if let restDict = payload["rest"] as? [String: Any],
                   let data = try? JSONSerialization.data(withJSONObject: restDict),
                   let rest = try? JSONDecoder().decode(WatchRestPayload.self, from: data) {
                    self.rest = rest
                } else {
                    self.rest = nil
                }
                return
            }
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let snapshot = try? JSONDecoder().decode(WatchWorkoutSnapshot.self, from: data) {
            self.snapshot = snapshot
            self.activeItemIndex = snapshot.activeItemIndex
            self.rest = snapshot.rest
            
            // Auto start healthkit tracking if not running
            if !self.isSessionActive {
                self.startHealthKitWorkout()
            }
        }
    }
    
    // MARK: - HKWorkoutSessionDelegate
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.isSessionActive = (toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("HKWorkoutSession failed: \(error.localizedDescription)")
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async {
                if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                    let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                    let hrValue = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                    self.heartRate = hrValue
                    self.calculateZone(hr: hrValue)
                } else if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    let calUnit = HKUnit.kilocalorie()
                    let calories = statistics?.sumQuantity()?.doubleValue(for: calUnit) ?? 0
                    self.activeCalories = calories
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    private func calculateZone(hr: Double) {
        // Standard 5-Zone calculation (based on estimate max HR 190)
        if hr < 110 {
            hrZone = 1
        } else if hr < 135 {
            hrZone = 2
        } else if hr < 155 {
            hrZone = 3
        } else if hr < 172 {
            hrZone = 4
        } else {
            hrZone = 5
        }
    }
}

