import ImSDK_Plus
import TIMCommon

public enum TUIConversationOnlineStatus: Int {
    case unknown = 0
    case online = 1
    case offline = 2
}

public class TUIConversationCellData: TUICommonCellData {
    public var conversationID: String!
    public var groupID: String?
    public var groupType: String?
    public var userID: String?
    public var avatarImage: UIImage?
    public var draftText: String?
    public var unreadCount: Int = 0
    public var subTitle: NSMutableAttributedString?
    public var atTipsStr: String?
    public var atMsgSeqs: [NSNumber]?
    public var time: Date?
    public var isOnTop: Bool = false
    public var showCheckBox: Bool = false
    public var disableSelected: Bool = false
    public var selected: Bool = false
    public var isLiteMode: Bool = false
    public var isNotDisturb: Bool = false
    public var orderKey: UInt = 0
    public var conversationGroupList: [String]?
    public var conversationMarkList: [NSNumber]?
    public var onlineStatus: TUIConversationOnlineStatus = .unknown
    public var isMarkAsUnread: Bool = false
    public var isMarkAsHide: Bool = false
    public var isMarkAsFolded: Bool = false
    public var isLocalConversationFoldList: Bool = false
    public var foldSubTitle: NSMutableAttributedString?
    public var lastMessage: V2TIMMessage?
    public var innerConversation: V2TIMConversation?

    @objc public dynamic var title: String?
    @objc public dynamic var faceUrl: String?

    override public required init() {
        super.init()
    }

    public class func isMarkedByHideType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num.intValue == V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_HIDE.rawValue {
                return true
            }
        }
        return false
    }

    public class func isMarkedByUnReadType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num.intValue == V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_UNREAD.rawValue {
                return true
            }
        }
        return false
    }

    class func isMarkedByFoldType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num.intValue == V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_FOLD.rawValue {
                return true
            }
        }
        return false
    }

    override public func height(ofWidth width: CGFloat) -> CGFloat {
        return CGFloat(isLiteMode ? TConversationCell_Height_LiteMode : TConversationCell_Height)
    }
}
