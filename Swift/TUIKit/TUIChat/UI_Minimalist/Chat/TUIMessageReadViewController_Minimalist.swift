import TIMCommon
import TUICore
import UIKit

class TUIMessageReadViewController_Minimalist: UIViewController, UITableViewDelegate, UITableViewDataSource, TUINotificationProtocol, TUIMessageCellDelegate {
    var alertCellClass: AnyClass?
    var alertViewCellData: TUIMessageCellData?
    var originFrame: CGRect = .zero

    var viewWillShowHandler: ((TUIMessageCell?) -> Void)?
    var viewDidShowHandler: ((TUIMessageCell?) -> Void)?
    var viewWillDismissHandler: ((TUIMessageCell?) -> Void)?

    var cellData: TUIMessageCellData?
    var showReadStatusDisable: Bool = false
    var dataProvider: TUIMessageDataProvider?

    var messageBackView: UIView?

    var readMembers: [V2TIMGroupMemberInfo] = []
    var unreadMembers: [V2TIMGroupMemberInfo] = []
    var readSeq: UInt = 0
    var unreadSeq: UInt = 0
    var c2cReceiverName: String?
    var c2cReceiverAvatarUrl: String?
    var alertView: TUIMessageCell_Minimalist?
    var messageCellConfig: TUIMessageCellConfig_Minimalist? = TUIMessageCellConfig_Minimalist()

    lazy var tableView: UITableView = {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        view.addSubview(tableView)

        let view = UIView(frame: .zero)
        tableView.tableFooterView = view
        tableView.separatorStyle = .none
        tableView.register(TUIMemberCell_Minimalist.self, forCellReuseIdentifier: kMemberCellReuseId)
        tableView.register(TUIMemberDescribeCell_Minimalist.self, forCellReuseIdentifier: "TUIMemberDescribeCell_Minimalist")
        messageCellConfig?.bindTableView(tableView)
        return tableView
    }()

    // MARK: - Init

