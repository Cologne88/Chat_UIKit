import TIMCommon
import TUICore
import UIKit

protocol TUIMessageReadSelectViewDelegate: AnyObject {
    func messageReadSelectView(_ view: TUIMessageReadSelectView, didSelectItemTag tag: TUIMessageReadViewTag)
}

class TUIMessageReadSelectView: UIView {
    weak var delegate: TUIMessageReadSelectViewDelegate?
    var selected: Bool {
        didSet {
            updateColorBySelected(selected)
        }
    }

    private var title: String
    private var titleLabel: UILabel
    private var bottomLine: UIView

    init(title: String, viewTag: TUIMessageReadViewTag, selected: Bool) {
        self.title = title
        self.selected = selected
        self.titleLabel = UILabel()
        self.bottomLine = UIView()

        super.init(frame: .zero)

        self.tag = viewTag.rawValue
        setupViews()
        setupGesture()
        updateColorBySelected(selected)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutViews()
    }

    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_controller_bg_color", defaultColor: "#FFFFFF")

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        addSubview(bottomLine)
    }

    private func layoutViews() {
        titleLabel.sizeToFit()
        titleLabel.frame.size.height = 24
        titleLabel.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        bottomLine.frame.size = CGSize(width: titleLabel.frame.width, height: 2.5)
        bottomLine.frame.origin = CGPoint(x: titleLabel.center.x - bottomLine.frame.width / 2, y: titleLabel.frame.maxY + 4)
    }

    private func updateColorBySelected(_ selected: Bool) {
        let color = selected ? TUISwift.tuiChatDynamicColor("chat_message_read_status_tab_color", defaultColor: "#147AFF") : TUISwift.timCommonDynamicColor("chat_message_read_status_tab_unselect_color", defaultColor: "#444444")
        titleLabel.textColor = color
        bottomLine.isHidden = !selected
        bottomLine.backgroundColor = color
    }

    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapped(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func onTapped(_ gesture: UIGestureRecognizer) {
        delegate?.messageReadSelectView(self, didSelectItemTag: TUIMessageReadViewTag(rawValue: tag)!)
    }
}

class TUIMessageReadViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TUIMessageReadSelectViewDelegate {
    var alertCellClass: AnyClass?
    var alertViewCellData: TUIMessageCellData?
    var originFrame: CGRect = .zero

    var viewWillShowHandler: ((TUIMessageCell?) -> Void)?
    var viewDidShowHandler: ((TUIMessageCell?) -> Void)?
    var viewWillDismissHandler: (() -> Void)?

    var cellData: TUIMessageCellData?
    var showReadStatusDisable: Bool = false
    var selectedViewTag: TUIMessageReadViewTag?
    var dataProvider: TUIMessageDataProvider?

    var messageBackView: UIView?
    var contentLabel: UILabel?

    var selectViewsDict: [Int: UIView] = [:]
    var readMembers: [V2TIMGroupMemberInfo] = []
    var unreadMembers: [V2TIMGroupMemberInfo] = []
    var readSeq: UInt = 0
    var unreadSeq: UInt = 0
    var c2cReceiverName: String?
    var c2cReceiverAvatarUrl: String?
    var alertView: TUIMessageCell?
    var messageCellConfig: TUIMessageCellConfig? = TUIMessageCellConfig()

    var content: Any? {
        if let msg = cellData?.innerMessage {
            let content = NSMutableString(string: TUIMessageDataProvider.getDisplayString(message: msg) ?? "")

            switch msg.elemType {
            case .ELEM_TYPE_IMAGE:
                if let data = cellData as? TUIImageMessageCellData {
                    return data.thumbImage
                }
            case .ELEM_TYPE_VIDEO:
                if let data = cellData as? TUIVideoMessageCellData {
                    return data.thumbImage
                }
            case .ELEM_TYPE_FILE:
                content.append(msg.fileElem?.filename ?? "")
            case .ELEM_TYPE_CUSTOM:
                break
            default:
                break
            }
            return content
        }
        return nil
    }

