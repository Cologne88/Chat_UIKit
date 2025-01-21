import Foundation
import ImSDK_Plus

enum TUISearchType: Int {
    case contact = 0
    case group = 1
    case chatHistory = 2
}

@objc public protocol TUIConversationListControllerListener: NSObjectProtocol {
    @objc optional func getConversationDisplayString(_ conversation: V2TIMConversation) -> String?
    @objc optional func conversationListController(_ conversationController: UIViewController, didSelectConversation conversation: TUIConversationCellData)
    @objc optional func onClearAllConversationUnreadCount()
    @objc optional func onCloseConversationMultiChooseBoard()
}
