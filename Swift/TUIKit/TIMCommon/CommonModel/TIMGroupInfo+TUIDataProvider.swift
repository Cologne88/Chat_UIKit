import Foundation
import ImSDK_Plus

public extension V2TIMGroupInfo {
    func isMeOwner() -> Bool {
        return self.owner == V2TIMManager.sharedInstance().getLoginUser() || self.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue
    }
    
    func isPrivate() -> Bool {
        return self.groupType == "Work"
    }
    
    func canInviteMember() -> Bool {
        return self.groupApproveOpt != .GROUP_ADD_FORBID
    }
    
    func canRemoveMember() -> Bool {
        return self.isMeOwner() && self.memberCount > 1
    }
    
    func canDismissGroup() -> Bool {
        if self.isPrivate() {
            return false
        } else {
            return self.owner == V2TIMManager.sharedInstance().getLoginUser() || self.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
        }
    }
    
    func canSupportSetAdmain() -> Bool {
        let isMeSuper = self.owner == V2TIMManager.sharedInstance().getLoginUser() || self.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
        let isCurrentGroupTypeSupportSetAdmain = ["Public", "Meeting", "Community", "Private"].contains(self.groupType)
        return isMeSuper && isCurrentGroupTypeSupportSetAdmain && self.memberCount > 1
    }
}