    var selectViewsData: [Int: [String: Any]] {
        var readViews: [Int: [String: Any]] = [
            TUIMessageReadViewTag.read.rawValue: [
                "tag": TUIMessageReadViewTag.read.rawValue,
                "title": "\(cellData?.messageReceipt?.readCount ?? 0)" + TUISwift.timCommonLocalizableString("TUIKitMessageReadPartRead"),
                "selected": true
            ],
            TUIMessageReadViewTag.unread.rawValue: [
                "tag": TUIMessageReadViewTag.unread.rawValue,
                "title": "\(cellData?.messageReceipt?.unreadCount ?? 0)" + TUISwift.timCommonLocalizableString("TUIKitMessageReadPartUnread"),
                "selected": false
            ]
        ]

        if showReadStatusDisable {
            readViews[TUIMessageReadViewTag.readDisable.rawValue] = [
                "tag": TUIMessageReadViewTag.readDisable.rawValue,
                "title": TUISwift.timCommonLocalizableString("TUIKitMessageReadPartDisable"),
                "selected": false
            ]
        }

        return readViews
    }

    var members: [V2TIMGroupMemberInfo?] {
        switch selectedViewTag {
        case .read:
            return readMembers
        case .unread:
            return unreadMembers
        case .readDisable:
            return []
        default:
            return []
        }
    }

