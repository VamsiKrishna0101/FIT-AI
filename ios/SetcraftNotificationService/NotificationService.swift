import UserNotifications

/// Adds Mochi, Setcraft's AI coach, to remote notifications.
/// The backend sets `mutable-content: 1` and `coach: "mochi"` on coaching alerts;
/// the artwork ships inside this extension, so nothing is downloaded.
final class NotificationService: UNNotificationServiceExtension {
  private var contentHandler: ((UNNotificationContent) -> Void)?
  private var bestAttempt: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
      contentHandler(request.content)
      return
    }
    bestAttempt = content
    if request.content.userInfo["coach"] as? String == "mochi",
       let attachment = mochiAttachment() {
      content.attachments = [attachment]
    }
    contentHandler(content)
  }

  override func serviceExtensionTimeWillExpire() {
    if let contentHandler = contentHandler, let bestAttempt = bestAttempt {
      contentHandler(bestAttempt)
    }
  }

  private func mochiAttachment() -> UNNotificationAttachment? {
    guard let source = Bundle.main.url(forResource: "mochi-coach", withExtension: "png") else {
      return nil
    }
    // The system moves attachment files into its own store, so attach a copy.
    let copy = FileManager.default.temporaryDirectory
      .appendingPathComponent("mochi-\(UUID().uuidString).png")
    do {
      try FileManager.default.copyItem(at: source, to: copy)
      return try UNNotificationAttachment(identifier: "mochi", url: copy, options: nil)
    } catch {
      return nil
    }
  }
}
