import Foundation
import TUICore

public enum TUIConversationItemInMoreMenu: UInt {
    case None = 0
    case Delete = 1
    case MarkRead = 2
    case Hide = 4
    case Pin = 8
    case Clear = 16
}

public protocol TUIConversationConfigDataSource: AnyObject {
    /**
     * Implement this method to hide items in more menu.
     */
    func conversationShouldHideItemsInMoreMenu(_ data: TUIConversationCellData) -> TUIConversationItemInMoreMenu
    /**
     * Implement this method to add new items.
     */
    func conversationShouldAddNewItemsToMoreMenu(_ data: TUIConversationCellData) -> [Any]
}

public extension TUIConversationConfigDataSource {
    func conversationShouldHideItemsInMoreMenu(_ data: TUIConversationCellData) -> TUIConversationItemInMoreMenu { return .None }
    func conversationShouldAddNewItemsToMoreMenu(_ data: TUIConversationCellData) -> [Any] { return [] }
}

public class TUIConversationConfig: NSObject {
    
    public static let sharedConfig: TUIConversationConfig = {
        let config = TUIConversationConfig()
        return config
    }()
    
    /**
     *  DataSource of more menu.
     */
    public weak var moreMenuDataSource: TUIConversationConfigDataSource?
    /**
     *  Background color of conversation list.
     */
    public var listBackgroundColor: UIColor?
    /**
     *  Background color of cell in conversation list.
     *  This configuration takes effect in all cells.
     */
    public var cellBackgroundColor: UIColor?
    /**
     *  Background color of pinned cell in conversation list.
     *  This configuration takes effect in all pinned cells.
     */
    public var pinnedCellBackgroundColor: UIColor?
    /**
     *  Font of title label of cell in conversation list.
     *  This configuration takes effect in all cells.
     */
    public var cellTitleLabelFont: UIFont?
    /**
     *  Font of subtitle label of cell in conversation list.
     *  This configuration takes effect in all cells.
     */
    public var cellSubtitleLabelFont: UIFont?
    /**
     *  Font of time label of cell in conversation list.
     *  This configuration takes effect in all cells.
     */
    public var cellTimeLabelFont: UIFont?
    /**
     *  Display unread count icon in each conversation cell.
     *  The default value is YES.
     */
    public var showCellUnreadCount: Bool = true
    /**
     *  Corner radius of the avatar.
     *  This configuration takes effect in all avatars.
     */
    public var avatarCornerRadius: CGFloat {
        get {
            return TUIConfig.default().avatarCornerRadius
        }
        set {
            TUIConfig.default().avatarCornerRadius = newValue
        }
    }
    /**
     *  Display user's online status icon in conversation and contact list.
     *  The default value is NO.
     */
    public var showUserOnlineStatusIcon: Bool {
        get {
            return TUIConfig.default().displayOnlineStatusIcon
        }
        set {
            TUIConfig.default().displayOnlineStatusIcon = newValue
        }
    }
}
