import Foundation
import TUICore

enum TUIConversationItemInMoreMenu: UInt {
    case None = 0
    case Delete = 1
    case MarkRead = 2
    case Hide = 4
    case Pin = 8
    case Clear = 16
}

protocol TUIConversationConfigDataSource: NSObjectProtocol {
    func conversationShouldHideItemsInMoreMenu(_ data: TUIConversationCellData) -> TUIConversationItemInMoreMenu
    func conversationShouldAddNewItemsToMoreMenu(_ data: TUIConversationCellData) -> [Any]
}

class TUIConversationConfig: NSObject {
    
    static let sharedConfig: TUIConversationConfig = {
        let config = TUIConversationConfig()
        return config
    }()
    
    weak var moreMenuDataSource: TUIConversationConfigDataSource?
    var listBackgroundColor: UIColor?
    var cellBackgroundColor: UIColor?
    var pinnedCellBackgroundColor: UIColor?
    var cellTitleLabelFont: UIFont?
    var cellSubtitleLabelFont: UIFont?
    var cellTimeLabelFont: UIFont?
    var showCellUnreadCount: Bool = true
    
    var avatarCornerRadius: CGFloat {
        get {
            return TUIConfig.default().avatarCornerRadius
        }
        set {
            TUIConfig.default().avatarCornerRadius = newValue
        }
    }
    
    var showUserOnlineStatusIcon: Bool {
        get {
            return TUIConfig.default().displayOnlineStatusIcon
        }
        set {
            TUIConfig.default().displayOnlineStatusIcon = newValue
        }
    }
}
