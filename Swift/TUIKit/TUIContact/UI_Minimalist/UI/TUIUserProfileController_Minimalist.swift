//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.
/**
 *
 *  Tencent Cloud Communication Service Interface Components TUIKIT - User Information View Interface
 *  This file implements the user profile view controller. User refers to other users who are not friends.
 *  If friend, use TUIFriendProfileController
 */

import TIMCommon
import UIKit

enum ProfileControllerAction_Minimalist: UInt {
    case PCA_NONE_MINI
    case PCA_ADD_FRIEND_MINI
    case PCA_PENDENDY_CONFIRM_MINI
    case PCA_GROUP_CONFIRM_MINI
}

class TUIUserProfileController_Minimalist: UITableViewController, TUIContactProfileCardDelegate_Minimalist {
    var userFullInfo: V2TIMUserFullInfo?
    var groupPendency: TUIGroupPendencyCellData?
    var pendency: TUICommonPendencyCellData_Minimalist?
    var actionType: ProfileControllerAction_Minimalist = .PCA_NONE_MINI
    var dataList: [[Any]] = []
    var titleView: TUINaviBarIndicatorView?

    override init(style: UITableView.Style) {
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleView = TUINaviBarIndicatorView()
        titleView?.setTitle(TUISwift.timCommonLocalizableString("ProfileDetails"))
        navigationItem.titleView = titleView
        navigationItem.title = ""
        clearsSelectionOnViewWillAppear = true
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(TUICommonContactTextCell.self, forCellReuseIdentifier: "TextCell")
        tableView.register(TUICommonContactProfileCardCell_Minimalist.self, forCellReuseIdentifier: "CardCell")
        tableView.register(TUIContactButtonCell_Minimalist.self, forCellReuseIdentifier: "ButtonCell")
        tableView.register(TUIContactAcceptRejectCell_Minimalist.self, forCellReuseIdentifier: "ButtonAcceptCell")

        tableView.delaysContentTouches = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white

        loadData()
    }

    func loadData() {
        var list: [[Any]] = []
        list.append({
            var inlist: [Any] = []
            inlist.append({
                let personal = TUICommonContactProfileCardCellData_Minimalist()
                personal.identifier = userFullInfo?.userID
                personal.avatarImage = TUISwift.defaultAvatarImage()
                personal.avatarUrl = URL(string: userFullInfo?.faceURL ?? "")
                personal.name = userFullInfo?.showName()
                personal.genderString = userFullInfo?.showGender()
                personal.signature = userFullInfo?.showSignature()
                personal.reuseId = "CardCell"
                return personal
            }())
            return inlist
        }())

        if pendency != nil || groupPendency != nil {
            list.append({
                var inlist: [Any] = []
                inlist.append({
                    let data = TUICommonContactTextCellData()
                    data.key = TUISwift.timCommonLocalizableString("FriendAddVerificationMessage")
                    data.keyColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1.0)
                    data.valueColor = UIColor(red: 68/255.0, green: 68/255.0, blue: 68/255.0, alpha: 1.0)
                    if let pendency = pendency {
                        data.value = pendency.addWording
                    } else if let groupPendency = groupPendency {
                        data.value = groupPendency.requestMsg
                    }
                    data.reuseId = "TextCell"
                    data.enableMultiLineValue = true
                    return data
                }())
                return inlist
            }())
        }

        dataList = list

        if actionType == .PCA_ADD_FRIEND_MINI,
           let userFullInfo = userFullInfo,
           let userID = userFullInfo.userID
        {
            V2TIMManager.sharedInstance().checkFriend(userIDList: [userID], checkType: .FRIEND_TYPE_BOTH, succ: { resultList in
                guard let result = resultList?.first else { return }
                if result.relationType == .FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST || result.relationType == .FRIEND_RELATION_TYPE_BOTH_WAY {
                    return
                }
                if !TUIContactConfig.shared.isItemHiddenInContactConfig(.addFriend) {
                    self.dataList.append({
                        var inlist: [Any] = []
                        inlist.append({
                            let data = TUIContactButtonCellData_Minimalist()
                            data.title = TUISwift.timCommonLocalizableString("FriendAddTitle")
                            data.style = .blue
                            data.textColor = UIColor.tui_color(withHex: "#147AFF")
                            data.cbuttonSelector = #selector(self.onAddFriend)
                            data.reuseId = "ButtonCell"
                            data.hideSeparatorLine = true
                            return data
                        }())
                        return inlist
                    }())
                }
                self.tableView.reloadData()
            }, fail: { _, _ in
                print("")
            })
        }

