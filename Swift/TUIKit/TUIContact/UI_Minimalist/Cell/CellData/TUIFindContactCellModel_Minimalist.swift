//  TUIFindContactCellModel_Minimalist.swift
//  TUIContact

import Foundation
import UIKit
import ImSDK_Plus

enum TUIFindContactType_Minimalist: Int {
    case C2C_Minimalist = 1
    case Group_Minimalist = 2
}

class TUIFindContactCellModel_Minimalist : NSObject {
    
    var type: TUIFindContactType_Minimalist?
    var avatar: UIImage?
    var avatarUrl: URL?
    var mainTitle: String?
    var subTitle: String?
    var desc: String?
    
    /**
     * c2c-> userID,   group->groupID
     * If the conversation type is c2c, contactID represents userid; if the conversation type is group, contactID represents groupID
     */
    var contactID: String?
    var userInfo: V2TIMUserFullInfo?
    var groupInfo: V2TIMGroupInfo?
    
    var onClick: ((TUIFindContactCellModel_Minimalist) -> Void)?
    
    override init() {
        super.init()
    }
    
    init(type: TUIFindContactType_Minimalist, avatar: UIImage? = nil, avatarUrl: URL? = nil, mainTitle: String? = nil, subTitle: String? = nil, desc: String? = nil, contactID: String? = nil, userInfo: V2TIMUserFullInfo? = nil, groupInfo: V2TIMGroupInfo? = nil, onClick: ((TUIFindContactCellModel_Minimalist) -> Void)? = nil) {
        self.type = type
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.mainTitle = mainTitle
        self.subTitle = subTitle
        self.desc = desc
        self.contactID = contactID
        self.userInfo = userInfo
        self.groupInfo = groupInfo
        self.onClick = onClick
    }
}
