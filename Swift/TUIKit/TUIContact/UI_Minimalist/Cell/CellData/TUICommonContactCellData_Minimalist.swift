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
    var identifier: String = ""
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
        if let userID = friend.userID {
            self.identifier = userID
        }
        if let info = friend.userFullInfo {
            self.avatarUrl = URL(string: info.faceURL ?? "")
            self.faceUrl = info.faceURL
        }
        self.friendProfile = friend
        self.userID = friend.userID

        super.init()
    }

    init(groupInfo: V2TIMGroupInfo) {
        self.title = groupInfo.groupName
        self.avatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType)
        self.avatarUrl = URL(string: groupInfo.faceURL ?? "")
        self.identifier = groupInfo.groupID ?? ""
        self.groupID = groupInfo.groupID
        self.groupType = groupInfo.groupType
        self.faceUrl = groupInfo.faceURL
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
