import ImSDK_Plus
import TIMCommon

enum TUIConversationOnlineStatus: Int {
    case unknown = 0
    case online = 1
    case offline = 2
}

public class TUIConversationCellData: TUICommonCellData {
    var conversationID: String!
    var groupID: String?
    var groupType: String?
    var userID: String?
    var avatarImage: UIImage?
    var draftText: String?
    var unreadCount: Int = 0
    var subTitle: NSMutableAttributedString?
    var atTipsStr: String?
    var atMsgSeqs: [NSNumber]?
    var time: Date?
    var isOnTop: Bool = false
    var showCheckBox: Bool = false
    var disableSelected: Bool = false
    var selected: Bool = false
    var isLiteMode: Bool = false
    var isNotDisturb: Bool = false
    var orderKey: UInt = 0
    var conversationGroupList: [String]?
    var conversationMarkList: [NSNumber]?
    var onlineStatus: TUIConversationOnlineStatus = .unknown
    var isMarkAsUnread: Bool = false
    var isMarkAsHide: Bool = false
    var isMarkAsFolded: Bool = false
    var isLocalConversationFoldList: Bool = false
    var foldSubTitle: NSMutableAttributedString?
    var lastMessage: V2TIMMessage?
    var innerConversation: V2TIMConversation?

    var title: Observable<String> = Observable("")
    var faceUrl: Observable<String> = Observable("")

    override public required init() {
        super.init()
    }

    class func isMarkedByHideType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num == NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_HIDE.rawValue) {
                return true
            }
        }
        return false
    }

    class func isMarkedByUnReadType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num == NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_UNREAD.rawValue) {
                return true
            }
        }
        return false
    }

    class func isMarkedByFoldType(_ markList: [NSNumber]?) -> Bool {
        guard let markList = markList else { return false }
        for num in markList {
            if num == NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_FOLD.rawValue) {
                return true
            }
        }
        return false
    }

    override public func height(ofWidth width: CGFloat) -> CGFloat {
        return CGFloat(isLiteMode ? TConversationCell_Height_LiteMode : TConversationCell_Height)
    }
}
