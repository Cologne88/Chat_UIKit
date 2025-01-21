import Foundation
import TIMCommon
import TUICore

@objc protocol TUIGroupInfoDataProviderDelegate: NSObjectProtocol {
    @objc func pushNavigationController() -> UINavigationController?
    @objc func didSelectMembers()
    @objc func didSelectGroupNick(_ cell: TUICommonTextCell)
    @objc func didSelectAddOption(_ cell: UITableViewCell)
    @objc func didSelectCommon()
    @objc func didSelectOnNotDisturb(_ cell: TUICommonSwitchCell)
    @objc func didSelectOnTop(_ cell: TUICommonSwitchCell)
    @objc func didSelectOnFoldConversation(_ cell: TUICommonSwitchCell)
    @objc func didSelectOnChangeBackgroundImage(_ cell: TUICommonTextCell)
    @objc func didDeleteGroup(_ cell: TUIButtonCell)
    @objc func didClearAllHistory(_ cell: TUIButtonCell)
    @objc func didSelectGroupNotice()
}

class TUIGroupInfoDataProvider: NSObject, V2TIMGroupListener {
    var addOptionData: TUICommonTextCellData?
    var inviteOptionData: TUICommonTextCellData?
    var groupNickNameCellData: TUICommonTextCellData?
    var groupInfo: V2TIMGroupInfo?
    var membersData: [TUIGroupMemberCellData] = []
    var groupMembersCellData: TUIGroupMembersCellData?
    @objc dynamic var dataList: [[Any]] = []

    weak var delegate: TUIGroupInfoDataProviderDelegate?
    private(set) var profileCellData: TUIProfileCardCellData?
    private(set) var selfInfo: V2TIMGroupMemberFullInfo?
    private var groupID: String

    init(groupID: String) {
        self.groupID = groupID
        super.init()
        V2TIMManager.sharedInstance().addGroupListener(listener: self)
    }

    // MARK: - V2TIMGroupListener

    func onMemberEnter(_ groupID: String, memberList: [V2TIMGroupMemberInfo]) {
        loadData()
    }

    func onMemberLeave(_ groupID: String, member: V2TIMGroupMemberInfo) {
        loadData()
    }

    func onMemberInvited(_ groupID: String, opUser: V2TIMGroupMemberInfo, memberList: [V2TIMGroupMemberInfo]) {
        loadData()
    }

    func onMemberKicked(_ groupID: String, opUser: V2TIMGroupMemberInfo, memberList: [V2TIMGroupMemberInfo]) {
        loadData()
    }

    func onGroupInfoChanged(_ groupID: String, changeInfoList: [V2TIMGroupChangeInfo]) {
        guard groupID == self.groupID else { return }
        loadData()
    }

    func loadData() {
        guard !groupID.isEmpty else {
            TUITool.makeToastError(Int(ERR_INVALID_PARAMETERS.rawValue), msg: "invalid groupID")
            return
        }

        let group = DispatchGroup()
        group.enter()
        getGroupInfo {
            group.leave()
        }

        group.enter()
        getGroupMembers {
            group.leave()
        }

        group.enter()
        getSelfInfoInGroup {
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.setupData()
        }
    }

