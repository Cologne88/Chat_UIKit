import Foundation

public struct TUIContactConfigItem: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = TUIContactConfigItem([])
    public static let alias = TUIContactConfigItem(rawValue: 1 << 0)
    public static let muteAndPin = TUIContactConfigItem(rawValue: 1 << 1)
    public static let background = TUIContactConfigItem(rawValue: 1 << 2)
    public static let block = TUIContactConfigItem(rawValue: 1 << 3)
    public static let clearChatHistory = TUIContactConfigItem(rawValue: 1 << 4)
    public static let delete = TUIContactConfigItem(rawValue: 1 << 5)
    public static let addFriend = TUIContactConfigItem(rawValue: 1 << 6)
}

public class TUIContactConfig {
    static let shared = TUIContactConfig()

    private var hideContactAlias: Bool = false
    private var hideContactMuteAndPinItems: Bool = false
    private var hideContactBackgroundItem: Bool = false
    private var hideContactBlock: Bool = false
    private var hideContactClearChatHistory: Bool = false
    private var hideContactDelete: Bool = false
    private var hideContactAddFriend: Bool = false
    
    private init() {}

    /**
     * Hide items in contact config interface.
     */
    public func hideItemsInContactConfig(_ items: TUIContactConfigItem) {
        hideContactAlias = items.contains(.alias)
        hideContactMuteAndPinItems = items.contains(.muteAndPin)
        hideContactBackgroundItem = items.contains(.background)
        hideContactBlock = items.contains(.block)
        hideContactClearChatHistory = items.contains(.clearChatHistory)
        hideContactDelete = items.contains(.delete)
        hideContactAddFriend = items.contains(.addFriend)
    }

    /**
     * Get the hidden status of specified item.
     */
    public func isItemHiddenInContactConfig(_ item: TUIContactConfigItem) -> Bool {
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
