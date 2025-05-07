import SDWebImage
import UIKit

public extension TUIGroupAvatar {
    static func getNormalGroupCacheAvatar(groupID: String, groupType: String?) -> UIImage? {
        var avatarImage: UIImage?
        if !groupID.isEmpty {
            var avatar: UIImage?
            if TUIConfig.default().enableGroupGridAvatar {
                let key = "TUIConversationLastGroupMember_\(groupID)"
                let member = UserDefaults.standard.integer(forKey: key)
                avatar = TUIGroupAvatar.getCacheAvatar(forGroup: groupID, number: UInt32(member))
            }
            avatarImage = avatar ?? TUISwift.defaultGroupAvatarImage(byGroupType: groupType)
        }
        return avatarImage
    }

    static func configAvatar(by param: [String: Any], targetView: UIImageView) {
        let groupID = param["groupID"] as? String
        let faceUrl = param["faceUrl"] as? String
        let groupType = param["groupType"] as? String
        let originAvatarImage = param["originAvatarImage"] as? UIImage

        if let groupID = groupID, !groupID.isEmpty {
            if let faceUrl = faceUrl, !faceUrl.isEmpty {
                targetView.sd_setImage(with: URL(string: faceUrl), placeholderImage: originAvatarImage)
            } else {
                if TUIConfig.default().enableGroupGridAvatar {
                    targetView.sd_setImage(with: nil, placeholderImage: originAvatarImage)
                    TUIGroupAvatar.getCacheGroupAvatar(groupID) { avatar, groupID in
                        if groupID == groupID {
                            let avatar: UIImage? = avatar
                            if let avatar = avatar {
                                targetView.sd_setImage(with: nil, placeholderImage: avatar)
                            } else {
                                targetView.sd_setImage(with: nil, placeholderImage: originAvatarImage)
                                TUIGroupAvatar.fetchGroupAvatars(groupID, placeholder: originAvatarImage ?? UIImage()) { success, image, _ in
                                    targetView.sd_setImage(with: nil, placeholderImage: success ? image : TUISwift.defaultGroupAvatarImage(byGroupType: groupType))
                                }
                            }
                        }
                    }
                } else {
                    targetView.sd_setImage(with: nil, placeholderImage: originAvatarImage)
                }
            }
        } else {
            if let faceUrl = faceUrl {
                targetView.sd_setImage(with: URL(string: faceUrl), placeholderImage: originAvatarImage ?? UIImage())
            }
        }
    }
}
