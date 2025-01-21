import Foundation
import ImSDK_Plus
import TIMCommon
import TUICore

protocol TUIGroupManageDataProviderDelegate: AnyObject {
    func insertSections(_ sections: IndexSet, withRowAnimation animation: UITableView.RowAnimation)
    func reloadData()
    func showCoverViewWhenMuteAll(_ show: Bool)
    func insertRows(at indexPaths: [IndexPath], withRowAnimation animation: UITableView.RowAnimation)
    func reloadRows(at indexPaths: [IndexPath], withRowAnimation animation: UITableView.RowAnimation)
    func onError(_ code: Int, desc: String, operate: String)
}

class TUIGroupManageDataProvider: NSObject {
    var muteAll: Bool = false
    var groupID: String = ""
    var currentGroupTypeSupportSettingAdmin: Bool = false
    var currentGroupTypeSupportAddMemberOfBlocked: Bool = false
    weak var delegate: TUIGroupManageDataProviderDelegate?

    private var groupInfo: V2TIMGroupInfo?
    private var groupInfoDatasArray: [Any] = []
    private var muteMembersDataArray: [Any] = []
    var datas: [Any] {
        return [groupInfoDatasArray, muteMembersDataArray]
    }

    func loadData() {
        groupInfoDatasArray = []
        muteMembersDataArray = []

        V2TIMManager.sharedInstance().getGroupsInfo([groupID]) { [weak self] groupResultList in
            guard let self = self else { return }
            if let result = groupResultList?.first, result.resultCode == 0 {
                self.groupInfo = result.info
                self.setupGroupInfo(result.info)
                self.muteAll = result.info?.allMuted ?? false
                self.currentGroupTypeSupportSettingAdmin = self.canSupportSettingAdmin(at: result.info?.groupType ?? "")
                self.currentGroupTypeSupportAddMemberOfBlocked = self.canSupportAddMemberOfBlocked(at: result.info?.groupType ?? "")
            }
        } fail: { [weak self] _, _ in
            guard let self else { return }
            self.setupGroupInfo(nil)
        }

        loadMuteMembers()
    }

    private func loadMuteMembers() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.loadMuteMembers()
            }
            return
        }

        muteMembersDataArray.removeAll()
        delegate?.reloadData()

        let add = TUIMemberInfoCellData(identifier: "")
        add.avatar = TUISwift.tuiContactCommonBundleImage("icon_add")
        add.name = TUISwift.timCommonLocalizableString("TUIKitGroupAddShutupMember")
        add.style = .add
        muteMembersDataArray.append(add)

        delegate?.insertRows(at: [IndexPath(row: 0, section: 1)], withRowAnimation: .none)

        setupGroupMembers(seq: 0, first: true)
    }

    private func setupGroupMembers(seq: UInt64, first: Bool) {
        if seq == 0 && !first {
            return
        }

        V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_ALL.rawValue), nextSeq: 0) { [weak self] nextSeq, memberList in
            guard let self = self, let memberList = memberList else { return }
            var indexPaths: [IndexPath] = []
            for info in memberList {
                let muteUntil = info.muteUntil
                if muteUntil > UInt32(Date().timeIntervalSince1970) {
                    let member = TUIMemberInfoCellData(identifier: info.userID)
                    member.avatarUrl = info.faceURL
                    member.name = info.nameCard ?? info.nickName ?? info.userID

                    let exist = self.muteMembersDataArray.contains { ($0 as? TUIMemberInfoCellData)?.identifier == info.userID }
                    let isSuper = info.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
                    let isAdmin = info.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue
                    let allowShowInMuteList = !(isSuper || isAdmin)

                    if !exist && allowShowInMuteList {
                        self.muteMembersDataArray.append(member)
                        indexPaths.append(IndexPath(row: self.muteMembersDataArray.count - 1, section: 1))
                    }
                }
            }

            if !indexPaths.isEmpty {
                self.delegate?.insertRows(at: indexPaths, withRowAnimation: .fade)
            }

            self.setupGroupMembers(seq: nextSeq, first: false)
        } fail: { _, _ in
            // Handle failure
        }
    }

    private func setupGroupInfo(_ groupInfo: V2TIMGroupInfo?) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.setupGroupInfo(groupInfo)
            }
            return
        }

        guard let groupInfo = groupInfo else { return }
        groupInfoDatasArray.removeAll()

        let adminSetting = TUICommonTextCellData()
        adminSetting.key = TUISwift.timCommonLocalizableString("TUIKitGroupManageAdminSetting")
        adminSetting.value = ""
        adminSetting.showAccessory = true
        adminSetting.cselector = #selector(onSettingAdmin(_:))
        groupInfoDatasArray.append(adminSetting)

        let shutupAll = TUICommonSwitchCellData()
        shutupAll.title = TUISwift.timCommonLocalizableString("TUIKitGroupManageShutAll")
        shutupAll.isOn = groupInfo.allMuted
        shutupAll.cswitchSelector = #selector(onMutedAll(_:))
        groupInfoDatasArray.append(shutupAll)

        delegate?.reloadData()
    }

    @objc func onSettingAdmin(_ textData: TUICommonTextCellData) {}

    @objc func onMutedAll(_ switchCell: TUICommonSwitchCell) {}

    func mutedAll(_ mute: Bool, completion: ((Int, String?) -> Void)?) {
        let groupInfo = V2TIMGroupInfo()
        groupInfo.groupID = groupID
        groupInfo.allMuted = mute

        V2TIMManager.sharedInstance().setGroupInfo(groupInfo) { [weak self] in
            guard let self = self else { return }
            self.muteAll = mute
            self.groupInfo?.allMuted = mute
            self.setupGroupInfo(self.groupInfo)
            completion?(0, nil)
        } fail: { [weak self] code, desc in
            self?.muteAll = !mute
            completion?(Int(code), desc)
        }
    }

    func mute(_ mute: Bool, user: TUIUserModel) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.mute(mute, user: user)
            }
            return
        }

        let callback: (Int, String?, Bool) -> Void = { [weak self] code, desc, mute in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var existData: TUIMemberInfoCellData?
                for data in self.muteMembersDataArray {
                    if let data = data as? TUIMemberInfoCellData, data.identifier == user.userId {
                        existData = data
                        break
                    }
                }

                if code == 0 && mute {
                    if existData == nil {
                        let cellData = TUIMemberInfoCellData(identifier: user.userId)
                        cellData.name = user.name
                        cellData.avatarUrl = user.avatar
                        self.muteMembersDataArray.append(cellData)
                    }
                } else if code == 0 && !mute {
                    if let existData = existData {
                        self.muteMembersDataArray.removeAll { $0 as? TUIMemberInfoCellData == existData }
                    }
                } else {
                    self.delegate?.onError(code, desc: desc ?? "", operate: mute ? TUISwift.timCommonLocalizableString("TUIKitGroupShutupOption") : TUISwift.timCommonLocalizableString("TUIKitGroupDisShutupOption"))
                }

                self.delegate?.reloadData()
            }
        }

        V2TIMManager.sharedInstance().muteGroupMember(groupID, member: user.userId, muteTime: mute ? 365 * 24 * 3600 : 0) {
            callback(0, nil, mute)
        } fail: { code, desc in
            callback(Int(code), desc, mute)
        }
    }

    func updateMuteMembersFilterAdmins() {
        loadMuteMembers()
    }

    private func canSupportSettingAdmin(at groupType: String) -> Bool {
        return groupType != "Work" && groupType != "AVChatRoom"
    }

    private func canSupportAddMemberOfBlocked(at groupType: String) -> Bool {
        return groupType != "Work"
    }
}
