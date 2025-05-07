import Foundation
import ImSDK_Plus

class TUIGroupNoticeDataProvider: NSObject {
    var groupInfo: V2TIMGroupInfo?
    var groupID: String?

    func getGroupInfo(callback: (() -> Void)?) {
        if let groupInfo = groupInfo, groupInfo.groupID == groupID {
            callback?()
            return
        }

        guard let groupID = groupID else {
            callback?()
            return
        }

        V2TIMManager.sharedInstance().getGroupsInfo([groupID]) { [weak self] groupResultList in
            guard let self else { return }
            if let result = groupResultList?.first, result.resultCode == 0 {
                self.groupInfo = result.info
            }
            callback?()
        } fail: { _, _ in
            callback?()
        }
    }

    func canEditNotice() -> Bool {
        guard let role = groupInfo?.role else { return false }
        return role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue || role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
    }

    func updateNotice(_ notice: String, callback: ((Int, String?) -> Void)?) {
        guard let groupID = groupID else {
            callback?(1, "Group ID is nil")
            return
        }

        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.notification = notice

        V2TIMManager.sharedInstance().setGroupInfo(info: info) { [weak self] in
            callback?(0, nil)
            self?.sendNoticeMessage(notice)
        } fail: { code, desc in
            callback?(Int(code), desc ?? "")
        }
    }

    private func sendNoticeMessage(_ notice: String) {
        guard !notice.isEmpty else { return }
        // Implement the logic to send a notice message if needed
    }
}