    func updateGroupInfo() {
        V2TIMManager.sharedInstance().getGroupsInfo([groupID]) { [weak self] groupResultList in
            guard let self = self, groupResultList?.count == 1 else { return }
            self.groupInfo = groupResultList?[0].info
            self.setupData()
        } fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
        }
    }

    func transferGroupOwner(_ groupID: String, member: String, succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        V2TIMManager.sharedInstance().transferGroupOwner(groupID, member: member, succ: succ, fail: fail)
    }

    func updateGroupAvatar(_ url: String, succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.faceURL = url
        V2TIMManager.sharedInstance().setGroupInfo(info, succ: succ, fail: fail)
    }

    private func getGroupInfo(callback: @escaping () -> Void) {
        V2TIMManager.sharedInstance().getGroupsInfo([groupID]) { [weak self] groupResultList in
            self?.groupInfo = groupResultList?.first?.info
            callback()
        } fail: { code, msg in
            callback()
            TUITool.makeToastError(Int(code), msg: msg)
        }
    }

    private func getGroupMembers(callback: @escaping () -> Void) {
        V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_ALL.rawValue), nextSeq: 0) { [weak self] _, memberList in
            guard let self, let memberList = memberList else { return }
            var members: [TUIGroupMemberCellData] = []
            for fullInfo in memberList {
                let data = TUIGroupMemberCellData()
                data.identifier = fullInfo.userID.safeValue
                data.name = fullInfo.userID.safeValue
                data.avatarUrl = fullInfo.faceURL.safeValue
                if !fullInfo.nameCard.isNilOrEmpty {
                    data.name = fullInfo.nameCard.safeValue
                } else if !fullInfo.friendRemark.isNilOrEmpty {
                    data.name = fullInfo.friendRemark.safeValue
                } else if !fullInfo.nickName.isNilOrEmpty {
                    data.name = fullInfo.nickName.safeValue
                }
                members.append(data)
            }
            self.membersData = members
            callback()
        } fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
            callback()
        }
    }

    private func getSelfInfoInGroup(callback: @escaping () -> Void) {
        guard let loginUserID = V2TIMManager.sharedInstance().getLoginUser(), !loginUserID.isEmpty else {
            callback()
            return
        }
        V2TIMManager.sharedInstance().getGroupMembersInfo(groupID, memberList: [loginUserID]) { [weak self] memberList in
            guard let self else { return }
            self.selfInfo = memberList?.first(where: { $0.userID == loginUserID })
            callback()
        } fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
            callback()
        }
    }

    private func setupData() {
        var dataList: [[Any]] = []
        if let groupInfo = groupInfo {
            var commonArray: [TUIProfileCardCellData] = []
            let commonData = TUIProfileCardCellData()
            commonData.avatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType.safeValue)
            commonData.avatarUrl = URL(string: groupInfo.faceURL.safeValue) ?? URL(fileURLWithPath: "")
            commonData.name = groupInfo.groupName.safeValue
            commonData.identifier = groupInfo.groupID.safeValue
            commonData.signature = groupInfo.notification.safeValue

            if TUIGroupInfoDataProvider.isMeOwner(groupInfo) || groupInfo.isPrivate() {
                commonData.cselector = #selector(didSelectCommon)
                commonData.showAccessory = true
            }
            profileCellData = commonData

            commonArray.append(commonData)
            dataList.append(commonArray)

            // Members
            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.members) {
                var memberArray: [Any] = []
                let countData = TUICommonTextCellData()
                countData.key = TUISwift.timCommonLocalizableString("TUIKitGroupProfileMember")
                countData.value = String(format: TUISwift.timCommonLocalizableString("TUIKitGroupProfileMemberCount"), groupInfo.memberCount)
                countData.cselector = #selector(didSelectMembers)
                countData.showAccessory = true
                memberArray.append(countData)

                let tmpArray = getShowMembers(membersData)
                let cellData = TUIGroupMembersCellData()
                cellData.members = NSMutableArray(array: tmpArray)
                memberArray.append(cellData)
                groupMembersCellData = cellData
                dataList.append(memberArray)
            }

            // Group Info
            var groupInfoArray: [Any] = []

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.notice) {
                let notice = TUIGroupNoticeCellData()
                notice.name = TUISwift.timCommonLocalizableString("TUIKitGroupNotice")
                notice.desc = groupInfo.notification ?? TUISwift.timCommonLocalizableString("TUIKitGroupNoticeNull")
                notice.target = self
                notice.selector = #selector(didSelectNotice)
                groupInfoArray.append(notice)
            }

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.members) {
                let param: [String: Any] = [
                    "pushVC": delegate?.pushNavigationController() as Any,
                    "groupID": groupID
                ]
                let extensionList = TUICore.getExtensionList(TUICore_TUIChatExtension_GroupProfileSettingsItemExtension_ClassicExtensionID, param: param)
                for info in extensionList {
                    if let text = info.text, let onClicked = info.onClicked {
                        let manageData = TUICommonTextCellData()
                        manageData.key = text
                        manageData.value = ""
                        manageData.tui_extValueObj = info
                        manageData.showAccessory = true
                        manageData.cselector = #selector(groupProfileExtensionButtonClick(_:))
                        if info.weight == 100 {
                            if TUIGroupInfoDataProvider.isMeOwner(groupInfo) {
                                groupInfoArray.append(manageData)
                            }
                        } else {
                            groupInfoArray.append(manageData)
                        }
                    }
                }
            }

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.manage) {
                let typeData = TUICommonTextCellData()
                typeData.key = TUISwift.timCommonLocalizableString("TUIKitGroupProfileType")
                typeData.value = TUIGroupInfoDataProvider.getGroupTypeName(groupInfo)
                groupInfoArray.append(typeData)

                let addOptionData = TUICommonTextCellData()
                addOptionData.key = TUISwift.timCommonLocalizableString("TUIKitGroupProfileJoinType")

                if groupInfo.groupType == "Work" {
                    addOptionData.value = TUISwift.timCommonLocalizableString("TUIKitGroupProfileInviteJoin")
                } else if groupInfo.groupType == "Meeting" {
                    addOptionData.value = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
                } else {
                    if TUIGroupInfoDataProvider.isMeOwner(groupInfo) {
                        addOptionData.cselector = #selector(didSelectAddOption(_:))
                        addOptionData.showAccessory = true
                    }
                    addOptionData.value = TUIGroupInfoDataProvider.getAddOption(groupInfo)
                }
                groupInfoArray.append(addOptionData)
                self.addOptionData = addOptionData

                let inviteOptionData = TUICommonTextCellData()
                inviteOptionData.key = TUISwift.timCommonLocalizableString("TUIKitGroupProfileInviteType")
                if TUIGroupInfoDataProvider.isMeOwner(groupInfo) {
                    inviteOptionData.cselector = #selector(didSelectAddOption(_:))
                    inviteOptionData.showAccessory = true
                }
                inviteOptionData.value = TUIGroupInfoDataProvider.getApproveOption(groupInfo)
                groupInfoArray.append(inviteOptionData)
                self.inviteOptionData = inviteOptionData
                dataList.append(groupInfoArray)
            }

            // Personal Info
            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.alias) {
                let nickData = TUICommonTextCellData()
                nickData.key = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAlias")
                nickData.value = selfInfo?.nameCard ?? ""
                nickData.cselector = #selector(didSelectGroupNick(_:))
                nickData.showAccessory = true
                groupNickNameCellData = nickData
                dataList.append([nickData])
            }

            let markFold = TUICommonSwitchCellData()
            let switchData = TUICommonSwitchCellData()
            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.muteAndPin) {
                var personalArray: [Any] = []

                let messageSwitchData = TUICommonSwitchCellData()
                if groupInfo.groupType != "Meeting" {
                    messageSwitchData.isOn = (groupInfo.recvOpt.rawValue == V2TIMReceiveMessageOpt.RECEIVE_NOT_NOTIFY_MESSAGE.rawValue)
                    messageSwitchData.title = TUISwift.timCommonLocalizableString("TUIKitGroupProfileMessageDoNotDisturb")
                    messageSwitchData.cswitchSelector = #selector(didSelectOnNotDisturb(_:))
                    personalArray.append(messageSwitchData)
                }

                markFold.title = TUISwift.timCommonLocalizableString("TUIKitConversationMarkFold")
                markFold.displaySeparatorLine = true
                markFold.cswitchSelector = #selector(didSelectOnFoldConversation(_:))
                if messageSwitchData.isOn {
                    personalArray.append(markFold)
                }

                switchData.title = TUISwift.timCommonLocalizableString("TUIKitGroupProfileStickyOnTop")
                personalArray.append(switchData)

                dataList.append(personalArray)
            }

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.background) {
                let changeBackgroundImageItem = TUICommonTextCellData()
                changeBackgroundImageItem.key = TUISwift.timCommonLocalizableString("ProfileSetBackgroundImage")
                changeBackgroundImageItem.cselector = #selector(didSelectOnChangeBackgroundImage(_:))
                changeBackgroundImageItem.showAccessory = true
                dataList.append([changeBackgroundImageItem])
            }

            var buttonArray: [TUIButtonCellData] = []
            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.clearChatHistory) {
                let clearHistory = TUIButtonCellData()
                clearHistory.title = TUISwift.timCommonLocalizableString("TUIKitClearAllChatHistory")
                clearHistory.style = .ButtonRedText
                clearHistory.cbuttonSelector = #selector(didClearAllHistory(_:))
                buttonArray.append(clearHistory)
            }

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.deleteAndLeave) {
                let quitButton = TUIButtonCellData()
                quitButton.title = TUISwift.timCommonLocalizableString("TUIKitGroupProfileDeleteAndExit")
                quitButton.style = .ButtonRedText
                quitButton.cbuttonSelector = #selector(didDeleteGroup(_:))
                buttonArray.append(quitButton)
            }

            if Self.isMeSuper(groupInfo) && !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.transfer) {
                var param: [String: Any] = [:]
                param["pushVC"] = delegate?.pushNavigationController()
                param["groupID"] = groupID.isEmpty ? "" : groupID
                let updateGroupInfoCallback: () -> Void = { [weak self] in
                    self?.updateGroupInfo()
                }
                param["updateGroupInfoCallback"] = updateGroupInfoCallback
                let extensionList = TUICore.getExtensionList(TUICore_TUIChatExtension_GroupProfileBottomItemExtension_ClassicExtensionID, param: param)
                for info in extensionList {
                    if let text = info.text, let onClicked = info.onClicked {
                        let transferButton = TUIButtonCellData()
                        transferButton.title = text
                        transferButton.style = .ButtonRedText
                        transferButton.tui_extValueObj = info
                        transferButton.cbuttonSelector = #selector(groupProfileExtensionButtonClick(_:))
                        buttonArray.append(transferButton)
                    }
                }
            }

            if groupInfo.canDismissGroup() && !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.dismiss) {
                let deleteButton = TUIButtonCellData()
                deleteButton.title = TUISwift.timCommonLocalizableString("TUIKitGroupProfileDissolve")
                deleteButton.style = .ButtonRedText
                deleteButton.cbuttonSelector = #selector(didDeleteGroup(_:))
                buttonArray.append(deleteButton)
            }

            if !TUIGroupConfig.shared.isItemHiddenInGroupConfig(.report) {
                let reportButton = TUIButtonCellData()
                reportButton.title = TUISwift.timCommonLocalizableString("TUIKitGroupProfileReport")
                reportButton.style = .ButtonRedText
                reportButton.cbuttonSelector = #selector(didReportGroup(_:))
                buttonArray.append(reportButton)
            }

            if let lastCellData = buttonArray.last {
                lastCellData.hideSeparatorLine = true
            }

            dataList.append(buttonArray)

            V2TIMManager.sharedInstance().getConversation("group_\(groupID)") { [weak self] conv in
                guard let self = self else { return }
                markFold.isOn = Self.isMarkedByFoldType(conv?.markList ?? [])
                switchData.cswitchSelector = #selector(self.didSelectOnTop(_:))
                switchData.isOn = conv?.isPinned ?? false
                if markFold.isOn {
                    switchData.isOn = false
                    switchData.disableChecked = true
                }
                self.dataList = dataList
            } fail: { _, desc in
                print("Failed to get conversation: \(desc ?? "")")
            }
        }
        self.dataList = dataList
    }

    @objc func groupProfileExtensionButtonClick(_ cell: TUICommonTextCell) {
        // Implemented through self.delegate, because of TUIButtonCellData cbuttonSelector mechanism
    }

    @objc func didSelectMembers() {
        delegate?.didSelectMembers()
    }

    @objc func didSelectGroupNick(_ cell: TUICommonTextCell) {
        delegate?.didSelectGroupNick(cell)
    }

    @objc func didSelectAddOption(_ cell: UITableViewCell) {
        delegate?.didSelectAddOption(cell)
    }

    @objc func didSelectCommon() {
        delegate?.didSelectCommon()
    }

    @objc func didSelectOnNotDisturb(_ cell: TUICommonSwitchCell) {
        delegate?.didSelectOnNotDisturb(cell)
    }

    @objc func didSelectOnTop(_ cell: TUICommonSwitchCell) {
        delegate?.didSelectOnTop(cell)
    }

    @objc func didSelectOnFoldConversation(_ cell: TUICommonSwitchCell) {
        delegate?.didSelectOnFoldConversation(cell)
    }

    @objc func didSelectOnChangeBackgroundImage(_ cell: TUICommonTextCell) {
        delegate?.didSelectOnChangeBackgroundImage(cell)
    }

    @objc func didDeleteGroup(_ cell: TUIButtonCell) {
        delegate?.didDeleteGroup(cell)
    }

    @objc func didClearAllHistory(_ cell: TUIButtonCell) {
        delegate?.didClearAllHistory(cell)
    }

    @objc func didSelectNotice() {
        delegate?.didSelectGroupNotice()
    }

    @objc func didReportGroup(_ cell: TUIButtonCell) {
        if let url = URL(string: "https://cloud.tencent.com/act/event/report-platform") {
            TUITool.openLink(with: url)
        }
    }

    private func getShowMembers(_ members: [TUIGroupMemberCellData]) -> [TUIGroupMemberCellData] {
        var maxCount = TGroupMembersCell_Column_Count * TGroupMembersCell_Row_Count
        if groupInfo?.canInviteMember() ?? false {
            maxCount -= 1
        }
        if groupInfo?.canRemoveMember() ?? false {
            maxCount -= 1
        }
        var tmpArray: [TUIGroupMemberCellData] = []
        for i in 0 ..< min(members.count, Int(maxCount)) {
            tmpArray.append(members[i])
        }
        if groupInfo?.canInviteMember() == true {
            let add = TUIGroupMemberCellData()
            add.avatarImage = TUISwift.tuiContactCommonBundleImage("add")
            add.tag = 1
            tmpArray.append(add)
        }
        if groupInfo?.canRemoveMember() == true {
            let delete = TUIGroupMemberCellData()
            delete.avatarImage = TUISwift.tuiContactCommonBundleImage("delete")
            delete.tag = 2
            tmpArray.append(delete)
        }
        return tmpArray
    }

    func setGroupAddOpt(_ opt: V2TIMGroupAddOpt) {
        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.groupAddOpt = opt

        V2TIMManager.sharedInstance().setGroupInfo(info) { [weak self] in
            guard let self else { return }
            self.groupInfo?.groupAddOpt = opt
            self.addOptionData?.value = TUIGroupInfoDataProvider.getAddOptionWithV2AddOpt(opt)
        } fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        }
    }

    func setGroupApproveOpt(_ opt: V2TIMGroupAddOpt) {
        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.groupApproveOpt = opt

        V2TIMManager.sharedInstance().setGroupInfo(info) { [weak self] in
            guard let self else { return }
            self.groupInfo?.groupApproveOpt = opt
            if let groupInfo = groupInfo {
                self.inviteOptionData?.value = TUIGroupInfoDataProvider.getApproveOption(groupInfo)
            }
        } fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        }
    }

    func setGroupReceiveMessageOpt(_ opt: V2TIMReceiveMessageOpt, succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        V2TIMManager.sharedInstance().setGroupReceiveMessageOpt(groupID, opt: opt, succ: succ, fail: fail)
    }

    func setGroupName(_ groupName: String) {
        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.groupName = groupName

        V2TIMManager.sharedInstance().setGroupInfo(info) { [weak self] in
            guard let self else { return }
            self.profileCellData?.name = groupName
        } fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
        }
    }

    func setGroupNotification(_ notification: String) {
        let info = V2TIMGroupInfo()
        info.groupID = groupID
        info.notification = notification

        V2TIMManager.sharedInstance().setGroupInfo(info) { [weak self] in
            guard let self else { return }
            self.profileCellData?.signature = notification
        } fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
        }
    }

    func setGroupMemberNameCard(_ nameCard: String) {
        guard let userID = V2TIMManager.sharedInstance().getLoginUser() else { return }
        let info = V2TIMGroupMemberFullInfo()
        info.userID = userID
        info.nameCard = nameCard

        V2TIMManager.sharedInstance().setGroupMemberInfo(groupID, info: info) { [weak self] in
            guard let self else { return }
            self.groupNickNameCellData?.value = nameCard
            self.selfInfo?.nameCard = nameCard
        } fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
        }
    }

    func dismissGroup(succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        V2TIMManager.sharedInstance().dismissGroup(groupID, succ: succ, fail: fail)
    }

    func quitGroup(succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        V2TIMManager.sharedInstance().quitGroup(groupID, succ: succ, fail: fail)
    }

    func clearAllHistory(succ: @escaping V2TIMSucc, fail: @escaping V2TIMFail) {
        V2TIMManager.sharedInstance().clearGroupHistoryMessage(groupID, succ: succ, fail: fail)
    }

    // MARK: - Static Methods

    static func getGroupTypeName(_ groupInfo: V2TIMGroupInfo) -> String {
        switch groupInfo.groupType {
        case "Work":
            return TUISwift.timCommonLocalizableString("TUIKitWorkGroup")
        case "Public":
            return TUISwift.timCommonLocalizableString("TUIKitPublicGroup")
        case "Meeting":
            return TUISwift.timCommonLocalizableString("TUIKitChatRoom")
        case "Community":
            return TUISwift.timCommonLocalizableString("TUIKitCommunity")
        default:
            return ""
        }
    }

    static func getAddOption(_ groupInfo: V2TIMGroupInfo) -> String {
        switch groupInfo.groupAddOpt {
        case V2TIMGroupAddOpt.GROUP_ADD_FORBID:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileJoinDisable")
        case V2TIMGroupAddOpt.GROUP_ADD_AUTH:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAdminApprove")
        case V2TIMGroupAddOpt.GROUP_ADD_ANY:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
        default:
            return ""
        }
    }

    static func getAddOptionWithV2AddOpt(_ opt: V2TIMGroupAddOpt) -> String {
        switch opt {
        case V2TIMGroupAddOpt.GROUP_ADD_FORBID:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileJoinDisable")
        case V2TIMGroupAddOpt.GROUP_ADD_AUTH:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAdminApprove")
        case V2TIMGroupAddOpt.GROUP_ADD_ANY:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
        default:
            return ""
        }
    }

    static func getApproveOption(_ groupInfo: V2TIMGroupInfo) -> String {
        switch groupInfo.groupApproveOpt {
        case V2TIMGroupAddOpt.GROUP_ADD_FORBID:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileInviteDisable")
        case V2TIMGroupAddOpt.GROUP_ADD_AUTH:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAdminApprove")
        case V2TIMGroupAddOpt.GROUP_ADD_ANY:
            return TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
        default:
            return ""
        }
    }

    static func isMarkedByFoldType(_ markList: [NSNumber]) -> Bool {
        return markList.contains { $0.uintValue == V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_FOLD.rawValue }
    }

    static func isMarkedByHideType(_ markList: [NSNumber]) -> Bool {
        return markList.contains { $0.uintValue == V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_HIDE.rawValue }
    }

    static func isMeOwner(_ groupInfo: V2TIMGroupInfo) -> Bool {
        return groupInfo.owner == V2TIMManager.sharedInstance().getLoginUser() || groupInfo.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue
    }

    static func isMeSuper(_ groupInfo: V2TIMGroupInfo) -> Bool {
        return groupInfo.owner == V2TIMManager.sharedInstance().getLoginUser() && groupInfo.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
    }
}
