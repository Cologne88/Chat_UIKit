import Foundation
import TIMCommon
import UIKit

class TUIChatMediaTask {
    var placeHolderCellData: TUIMessageCellData?
    var msgID: String?
    var conversationID: String?
}

class TUIChatMediaSendingManager {
    static let shared = TUIChatMediaSendingManager()
    var tasks: [String: TUIChatMediaTask] = [:]
    var mediaSendingControllers: NSHashTable<UIViewController> = NSHashTable.weakObjects()

    private init() {}

    func addMediaTask(_ task: TUIChatMediaTask, forKey key: String) {
        tasks[key] = task
    }

    func updateProgress(_ progress: Float, forKey key: String) {
        if let task = tasks[key] {
            task.placeHolderCellData?.videoTranscodingProgress = CGFloat(progress)
        }
    }

    func removeMediaTask(forKey key: String) {
        tasks.removeValue(forKey: key)
    }

    func findPlaceHolderList(byConversationID conversationID: String) -> [TUIChatMediaTask] {
        return tasks.values.filter { $0.conversationID == conversationID }
    }

    func addCurrentVC(_ vc: UIViewController) {
        mediaSendingControllers.add(vc)
    }

    func removeCurrentVC(_ vc: UIViewController) {
        mediaSendingControllers.remove(vc)
    }
}
