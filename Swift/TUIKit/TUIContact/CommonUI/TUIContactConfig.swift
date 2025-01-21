import Foundation

struct TUIContactConfigItem: OptionSet {
    let rawValue: Int

    static let none = TUIContactConfigItem([])
    static let alias = TUIContactConfigItem(rawValue: 1 << 0)
    static let muteAndPin = TUIContactConfigItem(rawValue: 1 << 1)
    static let background = TUIContactConfigItem(rawValue: 1 << 2)
    static let block = TUIContactConfigItem(rawValue: 1 << 3)
    static let clearChatHistory = TUIContactConfigItem(rawValue: 1 << 4)
    static let delete = TUIContactConfigItem(rawValue: 1 << 5)
    static let addFriend = TUIContactConfigItem(rawValue: 1 << 6)
}

class TUIContactConfig {
    static let shared = TUIContactConfig()

    private var hideContactAlias: Bool = false
    private var hideContactMuteAndPinItems: Bool = false
    private var hideContactBackgroundItem: Bool = false
    private var hideContactBlock: Bool = false
    private var hideContactClearChatHistory: Bool = false
    private var hideContactDelete: Bool = false
    private var hideContactAddFriend: Bool = false

    private init() {
        // 初始化时所有项都不隐藏
    }

    func hideItemsInContactConfig(_ items: TUIContactConfigItem) {
        hideContactAlias = items.contains(.alias)
        hideContactMuteAndPinItems = items.contains(.muteAndPin)
        hideContactBackgroundItem = items.contains(.background)
        hideContactBlock = items.contains(.block)
        hideContactClearChatHistory = items.contains(.clearChatHistory)
        hideContactDelete = items.contains(.delete)
        hideContactAddFriend = items.contains(.addFriend)
    }

    func isItemHiddenInContactConfig(_ item: TUIContactConfigItem) -> Bool {
        switch item {
        case .alias:
            return hideContactAlias
        case .muteAndPin:
            return hideContactMuteAndPinItems
        case .background:
            return hideContactBackgroundItem
        case .block:
            return hideContactBlock
        case .clearChatHistory:
            return hideContactClearChatHistory
        case .delete:
            return hideContactDelete
        case .addFriend:
            return hideContactAddFriend
        default:
            return false
        }
    }
}
