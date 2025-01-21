import Foundation

struct TUIGroupConfigItem: OptionSet {
    let rawValue: Int

    static let none = TUIGroupConfigItem([])
    static let members = TUIGroupConfigItem(rawValue: 1 << 0)
    static let notice = TUIGroupConfigItem(rawValue: 1 << 1)
    static let manage = TUIGroupConfigItem(rawValue: 1 << 2)
    static let alias = TUIGroupConfigItem(rawValue: 1 << 3)
    static let muteAndPin = TUIGroupConfigItem(rawValue: 1 << 4)
    static let background = TUIGroupConfigItem(rawValue: 1 << 5)
    static let clearChatHistory = TUIGroupConfigItem(rawValue: 1 << 6)
    static let deleteAndLeave = TUIGroupConfigItem(rawValue: 1 << 7)
    static let transfer = TUIGroupConfigItem(rawValue: 1 << 8)
    static let dismiss = TUIGroupConfigItem(rawValue: 1 << 9)
    static let report = TUIGroupConfigItem(rawValue: 1 << 10)
}

class TUIGroupConfig {
    static let shared = TUIGroupConfig()

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

    func hideItemsInGroupConfig(_ items: TUIGroupConfigItem) {
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

    func isItemHiddenInGroupConfig(_ item: TUIGroupConfigItem) -> Bool {
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