        if actionType == .PCA_PENDENDY_CONFIRM_MINI {
            dataList.append({
                var inlist: [Any] = []
                inlist.append({
                    let data = TUIContactAcceptRejectCellData_Minimalist()
                    weak var weakData = data
                    data.agreeClickCallback = {
                        self.onAgreeFriend()
                        weakData?.isAccepted = true
                        self.tableView.reloadData()
                    }
                    data.rejectClickCallback = {
                        self.onRejectFriend()
                        weakData?.isRejected = true
                        self.tableView.reloadData()
                    }
                    data.reuseId = "ButtonAcceptCell"
                    return data
                }())
                return inlist
            }())
        }

        if actionType == .PCA_GROUP_CONFIRM_MINI {
            dataList.append({
                var inlist: [Any] = []
                inlist.append({
                    let data = TUIContactButtonCellData_Minimalist()
                    data.title = TUISwift.timCommonLocalizableString("Accept")
                    data.style = .white
                    data.textColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
                    data.cbuttonSelector = #selector(self.onAgreeGroup)
                    data.reuseId = "ButtonCell"
                    return data
                }())
                inlist.append({
                    let data = TUIContactButtonCellData_Minimalist()
                    data.title = TUISwift.timCommonLocalizableString("Decline")
                    data.style = .redText
                    data.cbuttonSelector = #selector(self.onRejectGroup)
                    data.reuseId = "ButtonCell"
                    return data
                }())
                return inlist
            }())
        }

        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataList.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = dataList[indexPath.section][indexPath.row] as! TUICommonCellData
        let cell = tableView.dequeueReusableCell(withIdentifier: data.reuseId, for: indexPath) as! TUICommonTableViewCell
        if let cardCell = cell as? TUICommonContactProfileCardCell_Minimalist {
            cardCell.delegate = self
        }
        cell.fill(with: data)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let data = dataList[indexPath.section][indexPath.row] as! TUICommonCellData
        return data.height(ofWidth: TUISwift.screen_Width())
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Implement selection logic if needed
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 10
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    @objc func onSendMessage() {
        // Implement send message logic if needed
    }

    @objc func onAddFriend() {
        let vc = TUIFriendRequestViewController_Minimalist()
        vc.profile = userFullInfo
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onAgreeFriend() {
        pendency?.agreeWithSuccess(success: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }, failure: { _, _ in
            // Handle failure
        })
    }

    @objc func onRejectFriend() {
        pendency?.rejectWithSuccess(success: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }, failure: { _, _ in
            // Handle failure
        })
    }

    @objc func onAgreeGroup() {
        groupPendency?.agree(success: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }, failure: { _, _ in
            // Handle failure
        })
    }

    @objc func onRejectGroup() {
        groupPendency?.reject(success: { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }, failure: { _, _ in
            // Handle failure
        })
    }

    func toastView() -> UIView? {
        return TUITool.applicationKeywindow()
    }

    func didSelectAvatar() {
        let image = TUIContactAvatarViewController_Minimalist()
        image.avatarData?.avatarUrl = URL(string: userFullInfo?.faceURL ?? "")
        let list = dataList
        print("\(list)")

        navigationController?.pushViewController(image, animated: true)
    }

    func didTapOnAvatar(_ cell: TUICommonContactProfileCardCell_Minimalist) {
        let image = TUIContactAvatarViewController_Minimalist()
        image.avatarData = cell.cardData
        navigationController?.pushViewController(image, animated: true)
    }
}
