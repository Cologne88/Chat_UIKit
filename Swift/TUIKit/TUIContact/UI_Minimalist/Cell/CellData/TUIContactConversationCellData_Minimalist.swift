//  TUIContactConversationCellData_Minimalist.swift
//  TUIContact

import TIMCommon

class TUIContactConversationCellData_Minimalist: TUICommonCellData {

    var conversationID: String
    var groupID: String
    var groupType: String
    var userID: String
    var title: String
    var faceUrl: String
    var avatarImage: UIImage
    var draftText: String
    var unreadCount: Int = 0
    var subTitle: NSMutableAttributedString
    var atMsgSeqs: [NSNumber]
    var time: Date
    var isOnTop: Bool = false
    var showCheckBox: Bool = false
    var selected: Bool = false
    var isNotDisturb: Bool = false
    var orderKey: UInt = 0

    init(conversationID: String, groupID: String, groupType: String, userID: String, title: String, faceUrl: String, avatarImage: UIImage, draftText: String, subTitle: NSMutableAttributedString, atMsgSeqs: [NSNumber], time: Date) {
        self.conversationID = conversationID
        self.groupID = groupID
        self.groupType = groupType
        self.userID = userID
        self.title = title
        self.faceUrl = faceUrl
        self.avatarImage = avatarImage
        self.draftText = draftText
        self.subTitle = subTitle
        self.atMsgSeqs = atMsgSeqs
        self.time = time
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return CGFloat(TConversationCell_Height)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TUIContactConversationCellData_Minimalist else {
            return false
        }
        return self.conversationID == object.conversationID
    }
}
