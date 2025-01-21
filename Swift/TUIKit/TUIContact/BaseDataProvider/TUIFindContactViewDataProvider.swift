import Foundation
import ImSDK_Plus
import TIMCommon
import TUICore

class TUIFindContactViewDataProvider: NSObject {
    private(set) var users: [TUIFindContactCellModel] = []
    private(set) var groups: [TUIFindContactCellModel] = []

    func findUser(userID: String?, completion: @escaping () -> Void) {
        guard let userID = userID else {
            users = []
            completion()
            return
        }

        V2TIMManager.sharedInstance().getUsersInfo([userID], succ: { [weak self] infoList in
            guard let self else { return }
            if let userInfo = infoList?.first {
                let cellModel = TUIFindContactCellModel(type: TUIFindContactType.c2c)
                if let faceUrl = userInfo.faceURL {
                    cellModel.avatarUrl = URL(string: faceUrl) ?? URL(string: "")
                }
                cellModel.mainTitle = userInfo.nickName ?? userInfo.userID
                if let userID = userInfo.userID {
                    cellModel.subTitle = "ID: \(userID)"
                }
                cellModel.desc = ""
                cellModel.type = TUIFindContactType.c2c
                cellModel.contactID = userInfo.userID
                cellModel.userInfo = userInfo
                self.users = [cellModel]
            }
            completion()
        }, fail: { [weak self] _, _ in
            self?.users = []
            completion()
        })
    }

    func findGroup(groupID: String?, completion: @escaping () -> Void) {
        guard let groupID = groupID else {
            groups = []
            completion()
            return
        }

        V2TIMManager.sharedInstance().getGroupsInfo([groupID], succ: { [weak self] groupResultList in
            guard let self else { return }
            if let result = groupResultList?.first, result.resultCode == 0 {
                let info = result.info
                let cellModel = TUIFindContactCellModel(type: TUIFindContactType.c2c)
                if let faceUrl = info?.faceURL {
                    cellModel.avatarUrl = URL(string: faceUrl)
                }
                cellModel.mainTitle = info?.groupName
                cellModel.subTitle = "ID: \(info?.groupID ?? "")"
                cellModel.desc = "\(TUISwift.timCommonLocalizableString("TUIKitGroupProfileType") ?? ""): \(info?.groupType ?? "")"
                cellModel.type = TUIFindContactType.group
                cellModel.contactID = info?.groupID
                cellModel.groupInfo = info
                self.groups = [cellModel]
            } else {
                self.groups = []
            }
            completion()
        }, fail: { [weak self] _, _ in
            guard let self else { return }
            self.groups = []
            completion()
        })
    }

    func getMyUserIDDescription() -> String {
        guard let loginUser = V2TIMManager.sharedInstance().getLoginUser() else { return "" }
        return String(format: TUISwift.timCommonLocalizableString("TUIKitAddContactMyUserIDFormat"), loginUser)
    }

    func clear() {
        users = []
        groups = []
    }
}
