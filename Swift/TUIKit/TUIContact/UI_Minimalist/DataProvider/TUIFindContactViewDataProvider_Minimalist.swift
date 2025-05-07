//  TUIFindContactViewDataProvider_Minimalist.swift
//  TUIContact

import Foundation
import TIMCommon

class TUIFindContactViewDataProvider_Minimalist {
    private(set) var users: [TUIFindContactCellModel_Minimalist] = []
    private(set) var groups: [TUIFindContactCellModel_Minimalist] = []

    func findUser(userID: String?, completion: @escaping () -> Void) {
        guard let userID = userID else {
            users = []
            completion()
            return
        }

        V2TIMManager.sharedInstance().getUsersInfo([userID], succ: { [weak self] infoList in
            guard let self = self, let infoList = infoList else { return }
            if let userInfo = infoList.first {
                let cellModel = TUIFindContactCellModel_Minimalist()
                cellModel.avatarUrl = URL(string: userInfo.faceURL ?? "")
                cellModel.mainTitle = userInfo.nickName ?? userInfo.userID
                cellModel.subTitle = userInfo.userID
                cellModel.desc = ""
                cellModel.type = .C2C_Minimalist
                cellModel.contactID = userInfo.userID
                cellModel.userInfo = userInfo
                self.users = [cellModel]
            }
            completion()
        }, fail: { [weak self] _, _ in
            guard let self = self else { return }
            self.users = []
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
            guard let self = self else { return }
            if let result = groupResultList?.first, let info = result.info, result.resultCode == 0 {
                let cellModel = TUIFindContactCellModel_Minimalist()
                cellModel.avatarUrl = URL(string: info.faceURL ?? "")
                cellModel.mainTitle = info.groupName
                cellModel.subTitle = info.groupID
                cellModel.desc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileType") + (info.groupType ?? "")
                cellModel.type = .Group_Minimalist
                cellModel.contactID = info.groupID
                cellModel.groupInfo = info
                self.groups = [cellModel]
            } else {
                self.groups = []
            }
            completion()
        }, fail: { [weak self] _, _ in
            guard let self = self else { return }
            self.groups = []
            completion()
        })
    }

    func getMyUserIDDescription() -> String {
        if let loginUser = V2TIMManager.sharedInstance().getLoginUser() {
            return String(format: TUISwift.timCommonLocalizableString("TUIKitAddContactMyUserIDFormat"), loginUser)
        }
        return ""
    }

    func clear() {
        users = []
        groups = []
    }
}
