import Foundation
import ImSDK_Plus

enum TUISearchType: Int {
    case contact = 0
    case group = 1
    case chatHistory = 2
}

public protocol TUIConversationListControllerListener: AnyObject {
    func getConversationDisplayString(_ conversation: V2TIMConversation) -> String?
    func conversationListController(_ conversationController: UIViewController, didSelectConversation conversation: TUIConversationCellData) -> Bool
    func onClearAllConversationUnreadCount()
    func onCloseConversationMultiChooseBoard()
}

public extension TUIConversationListControllerListener {
    func getConversationDisplayString(_ conversation: V2TIMConversation) -> String? { return nil }
    func conversationListController(_ conversationController: UIViewController, didSelectConversation conversation: TUIConversationCellData) -> Bool { return false }
    func onClearAllConversationUnreadCount() {}
    func onCloseConversationMultiChooseBoard() {}
}
