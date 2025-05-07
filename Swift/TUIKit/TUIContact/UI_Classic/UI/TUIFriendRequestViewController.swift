import TIMCommon
import UIKit

class TUIFriendRequestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TUIContactProfileCardDelegate {
    var profile: V2TIMUserFullInfo?
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addWordTextView = UITextView(frame: .zero)
    private let nickTextField = UITextField(frame: .zero)
    private var keyboardShown = false
    private var cardCellData: TUICommonContactProfileCardCellData?
    private var singleSwitchData: TUICommonContactSwitchCellData?
    private var titleView: TUINaviBarIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.frame = view.frame
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.groupTableViewBackground
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        addWordTextView.font = UIFont.systemFont(ofSize: 14)
        addWordTextView.textAlignment = TUISwift.isRTL() ? .right : .left

        if let loginUser = V2TIMManager.sharedInstance().getLoginUser() {
            V2TIMManager.sharedInstance().getUsersInfo([loginUser]) { [weak self] infoList in
                guard let self else { return }
                if let userInfo = infoList?.first, let name = userInfo.nickName ?? userInfo.userID {
                    self.addWordTextView.text = String(format: TUISwift.timCommonLocalizableString("FriendRequestFormat"), name)
                }
            } fail: { _, _ in
            }
        }

        nickTextField.textAlignment = TUISwift.isRTL() ? .left : .right

        titleView = TUINaviBarIndicatorView()
        titleView?.setTitle(TUISwift.timCommonLocalizableString("FriendRequestFillInfo"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        let data = TUICommonContactProfileCardCellData()
        data.name = profile?.showName()
        data.genderString = profile?.showGender()
        data.identifier = profile?.userID
        data.signature = profile?.showSignature()
        data.avatarImage = TUISwift.defaultAvatarImage()
        data.avatarUrl = URL(string: profile?.faceURL ?? "")
        data.showSignature = true
        cardCellData = data

        singleSwitchData = TUICommonContactSwitchCellData()
        singleSwitchData?.title = TUISwift.timCommonLocalizableString("FriendOneWay")

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self, !self.keyboardShown else { return }
            self.keyboardShown = true
            self.adjustContentOffsetDuringKeyboardAppear(true, with: notification)
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] notification in
            guard let self = self, self.keyboardShown else { return }
            self.keyboardShown = false
            self.adjustContentOffsetDuringKeyboardAppear(false, with: notification)
        }
    }

    func adjustContentOffsetDuringKeyboardAppear(_ appear: Bool, with notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
              let keyboardEndFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyboardEndFrame.height
        var contentSize = tableView.contentSize
        contentSize.height += appear ? -keyboardHeight : keyboardHeight

        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: UInt(curveValue << 16)), animations: {
            self.tableView.contentSize = contentSize
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return cardCellData?.height(ofWidth: TUISwift.screen_Width()) ?? 0
        }
        if indexPath.section == 1 {
            return 120
        }
        return 44
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.textColor = UIColor(red: 136 / 255.0, green: 136 / 255.0, blue: 136 / 255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 14.0)
        if section == 1 {
            label.text = "  " + TUISwift.timCommonLocalizableString("please_fill_in_verification_information")
        } else if section == 2 {
            label.text = "  " + TUISwift.timCommonLocalizableString("please_fill_in_remarks_group_info")
        }
        return label
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 38
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = TUICommonContactProfileCardCell(style: .default, reuseIdentifier: "TPersonalCommonCell_ReuseId")
            cell.delegate = self
            if let cardData = cardCellData {
                cell.fill(with: cardData)
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "AddWord")
            cell.contentView.addSubview(addWordTextView)
            addWordTextView.frame = CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: 120)
            return cell
        } else if indexPath.section == 2 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "NickName")
            cell.textLabel?.text = TUISwift.timCommonLocalizableString("Alia")
            cell.contentView.addSubview(nickTextField)

            let separator = UIView()
            separator.backgroundColor = UIColor.groupTableViewBackground
            cell.contentView.addSubview(separator)
            separator.frame = CGRect(x: 0, y: cell.contentView.frame.height - 1, width: tableView.frame.width, height: 1)

            nickTextField.frame = CGRect(x: cell.contentView.frame.width / 2, y: 0, width: cell.contentView.frame.width / 2 - 20, height: cell.contentView.frame.height)
            nickTextField.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]

            return cell
        } else if indexPath.section == 3 {
            let cell = TUIButtonCell(style: .default, reuseIdentifier: "send")
            let data = TUIButtonCellData()
            data.style = .white
            data.title = TUISwift.timCommonLocalizableString("Send")
            data.cselector = #selector(onSend)
            data.textColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "147AFF")
            cell.fill(with: data)

            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    @objc func onSend() {
        view.endEditing(true)
        TUITool.makeToastActivity()

        let application = V2TIMFriendAddApplication()
        application.addWording = addWordTextView.text
        application.friendRemark = nickTextField.text
        application.userID = profile?.userID ?? ""
        application.addSource = "iOS"
        application.addType = (singleSwitchData?.isOn == true ? .FRIEND_TYPE_SINGLE : .FRIEND_TYPE_BOTH)

        V2TIMManager.sharedInstance().addFriend(application: application, succ: { result in
            guard let result = result else { return }
            var msg: String?
            if result.resultCode == ERR_SUCC.rawValue {
                msg = TUISwift.timCommonLocalizableString("FriendAddResultSuccess")
            } else if result.resultCode == ERR_SVR_FRIENDSHIP_INVALID_PARAMETERS.rawValue,
                      result.resultInfo == "Err_SNS_FriendAdd_Friend_Exist"
            {
                msg = TUISwift.timCommonLocalizableString("FriendAddResultExists")
            } else {
                msg = TUITool.convertIMError(result.resultCode, msg: result.resultInfo)
            }

            if msg?.isEmpty ?? true {
                msg = "\(result.resultCode)"
            }

            TUITool.hideToastActivity()
            TUITool.makeToast(msg ?? "", duration: 3.0, idposition: TUICSToastPositionBottom)
        }, fail: { code, desc in
            TUITool.hideToastActivity()
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func didTapOnAvatar(cell: TUICommonContactProfileCardCell) {
        let image = TUIContactAvatarViewController()
        image.avatarData = cell.cardData
        navigationController?.pushViewController(image, animated: true)
    }
}
