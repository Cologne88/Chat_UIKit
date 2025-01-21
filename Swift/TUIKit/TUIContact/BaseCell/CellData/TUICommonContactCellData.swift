import Foundation
import TIMCommon

enum TUIContactOnlineStatus: Int {
    case unknown = 0
    case online = 1
    case offline = 2
}

class TUICommonContactCellData: TUICommonCellData {
    var friendProfile: V2TIMFriendInfo?
    var identifier: String?
    var avatarUrl: URL?
    var title: String?
    var avatarImage: UIImage?
    var onlineStatus: TUIContactOnlineStatus = .unknown

    init(friend: V2TIMFriendInfo) {
        super.init()

        if let friendRemark = friend.friendRemark, !friendRemark.isEmpty {
            title = friendRemark
        } else {
            title = friend.userFullInfo?.showName()
        }

        identifier = friend.userID
        if let faceURL = friend.userFullInfo?.faceURL {
            avatarUrl = URL(string: faceURL)
        }
        friendProfile = friend
    }

    init(groupInfo: V2TIMGroupInfo) {
        super.init()

        title = groupInfo.groupName
        avatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType)
        if let faceURL = groupInfo.faceURL {
            avatarUrl = URL(string: faceURL)
        }
        identifier = groupInfo.groupID
    }

    func compare(to data: TUICommonContactCellData) -> ComparisonResult {
        return (title ?? "").localizedCompare(data.title ?? "")
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return 56
    }
}
