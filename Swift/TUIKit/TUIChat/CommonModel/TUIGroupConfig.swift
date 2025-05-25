import Foundation

public struct TUIGroupConfigItem: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = TUIGroupConfigItem([])
    public static let members = TUIGroupConfigItem(rawValue: 1 << 0)
    public static let notice = TUIGroupConfigItem(rawValue: 1 << 1)
    public static let manage = TUIGroupConfigItem(rawValue: 1 << 2)
    public static let alias = TUIGroupConfigItem(rawValue: 1 << 3)
    public static let muteAndPin = TUIGroupConfigItem(rawValue: 1 << 4)
    public static let background = TUIGroupConfigItem(rawValue: 1 << 5)
    public static let clearChatHistory = TUIGroupConfigItem(rawValue: 1 << 6)
    public static let deleteAndLeave = TUIGroupConfigItem(rawValue: 1 << 7)
    public static let transfer = TUIGroupConfigItem(rawValue: 1 << 8)
    public static let dismiss = TUIGroupConfigItem(rawValue: 1 << 9)
    public static let report = TUIGroupConfigItem(rawValue: 1 << 10)
}

public class TUIGroupConfig {
    public static let shared = TUIGroupConfig()

    private var hideGroupMembersItems = false
    private var hideGroupNoticeItem = false
    private var hideGroupManageItems = false
    private var hideGroupAliasItem = false
    private var hideGroupMuteAndPinItems = false
    private var hideGroupBackgroundItem = false
    private var hideGroupClearChatHistory = false
    private var hideGroupDeleteAndLeave = false
    private var hideGroupTransfer = false
    private var hideGroupDismiss = false
    private var hideGroupReport = false

    private init() {}

    /**
     * Hide items in group config interface.
     */
    public func hideItemsInGroupConfig(_ items: TUIGroupConfigItem) {
        hideGroupMuteAndPinItems = items.contains(.muteAndPin)
        hideGroupManageItems = items.contains(.manage)
        hideGroupAliasItem = items.contains(.alias)
        hideGroupBackgroundItem = items.contains(.background)
        hideGroupMembersItems = items.contains(.members)
        hideGroupClearChatHistory = items.contains(.clearChatHistory)
        hideGroupDeleteAndLeave = items.contains(.deleteAndLeave)
        hideGroupTransfer = items.contains(.transfer)
        hideGroupDismiss = items.contains(.dismiss)
        hideGroupReport = items.contains(.report)
    }

    /**
     * Get the hidden status of specified item.
     */
    public func isItemHiddenInGroupConfig(_ item: TUIGroupConfigItem) -> Bool {
        if item.contains(.muteAndPin) {
            return hideGroupMuteAndPinItems
        } else if item.contains(.manage) {
            return hideGroupManageItems
        } else if item.contains(.alias) {
            return hideGroupAliasItem
        } else if item.contains(.background) {
            return hideGroupBackgroundItem
        } else if item.contains(.members) {
            return hideGroupMembersItems
        } else if item.contains(.clearChatHistory) {
            return hideGroupClearChatHistory
        } else if item.contains(.deleteAndLeave) {
            return hideGroupDeleteAndLeave
        } else if item.contains(.transfer) {
            return hideGroupTransfer
        } else if item.contains(.dismiss) {
            return hideGroupDismiss
        } else if item.contains(.report) {
            return hideGroupReport
        } else {
            return false
        }
    }
}
