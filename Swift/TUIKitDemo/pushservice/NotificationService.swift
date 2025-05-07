import UserNotifications

import TIMPush

class NotificationService: UNNotificationServiceExtension, @unchecked Sendable {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler

        // appGroup identifies the APP Group shared between the current main APP and Extension. The App Groups capability needs to be configured in the Capability of the main APP.
        // The format is group + [main bundleID] + key
        // Such as group.com.tencent.im.pushkey
        let appGroupID = kTIMPushAppGroupKey

        TIMPushManager.handleNotificationServiceRequest(request: request, appGroupID: appGroupID) { [weak self] content in
            guard let self = self else { return }
            self.bestAttemptContent = content.mutableCopy() as? UNMutableNotificationContent
            // Modify the notification content here...
            // strongSelf.bestAttemptContent?.title = "\(strongSelf.bestAttemptContent?.title ?? "") [modified]"

            if let attachmentPath = self.bestAttemptContent?.userInfo["image"] as? String {
                if let fileURL = URL(string: attachmentPath) {
                    self.downloadAndSave(fileURL) { [weak self] localPath in
                        guard let self = self else { return }
                        if let localPath = localPath {
                            if let attachment = try? UNNotificationAttachment(identifier: "myAttachment", url: URL(fileURLWithPath: localPath), options: nil) {
                                self.bestAttemptContent?.attachments = [attachment]
                            }
                        }
                        self.contentHandler?(self.bestAttemptContent ?? UNNotificationContent())
                    }
                }
            } else {
                self.contentHandler?(self.bestAttemptContent ?? UNNotificationContent())
            }
        }
    }

    func downloadAndSave(_ fileURL: URL, handler: @escaping @Sendable (String?) -> Void) {
        let session = URLSession.shared
        let completion: @Sendable (URL?, URLResponse?, (any Error)?) -> Void = { location, _, error in
            var localPath: String?
            if error == nil, let location = location {
                let localURL = "\(NSTemporaryDirectory())/\(fileURL.lastPathComponent)"
                try? FileManager.default.moveItem(atPath: location.path, toPath: localURL)
                localPath = localURL
            }
            handler(localPath)
        }

        let task = session.downloadTask(with: fileURL, completionHandler: completion)
        task.resume()
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let bestAttemptContent = bestAttemptContent {
            contentHandler?(bestAttemptContent)
        }
    }
}
