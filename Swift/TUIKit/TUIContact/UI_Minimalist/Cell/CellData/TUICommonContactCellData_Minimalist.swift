//  TUICommonContactCellData_Minimalist.swift
//  TUIContact

import Foundation
import TIMCommon

enum TUIContactOnlineStatus_Minimalist: Int {
    case unknown = 0
    case online = 1
    case offline = 2
}

class TUICommonContactCellData_Minimalist: TUICommonCellData {
    var friendProfile: V2TIMFriendInfo?
    var identifier: String
    var avatarUrl: URL?
    var title: String?
    var avatarImage: UIImage?
    var userID: String?
    var groupID: String?
    var groupType: String?
    @objc dynamic var faceUrl: String?
    var onlineStatus: TUIContactOnlineStatus_Minimalist = .unknown

    init(friend: V2TIMFriendInfo) {
        if let friendRemark = friend.friendRemark, !friendRemark.isEmpty {
            self.title = friendRemark
        } else {
            if let info = friend.userFullInfo {
                self.title = info.showName()
            }
        }
        self.identifier = friend.userID.safeValue
        if let info = friend.userFullInfo {
            self.avatarUrl = URL(string: info.faceURL.safeValue)
            self.faceUrl = info.faceURL.safeValue
        }

        self.friendProfile = friend
        self.userID = friend.userID

        super.init()
    }

    init(groupInfo: V2TIMGroupInfo) {
        self.title = groupInfo.groupName.safeValue
        self.avatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType.safeValue)
        self.avatarUrl = URL(string: groupInfo.faceURL.safeValue)
        self.identifier = groupInfo.groupID.safeValue
        self.groupID = groupInfo.groupID.safeValue
        self.groupType = groupInfo.groupType.safeValue
        self.faceUrl = groupInfo.faceURL.safeValue
        super.init()
    }

    func compare(to data: TUICommonContactCellData_Minimalist) -> ComparisonResult {
        if let title = title, let dataTitle = data.title {
            return title.localizedCompare(dataTitle)
        }
        return .orderedSame
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return 56
    }
}