    lazy var tableView: UITableView = {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        view.addSubview(tableView)

        let view = UIView(frame: .zero)
        tableView.tableFooterView = view
        tableView.separatorStyle = isGroupMessageRead() ? .singleLine : .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 58, bottom: 0, right: 0)
        tableView.register(TUIMemberCell.self, forCellReuseIdentifier: kMemberCellReuseId)
        return tableView
    }()

    lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
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
            selectedViewTag = .read
            loadMembers()
        } else {
            selectedViewTag = .c2c
        }
        setupViews()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        layoutViews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDismissHandler?()
    }

    deinit {
        print("\(String(describing: self)) dealloc")
    }

    // MARK: - Setup views

    func setupViews() {
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        setupTitleView()
        setupMessageView()
        if isGroupMessageRead() {
            setupSelectView()
        }
        indicatorView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: CGFloat(TMessageController_Header_Height))
        tableView.tableFooterView = indicatorView
    }

    func layoutViews() {
        let content = self.content
        var messageBackViewHeight: CGFloat = 69
        if content is UIImage {
            messageBackViewHeight = 87
        }

        messageBackView?.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.height.equalTo(messageBackViewHeight)
            make.width.equalTo(view)
        }

        // content label may not exist when content is not text
        if let contentLabel = contentLabel {
            contentLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(33)
                make.height.equalTo(24)
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        let readView = layoutSelectView(selectViewsDict[TUIMessageReadViewTag.read.rawValue], leftView: nil)
        let unreadView = layoutSelectView(selectViewsDict[TUIMessageReadViewTag.unread.rawValue], leftView: readView)
        if showReadStatusDisable {
            _ = layoutSelectView(selectViewsDict[TUIMessageReadViewTag.readDisable.rawValue], leftView: unreadView)
        }

        tableView.frame.origin.y = (messageBackView?.frame.maxY ?? 0) + 10 + (selectViewsDict.count > 0 ? 48 : 0)
        tableView.frame.origin.x = 0
        tableView.frame.size.width = view.frame.width
        tableView.frame.size.height = view.frame.height - tableView.frame.origin.y
    }

    func layoutSelectView(_ view: UIView?, leftView: UIView?) -> UIView? {
        guard let view = view else { return nil }

        let count = selectViewsDict.count
        if count == 0 {
            return nil
        }

        view.snp.remakeConstraints { make in
            make.width.equalToSuperview().multipliedBy(1.0 / CGFloat(count))
            make.height.equalTo(48)
            if let leftView = leftView {
                make.leading.equalTo(leftView.snp.trailing)
            } else {
                make.leading.equalToSuperview()
            }
            if let messageBackView = messageBackView {
                make.top.equalTo(messageBackView.snp.bottom).offset(10)
            }
        }

        return view
    }

    func setupTitleView() {
        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitMessageReadDetail")
        titleLabel.font = UIFont.systemFont(ofSize: 18.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
    }

    func setupMessageView() {
        let messageBackView = UIView()
        messageBackView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        view.addSubview(messageBackView)
        self.messageBackView = messageBackView

        let nameLabel = UILabel()
        nameLabel.text = cellData?.senderName ?? ""
        nameLabel.font = UIFont.systemFont(ofSize: 12.0)
        nameLabel.textColor = TUISwift.tuiChatDynamicColor("chat_message_read_name_date_text_color", defaultColor: "#999999")
        nameLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        messageBackView.addSubview(nameLabel)
        nameLabel.sizeToFit()
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(nameLabel.frame.size.width)
            make.height.equalTo(nameLabel.frame.size.height)
        }

        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        let dateString = formatter.string(from: cellData?.innerMessage?.timestamp ?? Date())
        dateLabel.text = dateString
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        dateLabel.textColor = TUISwift.tuiChatDynamicColor("chat_message_read_name_date_text_color", defaultColor: "#999999")
        messageBackView.addSubview(dateLabel)
        dateLabel.sizeToFit()
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(12)
            make.width.equalTo(dateLabel.frame.size.width)
            make.height.equalTo(dateLabel.frame.size.height)
        }

        let content = self.content
        if let contentString = content as? String {
            let contentLabel = UILabel()
            contentLabel.text = contentString
            contentLabel.font = UIFont.systemFont(ofSize: 16)
            contentLabel.textColor = TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#111111")
            contentLabel.lineBreakMode = .byTruncatingTail
            contentLabel.textAlignment = TUISwift.isRTL() ? .right : .left
            self.contentLabel = contentLabel
            messageBackView.addSubview(contentLabel)
        } else if let contentImage = content as? UIImage {
            let imageView = UIImageView()
            imageView.image = contentImage
            messageBackView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(33)
                make.leading.equalToSuperview().offset(16)
                make.width.equalTo(scaledSizeOfImage(contentImage).width)
                make.height.equalTo(scaledSizeOfImage(contentImage).height)
            }
        }
    }

    func setupSelectView() {
        let dataDict = selectViewsData
        let count = dataDict.count
        var selectViewsArray: [TUIMessageReadSelectView] = []
        var tmp: UIView? = nil

        for (_, data) in dataDict {
            if let title = data["title"] as? String,
               let tagValue = data["tag"] as? Int,
               let selected = data["selected"] as? Bool
            {
                let selectView = TUIMessageReadSelectView(title: title, viewTag: TUIMessageReadViewTag(rawValue: tagValue)!, selected: selected)
                selectView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
                selectView.delegate = self
                view.addSubview(selectView)
                selectViewsArray.append(selectView)
                selectViewsDict[data["tag"] as! Int] = selectView

                selectView.frame.size.width = view.frame.width / CGFloat(count)
                selectView.frame.size.height = 48
                selectView.frame.origin.x = tmp == nil ? 0 : tmp!.frame.maxX
                selectView.frame.origin.y = (messageBackView?.frame.maxY ?? 0) + 10

                tmp = selectView
            }
        }
    }

    func loadMembers() {
        getReadMembersWithCompletion { code, _, _, _ in
            if code == 0 {
                self.tableView.reloadData()
            }
        }
        getUnreadMembersWithCompletion { code, _, _, _ in
            if code == 0 {
                self.tableView.reloadData()
            }
        }
    }

    func getReadMembersWithCompletion(completion: @escaping (Int, String, [Any]?, Bool) -> Void) {
        guard let message = cellData?.innerMessage else { return }
        TUIMessageDataProvider.getReadMembersOfMessage(message, filter: .GROUP_MESSAGE_READ_MEMBERS_FILTER_READ, nextSeq: readSeq, completion: { [weak self] code, desc, members, nextSeq, isFinished in
            guard let self else { return }
            if code != 0 {
                completion(code, desc ?? "", nil, false)
                return
            }
            self.readMembers.append(contentsOf: members)
            self.readSeq = isFinished ? UInt.max : nextSeq
            completion(Int(code), desc ?? "", members, isFinished)
        })
    }

    func getUnreadMembersWithCompletion(completion: @escaping (Int, String, [Any]?, Bool) -> Void) {
        guard let message = cellData?.innerMessage else { return }
        TUIMessageDataProvider.getReadMembersOfMessage(message, filter: .GROUP_MESSAGE_READ_MEMBERS_FILTER_UNREAD, nextSeq: readSeq, completion: { [weak self] code, desc, members, nextSeq, isFinished in
            guard let self else { return }
            if code != 0 {
                completion(code, desc ?? "", nil, false)
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
        TUICore.createObject("TUICore_TUIContactObjectFactory", key: "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod", param: param)
    }

    func isGroupMessageRead() -> Bool {
        guard let groupID = cellData?.innerMessage?.groupID else { return false }
        return groupID.count > 0
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isGroupMessageRead() {
            guard indexPath.row < members.count else { return }
            guard let member = members[indexPath.row] else { return }
            getUserOrFriendProfileVCWithUserID(member.userID, succ: { [weak self] vc in
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isGroupMessageRead() ? members.count : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kMemberCellReuseId, for: indexPath) as? TUIMemberCell else {
            return UITableViewCell()
        }
        cell.changeColorWhenTouched = true

        var data = TUIMemberCellData(userID: "", avatarUrl: "")
        if isGroupMessageRead() {
            guard indexPath.row < members.count else {
                return UITableViewCell()
            }
            if let member = members[indexPath.row], let userID = member.userID {
                data = TUIMemberCellData(userID: userID,
                                         nickName: member.nickName ?? "",
                                         friendRemark: member.friendRemark ?? "",
                                         nameCard: member.nameCard ?? "",
                                         avatarUrl: member.faceURL ?? "",
                                         detail: nil)
            }

        } else {
            let detail = (cellData?.messageReceipt?.isPeerRead ?? false) ? TUISwift.timCommonLocalizableString("TUIKitMessageReadC2CRead") : TUISwift.timCommonLocalizableString("TUIKitMessageReadC2CUnReadDetail")
            data = TUIMemberCellData(userID: cellData?.innerMessage?.userID ?? "",
                                     nickName: nil,
                                     friendRemark: c2cReceiverName ?? "",
                                     nameCard: nil,
                                     avatarUrl: c2cReceiverAvatarUrl ?? "",
                                     detail: detail)
        }
        cell.fill(with: data)
        return cell
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y > 0 && scrollView.contentOffset.y >= scrollView.bounds.origin.y else {
            return
        }
        guard !indicatorView.isAnimating else {
            return
        }
        indicatorView.startAnimating()

        switch selectedViewTag {
        case .read:
            getReadMembersWithCompletion { [weak self] _, _, members, _ in
                guard let self = self else { return }
                self.indicatorView.stopAnimating()
                self.refreshTableView()

                if let members = members, members.isEmpty {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitMessageReadNoMoreData"))
                    self.tableView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - CGFloat(TMessageController_Header_Height)), animated: true)
                }
            }
        case .unread:
            getUnreadMembersWithCompletion { [weak self] _, _, members, _ in
                guard let self = self else { return }
                self.indicatorView.stopAnimating()
                self.refreshTableView()

                if let members = members, members.isEmpty {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitMessageReadNoMoreData"))
                    self.tableView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - CGFloat(TMessageController_Header_Height)), animated: true)
                }
            }
        case .readDisable:
            break
        default:
            break
        }
    }

    func refreshTableView() {
        tableView.reloadData()
        tableView.layoutIfNeeded()
    }

    // MARK: - TUIMessageReadSelectViewDelegate

    func messageReadSelectView(_ view: TUIMessageReadSelectView, didSelectItemTag tag: TUIMessageReadViewTag) {
        for case let view as TUIMessageReadSelectView in selectViewsDict.values {
            view.selected = view.tag == tag.rawValue
        }
        selectedViewTag = tag
        tableView.reloadData()
    }

    func scaledSizeOfImage(_ image: UIImage) -> CGSize {
        let portraitOrientations: Set<UIImage.Orientation> = [
            .left, .right, .leftMirrored, .rightMirrored
        ]

        let orientation = image.imageOrientation
        let width = CGFloat(image.cgImage?.width ?? 0)
        let height = CGFloat(image.cgImage?.height ?? 0)

        // Height is fixed at 42.0, and width is proportionally scaled.
        if portraitOrientations.contains(orientation) {
            // UIImage is stored in memory in a fixed size, like 1280 * 720.
            // So we should adapt its size manually according to the direction.
            return CGSize(width: 42.0 * height / width, height: 42.0)
        } else {
            return CGSize(width: 42.0 * width / height, height: 42.0)
        }
    }
}
