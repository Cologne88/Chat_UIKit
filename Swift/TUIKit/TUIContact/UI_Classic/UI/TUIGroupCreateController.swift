// TUIGroupCreateController.swift
// TUIContact
//
// Created by wyl on 2022/8/22.
// Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import UIKit

class TUIGroupCreateController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var createGroupInfo: V2TIMGroupInfo?
    var createContactArray: [TUICommonContactSelectCellData]?
    var submitCallback: ((Bool, V2TIMGroupInfo?) -> Void)?

    private var tableView: UITableView!
    private var groupNameTextField: UITextField!
    private var groupIDTextField: UITextField!
    private var keyboardShown = false
    private var titleView: TUINaviBarIndicatorView!
    private var describeTextViewRect: CGRect = .zero
    private var pickerView: TUIContactListPicker!
    private var cacheGroupGridAvatarImage: UIImage?

    private lazy var describeTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textAlignment = TUISwift.isRTL() ? .right : .left
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return textView
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pickerView.mm_width(view.mm_w).mm_height(60 + pickerView.mm_safeAreaBottomGap).mm_bottom(0)
        tableView.mm_width(view.mm_w).mm_flexToBottom(pickerView.mm_h)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: view.frame, style: .plain)
        view.addSubview(tableView)
        tableView.frame = view.frame
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.groupTableViewBackground

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        groupNameTextField = UITextField(frame: .zero)
        groupNameTextField.textAlignment = TUISwift.isRTL() ? .left : .right
        groupNameTextField.placeholder = TUISwift.timCommonLocalizableString("TUIKitCreatGroupNamed_Placeholder")
        groupNameTextField.delegate = self
        if let groupName = createGroupInfo?.groupName, !groupName.isEmpty {
            groupNameTextField.text = groupName
        }

        groupIDTextField = UITextField(frame: .zero)
        groupIDTextField.textAlignment = TUISwift.isRTL() ? .left : .right
        groupIDTextField.keyboardType = .default
        groupIDTextField.placeholder = TUISwift.timCommonLocalizableString("TUIKitCreatGroupID_Placeholder")
        groupIDTextField.delegate = self

        updateRectAndTextForDescribeTextView(describeTextView)

        titleView = TUINaviBarIndicatorView()
        titleView.setTitle(TUISwift.timCommonLocalizableString("ChatsNewGroupText"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        pickerView = TUIContactListPicker(frame: .zero)
        pickerView.backgroundColor = UIColor.groupTableViewBackground
        view.addSubview(pickerView)
        pickerView.accessoryBtn.isEnabled = true
        pickerView.accessoryBtn.addTarget(self, action: #selector(finishTask), for: .touchUpInside)

        creatGroupAvatarImage()
    }

    private func creatGroupAvatarImage() {
        guard TUIConfig.default().enableGroupGridAvatar else { return }
        guard cacheGroupGridAvatarImage == nil else { return }

        var muArray: [String] = []
        createContactArray?.forEach { cellData in
            if let avatarUrl = cellData.avatarUrl?.absoluteString {
                muArray.append(avatarUrl)
            } else {
                muArray.append("about:blank")
            }
        }

        muArray.append(TUILogin.getFaceUrl() ?? "")

        TUIGroupAvatar.createGroupAvatar(muArray) { [weak self] groupAvatar in
            guard let self else { return }
            self.cacheGroupGridAvatarImage = groupAvatar
            self.tableView.reloadData()
        }
    }

    private func updateRectAndTextForDescribeTextView(_ describeTextView: UITextView) {
        var descStr = ""
        Self.getfomatDescribeType(createGroupInfo?.groupType) { _, groupTypeDescribeStr in
            descStr = groupTypeDescribeStr
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = TUISwift.isRTL() ? .right : .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.tui_color(withHex: "#888888"),
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSMutableAttributedString(string: descStr, attributes: attributes)
        let inviteTipstring = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Desc_Highlight")
        if let range = descStr.range(of: inviteTipstring) {
            attributedString.addAttribute(.link, value: "https://cloud.tencent.com/product/im", range: NSRange(range, in: descStr))
        }
        self.describeTextView.attributedText = attributedString

        let rect = self.describeTextView.text.boundingRect(
            with: CGSize(width: view.mm_w - 32, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle],
            context: nil
        )
        describeTextViewRect = rect
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 2 ? 88 : 44
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear

        if section == 2 {
            view.addSubview(describeTextView)
            describeTextView.frame = CGRect(x: 15, y: 10, width: describeTextViewRect.size.width, height: describeTextViewRect.size.height)
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 2 ? describeTextViewRect.size.height + 20 : 10
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "groupName")
                cell.textLabel?.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupNamed")
                cell.contentView.addSubview(groupNameTextField)
                cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
                groupNameTextField.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    groupNameTextField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    groupNameTextField.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor),
                    groupNameTextField.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.5),
                    groupNameTextField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
                return cell
            } else {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: "groupID")
                cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
                cell.textLabel?.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupID")
                cell.contentView.addSubview(groupIDTextField)
                groupIDTextField.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    groupIDTextField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                    groupIDTextField.heightAnchor.constraint(equalTo: cell.contentView.heightAnchor),
                    groupIDTextField.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: 0.5),
                    groupIDTextField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
                ])
                return cell
            }
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "GroupType")
            cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType")
            Self.getfomatDescribeType(createGroupInfo?.groupType) { groupTypeStr, _ in
                cell.detailTextLabel?.text = groupTypeStr
            }
            return cell
        } else if indexPath.section == 2 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "GroupType")
            cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupAvatar")
            let headImage = UIImageView(image: TUISwift.defaultGroupAvatarImage(byGroupType: createGroupInfo?.groupType))
            cell.contentView.addSubview(headImage)
            if TUIConfig.default().enableGroupGridAvatar, let cacheImage = cacheGroupGridAvatarImage {
                headImage.sd_setImage(with: URL(string: createGroupInfo?.faceURL ?? ""), placeholderImage: cacheImage)
            }
            let margin: CGFloat = 5
            headImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headImage.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -margin),
                headImage.heightAnchor.constraint(equalToConstant: 48),
                headImage.widthAnchor.constraint(equalToConstant: 48),
                headImage.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.section == 1 {
            let vc = TUIGroupTypeListController()
            vc.title = ""
            navigationController?.pushViewController(vc, animated: true)
            vc.selectCallBack = { [weak self] groupType in
                guard let self = self else { return }
                self.createGroupInfo?.groupType = groupType
                self.updateRectAndTextForDescribeTextView(self.describeTextView)
                self.tableView.reloadData()
            }
        } else if indexPath.section == 2 {
            didTapToChooseAvatar()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == groupNameTextField {
            if let text = textField.text, text.count > 10 {
                textField.text = String(text.prefix(10))
            }
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == groupIDTextField {
            let currentText = textField.text ?? ""
            let newLength = currentText.count - range.length + string.count
            if newLength > 16 {
                return false
            }
            return true
        }
        return true
    }

    @objc func didTapToChooseAvatar() {
        let vc = TUISelectAvatarController()
        vc.selectAvatarType = .groupAvatar
        vc.createGroupType = createGroupInfo?.groupType ?? "Public"
        vc.cacheGroupGridAvatarImage = cacheGroupGridAvatarImage ?? UIImage()
        vc.profilFaceURL = createGroupInfo?.faceURL ?? ""
        navigationController?.pushViewController(vc, animated: true)

        vc.selectCallBack = { [weak self] urlStr in
            guard let self = self else { return }
            if !urlStr.isEmpty {
                self.createGroupInfo?.faceURL = urlStr
            } else {
                self.createGroupInfo?.faceURL = nil
            }
            self.tableView.reloadData()
        }
    }

    @objc private func finishTask() {
        createGroupInfo?.groupName = groupNameTextField.text
        createGroupInfo?.groupID = groupIDTextField.text

        guard let info = createGroupInfo, let createContactArray = createContactArray else { return }

        let isCommunity = info.groupType == "Community"
        let hasTGSPrefix = info.groupID?.hasPrefix("@TGS#_") ?? false

        if let groupIDText = groupIDTextField.text, !groupIDText.isEmpty {
            if isCommunity && !hasTGSPrefix {
                let toastMsg = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessageRuleError")
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
                return
            }

            if !isCommunity && hasTGSPrefix {
                let toastMsg = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessageRuleError")
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
                return
            }
        }

        var members: [V2TIMCreateGroupMemberInfo] = []
        for item in createContactArray {
            let member = V2TIMCreateGroupMemberInfo()
            member.userID = item.identifier
            member.role = UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_MEMBER.rawValue)
            members.append(member)
        }

        let showName = TUILogin.getNickName() ?? TUILogin.getUserID()

        V2TIMManager.sharedInstance().createGroup(info: info, memberList: members, succ: { [weak self] groupID in
            guard let self = self else { return }
            var content = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessage")
            if info.groupType == "Community" {
                content = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessage")
            }
            let dic: [String: Any] = [
                "version": GroupCreate_Version,
                "businessID": "group_create",
                "opUser": showName ?? "",
                "content": content,
                "cmd": info.groupType == "Community" ? 1 : 0
            ]
            if let data = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted) {
                if let msg = V2TIMManager.sharedInstance().createCustomMessage(data: data) {
                    V2TIMManager.sharedInstance().sendMessage(message: msg, receiver: nil, groupID: groupID, priority: .PRIORITY_DEFAULT, onlineUserOnly: false, offlinePushInfo: nil, progress: nil, succ: nil, fail: nil)
                    self.createGroupInfo?.groupID = groupID
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.submitCallback?(true, self.createGroupInfo)
                    }
                }
            }
        }, fail: { [weak self] code, msg in
            guard let self = self else { return }
            if code == ERR_SDK_INTERFACE_NOT_SUPPORT.rawValue {
                TUITool.postUnsupportNotification(ofService: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunity"), serviceDesc: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunityDesc"), debugOnly: true)
            } else {
                var toastMsg = TUITool.convertIMError(Int(code), msg: msg) ?? ""
                if toastMsg.count == 0 {
                    toastMsg = "\(code)"
                }
                TUITool.hideToastActivity()
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
            }
            self.submitCallback?(false, self.createGroupInfo)
        })
    }

    // MARK: - format

    static func getfomatDescribeType(_ groupType: String?, completion: @escaping (String, String) -> Void) {
        guard let groupType = groupType else {
            completion("", "")
            return
        }
        var desc = ""
        switch groupType {
        case "Work":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work"), desc)
        case "Public":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public"), desc)
        case "Meeting":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting"), desc)
        case "Community":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community"), desc)
        default:
            completion(groupType, groupType)
        }
    }
}
