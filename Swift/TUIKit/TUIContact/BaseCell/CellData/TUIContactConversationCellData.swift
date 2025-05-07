import TIMCommon
import UIKit

class TUIContactConversationCellData: TUICommonCellData {
    var conversationID: String?
    var groupID: String?
    var groupType: String?
    var userID: String?
    var title: String?
    var faceUrl: String?
    var avatarImage: UIImage?
    var draftText: String?

    // Conversation Messages Overview (subtitle)
    // The overview is responsible for displaying the content/type of the latest message for the corresponding conversation.
    // When the latest message is a text message/system message, the content of the overview is the text content of the message.
    // When the latest message is a multimedia message, the content of the overview is the name of the corresponding multimedia form, such as: "Animation
    // Expression" / "[File]" / "[Voice]" / "[Picture]" / "[Video]", etc. . If there is a draft in the current conversation, the overview content is:
    // "[Draft]XXXXX", where XXXXX is the draft content.
    var subTitle: NSMutableAttributedString?

    // seq list of group@ messages
    var atMsgSeqs: [NSNumber] = []

    // Latest message time
    // Save the receive/send time of the latest message in the conversation.
    var time: Date?

    // The flag that whether the conversation is pinned to the top
    var isOnTop: Bool = false

    // Indicates whether to display the message checkbox
    // In the conversation list, the message checkbox is not displayed by default.
    // In the message forwarding scenario, the list cell is multiplexed to the select conversation page. When the "Multiple Choice" button is clicked, the
    // conversation list becomes multi-selectable. YES: Multiple selection is enable, multiple selection views are displayed; NO: Multiple selection is disable, the
    // default view is displayed
    var showCheckBox: Bool = false

    // Indicates whether the current message is selected, the default is NO
    var selected: Bool = false

    // Whether the current conversation is marked as do-not-disturb for new messages
    var isNotDisturb: Bool = false

    // key by which to sort the conversation list
    var orderKey: UInt = 0

    override init() {
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return CGFloat(TConversationCell_Height)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TUIContactConversationCellData else { return false }
        return self.conversationID == object.conversationID
    }
}
