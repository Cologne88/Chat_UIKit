import Foundation
import TIMCommon

class TUISettingAdminDataProvider: NSObject {
    var groupID: String?

    private(set) var owners: [TUIMemberInfoCellData] = []
    private(set) var admins: [TUIMemberInfoCellData] = []
    var datas: [[TUIMemberInfoCellData]] {
        return [owners, admins]
    }

    func loadData(callback: @escaping (Int, String?) -> Void) {
        let add = TUIMemberInfoCellData(identifier: "")
        add.style = .add
        add.name = TUISwift.timCommonLocalizableString("TUIKitGroupAddAdmins")
        add.avatar = TUISwift.tuiContactCommonBundleImage("icon_add")
        admins.append(add)

        var errorCode = 0
        var errorMsg: String? = nil

        guard let groupID = groupID else { return }

        let group = DispatchGroup()
        group.enter()

        V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_OWNER.rawValue), nextSeq: 0, succ: { [weak self] _, memberList in
            guard let self, let memberList = memberList else { return }
            for info in memberList {
                let cellData = TUIMemberInfoCellData(identifier: info.userID)
                cellData.name = (info.nameCard ?? info.nickName) ?? info.userID
                cellData.avatarUrl = info.faceURL
                if info.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue) {
                    self.owners.append(cellData)
                }
            }
            group.leave()
        }, fail: { code, desc in
            if errorCode == 0 {
                errorCode = Int(code)
                errorMsg = desc
            }
            group.leave()
        })

        group.enter()
        V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_ADMIN.rawValue), nextSeq: 0, succ: { [weak self] _, memberList in
            guard let self, let memberList = memberList else { return }
            for info in memberList {
                let cellData = TUIMemberInfoCellData(identifier: info.userID)
                cellData.name = (info.nameCard ?? info.nickName) ?? info.userID
                cellData.avatarUrl = info.faceURL
                if info.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue) {
                    self.admins.append(cellData)
                }
            }
            group.leave()
        }, fail: { code, desc in
            if errorCode == 0 {
                errorCode = Int(code)
                errorMsg = desc
            }
            group.leave()
        })

        group.notify(queue: .main) {
            callback(errorCode, errorMsg)
        }
    }

    func removeAdmin(userID: String, callback: @escaping (Int, String?) -> Void) {
        guard let groupID = groupID else { return }
        V2TIMManager.sharedInstance().setGroupMemberRole(groupID: groupID, memberUserID: userID, newRole: UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_MEMBER.rawValue), succ: { [weak self] in
            guard let self else { return }
            if let exist = self.existAdmin(userID: userID) {
                self.admins.removeAll { $0 as NSObject == exist }
            }
            callback(0, nil)
        }, fail: { code, desc in
            callback(Int(code), desc)
        })
    }

    func settingAdmins(userModels: [TUIUserModel], callback: @escaping (Int, String?) -> Void) {
        var validUsers: [TUIMemberInfoCellData] = []
        for user in userModels {
            if existAdmin(userID: user.userId) == nil {
                let data = TUIMemberInfoCellData(identifier: user.userId)
                data.name = user.name
                data.avatarUrl = user.avatar
                validUsers.append(data)
            }
        }

        if validUsers.isEmpty {
            callback(0, nil)
            return
        }

        if admins.count + validUsers.count > 11 {
            callback(-1, "The number of administrator must be less than ten")
            return
        }

        var errorCode = 0
        var errorMsg: String? = nil
        var results: [TUIMemberInfoCellData] = []

        guard let groupID = groupID else { return }

        let group = DispatchGroup()
        for data in validUsers {
            guard let identifier = data.identifier else { continue }
            group.enter()
            V2TIMManager.sharedInstance().setGroupMemberRole(groupID: groupID, memberUserID: identifier, newRole: UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue), succ: {
                results.append(data)
                group.leave()
            }, fail: { code, desc in
                if errorCode == 0 {
                    errorCode = Int(code)
                    errorMsg = desc
                }
                group.leave()
            })
        }

        weak var weakSelf = self
        group.notify(queue: .main) {
            weakSelf?.admins.append(contentsOf: results)
            callback(errorCode, errorMsg)
        }
    }

    private func existAdmin(userID: String) -> TUIMemberInfoCellData? {
        var exist: TUIMemberInfoCellData? = nil
        for data in admins {
            if data.identifier == userID {
                exist = data
                break
            }
        }
        return exist
    }
}
