//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

import TIMCommon
import UIKit

class TUIGroupMemberController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView?
    var groupId: String?
    var groupInfo: V2TIMGroupInfo?

    var titleView: TUINaviBarIndicatorView?
    var showContactSelectVC: UIViewController?
    var dataProvider: TUIGroupMemberDataProvider?
    var members: [TUIMemberInfoCellData] = []
    var tag: Int = 0

    lazy var indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        dataProvider = TUIGroupMemberDataProvider(groupID: groupId ?? "")
        dataProvider?.groupInfo = groupInfo
        refreshData()
    }

    func refreshData() {
        weak var weakSelf = self
        dataProvider?.loadDatas { _, _, datas in
            guard let strongSelf = weakSelf else { return }
            let title = String(format: TUISwift.timCommonLocalizableString("TUIKitGroupProfileGroupCountFormat"), datas.count)
            strongSelf.title = title
            strongSelf.members = datas
            strongSelf.tableView?.reloadData()
        }
    }

    func setupViews() {
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")

        // left
        var image = TUISwift.tuiContactDynamicImage("group_nav_back_img", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("back")))
        image = image?.rtl_imageFlippedForRightToLeftLayoutDirection()
        let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        leftButton.addTarget(self, action: #selector(leftBarButtonClick), for: .touchUpInside)
        leftButton.setImage(image, for: .normal)
        let leftItem = UIBarButtonItem(customView: leftButton)
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = -10.0
        if let deviceVersion = TUITool.deviceVersion() {
            let version = (deviceVersion as NSString).floatValue
            if version >= 11.0 {
                leftButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
                leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -15, bottom: 0, right: 0)
            }
        }
        navigationItem.leftBarButtonItems = [spaceItem, leftItem]
        parent?.navigationItem.leftBarButtonItems = [spaceItem, leftItem]

        // right
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        rightButton.addTarget(self, action: #selector(rightBarButtonClick), for: .touchUpInside)
        rightButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitGroupProfileManage"), for: .normal)
        rightButton.setTitleColor(TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000"), for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        let rightItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightItem
        parent?.navigationItem.rightBarButtonItem = rightItem

        indicatorView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: CGFloat(TMessageController_Header_Height))

        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView?.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(TUIMemberInfoCell.self, forCellReuseIdentifier: "cell")
        tableView?.rowHeight = 48.0
        tableView?.tableFooterView = indicatorView
        view.addSubview(tableView!)

        titleView = TUINaviBarIndicatorView()
        navigationItem.titleView = titleView
        navigationItem.title = ""
        titleView?.setTitle(TUISwift.timCommonLocalizableString("GroupMember"))
    }

    @objc func leftBarButtonClick() {
        navigationController?.popViewController(animated: true)
    }

    @objc func rightBarButtonClick() {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        var ids = [String]()
        var displayNames = [String: String]()
        for cd in members {
            if let identifier = cd.identifier, identifier != V2TIMManager.sharedInstance().getLoginUser() {
                ids.append(identifier)
                displayNames[cd.identifier ?? ""] = cd.name ?? ""
            }
        }

        weak var weakSelf = self
        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { array in
            guard let strongSelf = weakSelf else { return }
            if strongSelf.tag == 1 {
                // add
                var list = [String]()
                for data in array {
                    list.append(data.identifier)
                }
                strongSelf.navigationController?.popToViewController(strongSelf, animated: true)
                strongSelf.addGroupId(strongSelf.groupId, members: list)
            } else if strongSelf.tag == 2 {
                // delete
                var list = [String]()
                for data in array {
                    list.append(data.identifier)
                }
                strongSelf.navigationController?.popToViewController(strongSelf, animated: true)
                strongSelf.deleteGroupId(strongSelf.groupId, members: list)
            }
        }

        if dataProvider?.groupInfo?.canInviteMember() == true {
            ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitGroupProfileManageAdd"), style: .default) { _ in
                // add
                self.tag = 1
                var param = [String: Any]()
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] = TUISwift.timCommonLocalizableString("GroupAddFirend")
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey] = ids
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] = selectContactCompletion
                if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: param) as? UIViewController {
                    self.showContactSelectVC = vc
                    self.navigationController?.pushViewController(self.showContactSelectVC!, animated: true)
                }
            })
        }
        if dataProvider?.groupInfo?.canRemoveMember() == true {
            ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitGroupProfileManageDelete"), style: .default) { _ in
                // delete
                self.tag = 2
                var param = [String: Any]()
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] = TUISwift.timCommonLocalizableString("GroupDeleteFriend")
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_SourceIdsKey] = ids
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames
                param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] = selectContactCompletion
                if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: param) as? UIViewController {
                    self.showContactSelectVC = vc
                    self.navigationController?.pushViewController(self.showContactSelectVC!, animated: true)
                }
            })
        }
        ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .cancel, handler: nil))

        present(ac, animated: true, completion: nil)
    }

    func addGroupId(_ groupId: String?, members: [String]) {
        weak var weakSelf = self
        V2TIMManager.sharedInstance().inviteUser(toGroup: groupId, userList: members, succ: { _ in
            guard let strongSelf = weakSelf else { return }
            strongSelf.refreshData()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("add_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }

    func deleteGroupId(_ groupId: String?, members: [String]) {
        weak var weakSelf = self
        V2TIMManager.sharedInstance().kickGroupMember(groupId, memberList: members, reason: "", succ: { _ in
            guard let strongSelf = weakSelf else { return }
            strongSelf.refreshData()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("delete_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TUIMemberInfoCell
        let data = members[indexPath.row]
        cell.data = data
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let data = members[indexPath.row]
        didCurrentMemberAtCellData(data)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && (scrollView.contentOffset.y >= scrollView.bounds.origin.y) {
            if indicatorView.isAnimating {
                return
            }
            indicatorView.startAnimating()

            // There's no more data, stop loading.
            if dataProvider?.isNoMoreData == true {
                indicatorView.stopAnimating()
                TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitMessageReadNoMoreData"))
                return
            }

            weak var weakSelf = self
            dataProvider?.loadDatas { success, _, datas in
                guard let strongSelf = weakSelf else { return }
                strongSelf.indicatorView.stopAnimating()
                if !success {
                    return
                }
                strongSelf.members.append(contentsOf: datas)
                strongSelf.tableView?.reloadData()
                strongSelf.tableView?.layoutIfNeeded()
                if datas.isEmpty {
                    strongSelf.tableView?.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - CGFloat(TMessageController_Header_Height)), animated: true)
                }
            }
        }
    }

    func didCurrentMemberAtCellData(_ mem: TUIMemberInfoCellData) {
        let userID = mem.identifier
        weak var weakSelf = self
        getUserOrFriendProfileVCWithUserID(userID) { vc in
            guard let strongSelf = weakSelf else { return }
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        } failBlock: { _, _ in
        }
    }

    func getUserOrFriendProfileVCWithUserID(_ userID: String?, succBlock: @escaping (UIViewController) -> Void, failBlock: @escaping (Int, String) -> Void) {
        let param: [String: Any] = [
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey: userID ?? "",
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey: succBlock,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey: failBlock
        ]
        TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod, param: param)
    }
}