    init(cellData: TUIMessageCellData?, dataProvider: TUIMessageDataProvider?, showReadStatusDisable: Bool, c2cReceiverName: String?, c2cReceiverAvatar: String?) {
        super.init(nibName: nil, bundle: nil)
        self.cellData = cellData
        self.dataProvider = dataProvider
        self.showReadStatusDisable = showReadStatusDisable
        self.c2cReceiverName = c2cReceiverName
        self.c2cReceiverAvatarUrl = c2cReceiverAvatar
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if isGroupMessageRead() {
            loadMembers()
        }
        setupViews()
        TUICore.registerEvent("TUICore_TUIPluginNotify", subKey: "TUICore_TUIPluginNotify_DidChangePluginViewSubKey", object: self)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRootMsg()
        viewWillShowHandler?(alertView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidShowHandler?(alertView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDismissHandler?(alertView)
    }

    deinit {
        print("\(String(describing: self)) dealloc")
    }

    // MARK: - Setup views

    func setupViews() {
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        setupTitleView()
        setupMessageView()
    }

    func layoutViews() {
        guard let navigationController = navigationController else { return }
        let backViewTop = navigationController.navigationBar.mm_maxY
        messageBackView?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: TUISwift.kScale390(17) + TUISwift.kScale390(24) + TUISwift.kScale390(4))
        tableView.mm_top(backViewTop).mm_left(0).mm_width(view.mm_w).mm_height(view.mm_h - tableView.mm_y)
    }

    func setupTitleView() {
        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("MessageInfo")
        titleLabel.font = UIFont.systemFont(ofSize: 18.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }

    func setupMessageView() {
        messageBackView = UIView()
        messageBackView?.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        messageBackView?.isUserInteractionEnabled = true
        tableView.tableHeaderView = messageBackView
        tableView.tableHeaderView?.isUserInteractionEnabled = true

        let dateLabel = UILabel()
        messageBackView?.addSubview(dateLabel)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        let dateString = formatter.string(from: cellData?.innerMessage?.timestamp ?? Date())
        dateLabel.text = dateString
        dateLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        dateLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        dateLabel.textColor = TUISwift.tuiChatDynamicColor("chat_message_read_name_date_text_color", defaultColor: "#999999")
        dateLabel.sizeToFit()
        dateLabel.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(TUISwift.kScale390(17))
            make.width.equalTo(dateLabel.frame.size.width)
            make.height.equalTo(TUISwift.kScale390(24))
        }
    }

    func updateRootMsg() {
        guard let alertViewCellData = alertViewCellData else { return }
        alertViewCellData.showAvatar = false
        alertViewCellData.showMessageModifyReplies = false
    }

    func loadMembers() {
        getReadMembersWithCompletion { _, _, _, _ in
            self.tableView.reloadData()
        }
        getUnreadMembersWithCompletion { _, _, _, _ in
            self.tableView.reloadData()
        }
    }

    func getReadMembersWithCompletion(completion: @escaping (Int, String, [Any], Bool) -> Void) {
        guard let message = cellData?.innerMessage else { return }
        TUIMessageDataProvider.getReadMembersOfMessage(message, filter: .GROUP_MESSAGE_READ_MEMBERS_FILTER_READ, nextSeq: readSeq, completion: { [weak self] code, desc, members, nextSeq, isFinished in
            guard let self else { return }
            if code != 0 {
                return
            }
            self.readMembers.append(contentsOf: members)
            self.readSeq = isFinished ? UInt.max : nextSeq
            completion(Int(code), desc ?? "", members, isFinished)
        })
    }

    func getUnreadMembersWithCompletion(completion: @escaping (Int, String, [Any], Bool) -> Void) {
        guard let message = cellData?.innerMessage else { return }
        TUIMessageDataProvider.getReadMembersOfMessage(message, filter: .GROUP_MESSAGE_READ_MEMBERS_FILTER_UNREAD, nextSeq: readSeq, completion: { [weak self] code, desc, members, nextSeq, isFinished in
            guard let self else { return }
            if code != 0 {
                return
            }
            self.unreadMembers.append(contentsOf: members)
            self.unreadSeq = isFinished ? UInt.max : nextSeq
            completion(Int(code), desc ?? "", members, isFinished)
        })
    }

    func getUserOrFriendProfileVCWithUserID(_ userID: String?, succ: @escaping (UIViewController) -> Void, fail: @escaping (Int32, String?) -> Void) {
        let param: [String: Any] = [
            "TUICore_TUIContactService_etUserOrFriendProfileVCMethod_UserIDKey": userID ?? "",
            "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey": succ,
            "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey": fail
        ]
        TUICore.createObject("TUICore_TUIContactObjectFactory_Minimalist", key: "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod", param: param)
    }

    var members: [Any] {
        var dataArray = [Any]()
        if isGroupMessageRead() {
            if readMembers.count > 0 {
                let describeCellData = TUIMemberDescribeCellData()
                describeCellData.title = TUISwift.timCommonLocalizableString("GroupReadBy")
                describeCellData.icon = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_all_people_read"))
                dataArray.append(describeCellData)

                for member in readMembers {
                    if let userID = member.userID {
                        let data = TUIMemberCellData(userID: userID, nickName: member.nickName, friendRemark: member.friendRemark, nameCard: member.nameCard, avatarUrl: member.faceURL ?? "", detail: nil)
                        dataArray.append(data)
                    }
                }
            }

            if unreadMembers.count > 0 {
                let describeCellData = TUIMemberDescribeCellData()
                describeCellData.title = TUISwift.timCommonLocalizableString("GroupDeliveredTo")
                describeCellData.icon = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_some_people_read"))
                dataArray.append(describeCellData)

                for member in unreadMembers {
                    if let userID = member.userID {
                        let data = TUIMemberCellData(userID: userID, nickName: member.nickName, friendRemark: member.friendRemark, nameCard: member.nameCard, avatarUrl: member.faceURL ?? "", detail: nil)
                        dataArray.append(data)
                    }
                }
            }
        } else {
            if cellData?.direction == .incoming {
                return dataArray
            }
            let detail: String? = nil
            let isPeerRead = cellData?.messageReceipt?.isPeerRead ?? false

            let describeCellData = TUIMemberDescribeCellData()
            if isPeerRead {
                describeCellData.title = TUISwift.timCommonLocalizableString("C2CReadBy")
                describeCellData.icon = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_all_people_read"))
            } else {
                describeCellData.title = TUISwift.timCommonLocalizableString("C2CDeliveredTo")
                describeCellData.icon = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_some_people_read"))
            }

            let data = TUIMemberCellData(userID: cellData?.innerMessage?.userID ?? "", nickName: nil, friendRemark: c2cReceiverName ?? "", nameCard: nil, avatarUrl: c2cReceiverAvatarUrl ?? "", detail: detail)
            dataArray.append(describeCellData)
            dataArray.append(data)
        }
        return dataArray
    }

    func isGroupMessageRead() -> Bool {
        guard let cellData = cellData else { return false }
        return (cellData.innerMessage?.groupID?.count ?? 0) > 0
    }

    func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, onRemoveHeightCache cellData: TUIMessageCellData?) {
        if let cellData = cellData {
            messageCellConfig?.removeHeightCacheOfMessageCellData(cellData)
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let data = members[indexPath.row] as? TUICommonCellData else { return }

        if data is TUIMemberDescribeCellData {
            return
        } else if data is TUIMemberCellData {
            if isGroupMessageRead() {
                guard indexPath.row < members.count else { return }
                guard let currentData = data as? TUIMemberCellData else { return }
                getUserOrFriendProfileVCWithUserID(currentData.userID, succ: { [weak self] vc in
                    guard let self else { return }
                    self.navigationController?.pushViewController(vc, animated: true)
                }, fail: { _, _ in })
            } else {
                getUserOrFriendProfileVCWithUserID(cellData?.innerMessage?.userID) { [weak self] vc in
                    guard let self else { return }
                    self.navigationController?.pushViewController(vc, animated: true)
                } fail: { _, _ in }
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return members.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let data = alertViewCellData else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: data.reuseId, for: indexPath) as? TUIMessageCell
            cell!.delegate = self
            cell!.fill(with: data)
            cell!.notifyBottomContainerReady(of: nil)
            return cell!
        }

        if let data = members[indexPath.row] as? TUICommonCellData {
            var cell: TUICommonTableViewCell? = nil
            if data is TUIMemberDescribeCellData {
                cell = tableView.dequeueReusableCell(withIdentifier: "TUIMemberDescribeCell_Minimalist", for: indexPath) as? TUIMemberDescribeCell_Minimalist
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: kMemberCellReuseId, for: indexPath) as? TUIMemberCell_Minimalist
            }
            cell?.fill(with: data)
            return cell ?? UITableViewCell()
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let margin: CGFloat = cellData?.sameToNextMsgSender == true ? 10 : 0
            return (messageCellConfig?.getHeightFromMessageCellData(cellData) ?? 0) + margin
        }
        guard members[indexPath.row] is TUICommonCellData else { return 0 }
        return TUISwift.kScale390(57)
    }

    // MARK: - TUINotificationProtocol

    func onNotifyEvent(_ key: String, subKey: String, object anObject: Any?, param: [AnyHashable: Any]?) {
        if key == "TUICore_TUIPluginNotify", subKey == "TUICore_TUIPluginNotify_DidChangePluginViewSubKey" {
            guard let data = param?["TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data"] as? TUIMessageCellData else { return }
            clearAndReloadCell(ofData: data)
        }
    }

    func clearAndReloadCell(ofData data: TUIMessageCellData) {
        messageCellConfig?.removeHeightCacheOfMessageCellData(data)
        tableView.reloadData()
    }
}
