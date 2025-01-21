import AssetsLibrary
import AVFoundation
import ImSDK_Plus
import MobileCoreServices
import Photos
import ReactiveObjC
import TIMCommon
import UIKit

public class TUIBaseChatViewController_Minimalist: UIViewController, TUIBaseMessageControllerDelegate_Minimalist, TUIInputControllerDelegate_Minimalist, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate, TUIMessageMultiChooseViewDelegate_Minimalist, TUIChatBaseDataProviderDelegate, TUINotificationProtocol, TUIJoinGroupMessageCellDelegate_Minimalist, V2TIMConversationListener, TUINavigationControllerDelegate, V2TIMSDKListener, TUIChatMediaDataListener, TIMInputViewMoreActionProtocol {
    var kTUIInputNormalFont: UIFont {
        UIFont.systemFont(ofSize: 16)
    }

    var kTUIInputNormalTextColor: UIColor {
        TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000")
    }

    public var highlightKeyword: String?
    public var locateMessage: V2TIMMessage?
    public var messageController: TUIBaseMessageController_Minimalist?

    private var dataProvider: TUIChatDataProvider!
    private var firstAppear: Bool = false
    private var responseKeyboard: Bool = false

    private var titleView: TUINaviBarIndicatorView?
    private var multiChooseView: TUIMessageMultiChooseView_Minimalist?
    private var backgroudView: UIImageView!
    private var avatarView: UIImageView?
    private var mainTitleLabel: UILabel?
    private var subTitleLabel: UILabel?

    private var otherSideTypingObservation: NSKeyValueObservation?
    private var faceUrlObservation: NSKeyValueObservation?

    static var gCustomTopView: UIView?
    static var gTopExtensionView: UIView?
    static var gGroupPinTopView: UIView?
    static var gCustomTopViewRect: CGRect?

    public static var customTopView: UIView? {
        get {
            return gCustomTopView
        } set {
            guard let view = newValue else { return }
            gCustomTopView = view
            gCustomTopViewRect = view.frame
            gCustomTopView!.clipsToBounds = true
        }
    }

    public static var groupPinTopView: UIView? {
        get {
            return gGroupPinTopView
        } set {
            gGroupPinTopView = newValue
        }
    }

    public static func topAreaBottomView() -> UIView? {
        guard let view = gGroupPinTopView else {
            return gCustomTopView ?? gTopExtensionView
        }
        return view
    }

    private var _mediaProvider: TUIChatMediaDataProvider?
    var mediaProvider: TUIChatMediaDataProvider? {
        get {
            if _mediaProvider == nil {
                _mediaProvider = TUIChatMediaDataProvider()
                _mediaProvider?.listener = self
                _mediaProvider?.presentViewController = self
            }
            return _mediaProvider
        }
        set {}
    }

    public var conversationData: TUIChatConversationModel? {
        didSet {
            if let data = conversationData, data.title.isNilOrEmpty || data.faceUrl.isNilOrEmpty {
                checkTitle(force: true)
            }
        }
    }

    public lazy var inputController: TUIInputController_Minimalist = {
        let controller = TUIInputController_Minimalist()
        controller.delegate = self
        controller.view.frame = CGRect(x: 0, y: view.frame.size.height - CGFloat(TTextView_Height) - TUISwift.bottom_SafeHeight(), width: view.frame.size.width, height: CGFloat(TTextView_Height) + TUISwift.bottom_SafeHeight())
        controller.view.autoresizingMask = .flexibleTopMargin
        addChild(controller)
        view.addSubview(controller.view)
        controller.view.isHidden = !TUIChatConfig.shared.enableMainPageInputBar
        return controller
    }()

    // MARK: - Init

    public init() {
        super.init(nibName: nil, bundle: nil)
        createCachePath()
        TUIAIDenoiseSignatureManager.sharedInstance.updateSignature()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTopViewsAndMessagePage), name: Notification.Name(TUICore_TUIChatExtension_ChatViewTopArea_ChangedNotification), object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        otherSideTypingObservation = nil
        faceUrlObservation = nil
    }

    // MARK: - Lift cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTopViews()

        firstAppear = true
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#FFFFFF")
        edgesForExtendedLayout = []

        configBackgroundView()
        configNotify()

        // setup UI
        setupNavigator()
        if let _ = TUIBaseChatViewController_Minimalist.gCustomTopView {
            setupCustomTopView()
        }
        setupMessageController()
        setupInputMoreMenu()
        _ = inputController

        // data provider
        dataProvider = TUIChatDataProvider()
        dataProvider.delegate = self

        V2TIMManager.sharedInstance().add(self)
    }

    override public func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            saveDraft()
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configTopViewsInWillAppear()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        responseKeyboard = true
        if firstAppear == true {
            loadDraft()
            firstAppear = false
        }
        mainTitleLabel?.text = getMainTitleLabelText()
        configHeadImageView(conversationData ?? TUIChatConversationModel())
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        responseKeyboard = false
        openMultiChooseBoard(isOpen: false)
        messageController?.enableMultiSelectedMode(false)
    }

    // MARK: - Setup views and data

    func createCachePath() {
        let fileManager = FileManager.default

        let paths = [
            TUISwift.tuiKit_Image_Path()!,
            TUISwift.tuiKit_Video_Path()!,
            TUISwift.tuiKit_Voice_Path()!,
            TUISwift.tuiKit_File_Path()!,
            TUISwift.tuiKit_DB_Path()!
        ]

        for path in paths {
            do {
                if !fileManager.fileExists(atPath: path) {
                    try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                }
            } catch {
                print("Failed to create directory at path: \(path). Error: \(error)")
            }
        }
    }

    func setupTopViews() {
        if let gTopExtensionView = TUIBaseChatViewController_Minimalist.gTopExtensionView {
            gTopExtensionView.removeFromSuperview()
        } else {
            TUIBaseChatViewController_Minimalist.gTopExtensionView = UIView()
            TUIBaseChatViewController_Minimalist.gTopExtensionView?.clipsToBounds = true
        }

        if let gGroupPinTopView = TUIBaseChatViewController_Minimalist.gGroupPinTopView {
            gGroupPinTopView.removeFromSuperview()
        } else {
            TUIBaseChatViewController_Minimalist.gGroupPinTopView = UIView()
            TUIBaseChatViewController_Minimalist.gGroupPinTopView?.clipsToBounds = true
        }

        if let _ = TUIBaseChatViewController_Minimalist.gTopExtensionView {
            setupTopExtensionView()
        }

        if let gCustomTopView = TUIBaseChatViewController_Minimalist.gCustomTopView {
            setupCustomTopView()
            gCustomTopView.frame = CGRect(x: 0, y: TUIBaseChatViewController_Minimalist.gTopExtensionView?.frame.maxY ?? 0, width: TUIBaseChatViewController_Minimalist.gCustomTopViewRect?.size.width ?? 0, height: TUIBaseChatViewController_Minimalist.gCustomTopViewRect?.size.height ?? 0)
        }

        if let gGroupPinTopView = TUIBaseChatViewController_Minimalist.gGroupPinTopView, let groupID = conversationData?.groupID, !groupID.isEmpty {
            setupGroupPinTopView()
            gGroupPinTopView.frame = CGRect(x: 0, y: TUIBaseChatViewController_Minimalist.gCustomTopView?.frame.maxY ?? 0, width: gGroupPinTopView.frame.size.width, height: gGroupPinTopView.frame.size.height)
        }
    }

    func setupGroupPinTopView() {
        guard let groupPinTopView = TUIBaseChatViewController_Minimalist.gGroupPinTopView else { return }
        if groupPinTopView.superview != view {
            view.addSubview(groupPinTopView)
        }
        groupPinTopView.backgroundColor = UIColor.clear
        groupPinTopView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 0)
    }

    func setupTopExtensionView() {
        if let topExtensionView = TUIBaseChatViewController_Minimalist.gTopExtensionView {
            if topExtensionView.superview != view {
                view.addSubview(topExtensionView)
            }
            topExtensionView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 0)
            var param: [String: Any] = [:]
            if let userID = conversationData?.userID, !userID.isEmpty {
                param[TUICore_TUIChatExtension_ChatViewTopArea_ChatID] = userID
                param[TUICore_TUIChatExtension_ChatViewTopArea_IsGroup] = "0"
            } else if let groupID = conversationData?.groupID, !groupID.isEmpty {
                param[TUICore_TUIChatExtension_ChatViewTopArea_IsGroup] = "1"
                param[TUICore_TUIChatExtension_ChatViewTopArea_ChatID] = groupID
            }

            TUICore.raiseExtension(TUICore_TUIChatExtension_ChatViewTopArea_MinimalistExtensionID, parentView: topExtensionView, param: param)
        }
    }

    func configBackgroundView() {
        backgroudView = UIImageView()
        backgroudView.backgroundColor = TUIChatConfig.shared.backgroudColor ?? TUISwift.tuiChatDynamicColor("chat_controller_bg_color", defaultColor: "#FFFFFF")
        let conversationID = getConversationID()
        let imgUrl = getBackgroundImageUrl(byConversationID: conversationID)

        if TUIChatConfig.shared.backgroudImage != nil {
            backgroudView.backgroundColor = .clear
            backgroudView.image = TUIChatConfig.shared.backgroudImage
        } else if imgUrl != nil {
            backgroudView.sd_setImage(with: URL(string: imgUrl!), placeholderImage: nil)
        }

        let textViewHeight = TUIChatConfig.shared.enableMainPageInputBar ? TTextView_Height : 0
        backgroudView.frame = CGRect(x: 0, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height - CGFloat(textViewHeight) - TUISwift.bottom_SafeHeight())

        view.insertSubview(backgroudView, at: 0)
    }

    func configNotify() {
        V2TIMManager.sharedInstance().addConversationListener(listener: self)
        TUICore.registerEvent(TUICore_TUIConversationNotify, subKey: TUICore_TUIConversationNotify_ClearConversationUIHistorySubKey, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(onFriendInfoChanged(_:)), name: NSNotification.Name("FriendInfoChangedNotification"), object: nil)

        TUICore.registerEvent(TUICore_TUIContactNotify, subKey: TUICore_TUIContactNotify_UpdateConversationBackgroundImageSubKey, object: self)
    }

    func setupNavigator() {
        guard let conversationData = conversationData else { return }

        if let naviController = navigationController as? TUINavigationController {
            naviController.uiNaviDelegate = self
            if let backimg = TUISwift.timCommonDynamicImage("nav_back_img", defaultImage: UIImage(named: TUISwift.timCommonImagePath("nav_back"))) {
                naviController.navigationItemBackArrowImage = backimg.rtl_imageFlippedForRightToLeftLayoutDirection()
            }
        }

        let backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        backButton.addTarget(self, action: #selector(onBackButtonClick), for: .touchUpInside)
        let imgicon = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("vc_back"))
        backButton.setImage(imgicon.rtl_imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        let backButtonItem = UIBarButtonItem(customView: backButton)

        let infoView = UIView(frame: CGRect(x: 0, y: 0, width: TUISwift.kScale390(200), height: 40))
        let tap = UITapGestureRecognizer(target: self, action: #selector(onInfoViewTapped))
        infoView.addGestureRecognizer(tap)

        let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        avatarView.image = conversationData.avatarImage
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2.0
        avatarView.layer.masksToBounds = true
        infoView.addSubview(avatarView)
        self.avatarView = avatarView

        let mainTitleLabel = UILabel(frame: CGRect(x: avatarView.mm_x + avatarView.mm_w + TUISwift.kScale390(8), y: 0, width: TUISwift.kScale390(200), height: 20))
        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        mainTitleLabel.text = getMainTitleLabelText()
        mainTitleLabel.rtlAlignment = TUITextRTLAlignment.leading
        infoView.addSubview(mainTitleLabel)
        self.mainTitleLabel = mainTitleLabel

        subTitleLabel = UILabel(frame: CGRect(x: mainTitleLabel.mm_x, y: 20, width: mainTitleLabel.mm_w, height: 20))
        subTitleLabel!.font = UIFont.systemFont(ofSize: 12)
        subTitleLabel!.rtlAlignment = TUITextRTLAlignment.leading
        updateSubTitleLabelText()
        infoView.addSubview(subTitleLabel!)

        if TUISwift.isRTL() {
            avatarView.resetFrameToFitRTL()
            mainTitleLabel.resetFrameToFitRTL()
            subTitleLabel!.resetFrameToFitRTL()
        }

        otherSideTypingObservation = conversationData.observe(\.otherSideTyping, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            if !newValue {
                self.updateSubTitleLabelText()
            } else {
                let typingText = TUISwift.timCommonLocalizableString("TUIKitTyping") + "..."
                self.subTitleLabel?.text = typingText
            }
        }

        let infoViewItem = UIBarButtonItem(customView: infoView)

        navigationItem.leftBarButtonItems = [backButtonItem, infoViewItem]

        let itemSize = CGSize(width: 30, height: 24)
        var rightBarButtonList = [UIBarButtonItem]()
        var param = [String: Any]()
        if let userID = conversationData.userID, !userID.isEmpty {
            param[TUICore_TUIChatExtension_NavigationMoreItem_UserID] = userID
        } else if let groupID = conversationData.groupID, !groupID.isEmpty {
            param[TUICore_TUIChatExtension_NavigationMoreItem_GroupID] = groupID
        }
        param[TUICore_TUIChatExtension_NavigationMoreItem_ItemSize] = itemSize
        param[TUICore_TUIChatExtension_NavigationMoreItem_FilterVideoCall] = !TUIChatConfig.shared.enableVideoCall
        param[TUICore_TUIChatExtension_NavigationMoreItem_FilterAudioCall] = !TUIChatConfig.shared.enableAudioCall

        let extensionList: [TUIExtensionInfo]? = TUICore.getExtensionList(TUICore_TUIChatExtension_NavigationMoreItem_MinimalistExtensionID, param: param)
        if let extensionList = extensionList {
            for info in extensionList {
                if let icon = info.icon, let _ = info.onClicked {
                    let button = UIButton(frame: CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height))
                    button.tui_extValueObj = info
                    button.addTarget(self, action: #selector(rightBarButtonClick(_:)), for: .touchUpInside)
                    button.setImage(icon, for: .normal)
                    let rightItem = UIBarButtonItem(customView: button)
                    rightBarButtonList.append(rightItem)
                }
            }
        }

        if rightBarButtonList.count > 0 {
            navigationItem.rightBarButtonItems = rightBarButtonList.reversed()
        }
    }

    func setupCustomTopView() {
        guard let customTopView = TUIBaseChatViewController_Minimalist.gCustomTopView else { return }
        view.addSubview(customTopView)
    }

    func setupMessageController() {
        guard let conversationData = conversationData else { return }
        let vc = TUIMessageController_Minimalist()
        vc.highlightKeyword = highlightKeyword
        vc.locateMessage = locateMessage
        vc.isMsgNeedReadReceipt = conversationData.msgNeedReadReceipt && TUIChatConfig.shared.msgNeedReadReceipt
        messageController = vc
        messageController!.delegate = self
        messageController!.setConversation(conversationData: conversationData)

        let textViewHeight = TUIChatConfig.shared.enableMainPageInputBar ? TTextView_Height : 0
        let height = view.frame.size.height - CGFloat(textViewHeight) - TUISwift.bottom_SafeHeight() - topMarginByCustomView()
        messageController!.view.frame = CGRect(x: 0, y: topMarginByCustomView(), width: view.frame.size.width,
                                               height: height)

        addChild(messageController!)
        view.addSubview(messageController!.view)
        messageController!.didMove(toParent: self)
    }

    func setupInputMoreMenu() {
        guard let conversationData = conversationData else { return }
        guard let dataSource = TUIChatConfig.shared.inputBarDataSource else { return }
        let tag = dataSource.shouldHideItems(of: conversationData)
        conversationData.enableFile = !(tag.contains(TUIChatInputBarMoreMenuItem.file))
        conversationData.enableAlbum = !(tag.contains(TUIChatInputBarMoreMenuItem.album))
        conversationData.enableTakePhoto = !(tag.contains(TUIChatInputBarMoreMenuItem.takePhoto))
        conversationData.enableRecordVideo = !(tag.contains(TUIChatInputBarMoreMenuItem.recordVideo))
        conversationData.enableWelcomeCustomMessage = !(tag.contains(TUIChatInputBarMoreMenuItem.customMessage))

        if let items = dataSource.shouldAddNewItems(of: conversationData) {
            conversationData.customizedNewItemsInMoreMenu = items
        }
    }

    func configTopViewsInWillAppear() {
        if let customTopView = TUIBaseChatViewController_Minimalist.gCustomTopView, customTopView.superview != view {
            if customTopView.frame == .zero,
               let topExtensionView = TUIBaseChatViewController_Minimalist.gTopExtensionView,
               let customTopViewRect = TUIBaseChatViewController_Minimalist.gCustomTopViewRect
            {
                customTopView.frame = CGRect(
                    x: 0, y: topExtensionView.frame.maxY, width: customTopViewRect.width,
                    height: customTopViewRect.height
                )
            }
            view.addSubview(customTopView)
        }

        if let topExtensionView = TUIBaseChatViewController_Minimalist.gTopExtensionView, topExtensionView.superview != view {
            view.addSubview(topExtensionView)
        }

        if let groupID = conversationData?.groupID, !groupID.isEmpty {
            if let groupPinTopView = TUIBaseChatViewController_Minimalist.gGroupPinTopView, groupPinTopView.superview != view {
                view.addSubview(groupPinTopView)
            }
        }

        reloadTopViewsAndMessagePage()
    }

    func loadDraft() {
        guard let draft = conversationData?.draftText, !draft.isEmpty else { return }
        do {
            if let data = draft.data(using: .utf8), let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let draftContent = jsonDict["content"] as? String ?? ""
                let formatEmojiString = draftContent.getAdvancedFormatEmojiString(with: kTUIInputNormalFont, textColor: kTUIInputNormalTextColor, emojiLocations: nil)
                inputController.inputBar?.addDraftToInputBar(formatEmojiString)

                if let messageRootID = jsonDict["messageRootID"] as? String,
                   let reply = jsonDict["messageReply"] as? [String: Any],
                   reply.keys.contains("messageID"),
                   reply.keys.contains("messageAbstract"),
                   reply.keys.contains("messageSender"),
                   reply.keys.contains("messageType"),
                   reply.keys.contains("version")
                {
                    if let version = reply["version"] as? Int, version <= kDraftMessageReplyVersion {
                        if !messageRootID.isEmpty {
                            let replyPreviewData = TUIReplyPreviewData()
                            replyPreviewData.msgID = reply["messageID"] as? String ?? ""
                            replyPreviewData.msgAbstract = reply["messageAbstract"] as? String ?? ""
                            replyPreviewData.sender = reply["messageSender"] as? String ?? ""
                            replyPreviewData.type = reply["messageType"] as? V2TIMElemType ?? V2TIMElemType.ELEM_TYPE_NONE
                            replyPreviewData.messageRootID = messageRootID
                            inputController.showReplyPreview(replyPreviewData)
                        } else {
                            let referencePreviewData = TUIReferencePreviewData()
                            referencePreviewData.msgID = reply["messageID"] as? String ?? ""
                            referencePreviewData.msgAbstract = reply["messageAbstract"] as? String ?? ""
                            referencePreviewData.sender = reply["messageSender"] as? String ?? ""
                            referencePreviewData.type = reply["messageType"] as? V2TIMElemType ?? V2TIMElemType.ELEM_TYPE_NONE
                            inputController.showReferencePreview(referencePreviewData)
                        }
                    }
                }
            }
        } catch {
            let formatEmojiString = draft.getAdvancedFormatEmojiString(with: kTUIInputNormalFont, textColor: kTUIInputNormalTextColor, emojiLocations: nil)
            inputController.inputBar?.addDraftToInputBar(formatEmojiString)
        }
    }

    func saveDraft() {
        guard let conversationData = conversationData else { return }
        var content = inputController.inputBar?.inputTextView.textStorage.tui_getPlainString()

        var previewData: TUIReplyPreviewData? = nil
        if let referenceData = inputController.referenceData {
            previewData = referenceData
        } else if let replyData = inputController.replyData {
            previewData = replyData
        }

        if let previewData = previewData {
            let dict: [String: Any] = [
                "content": content ?? "",
                "messageReply": [
                    "messageID": previewData.msgID ?? "",
                    "messageAbstract": (previewData.msgAbstract ?? "").getInternationalStringWithfaceContent(),
                    "messageSender": previewData.sender ?? "",
                    "messageType": previewData.type.rawValue,
                    "messageTime": previewData.originMessage?.timestamp?.timeIntervalSince1970 ?? 0, // Compatible for web
                    "messageSequence": previewData.originMessage?.seq ?? 0, // Compatible for web
                    "version": kDraftMessageReplyVersion
                ]
            ]

            var mutableDict = dict
            if let rootID = previewData.messageRootID, !rootID.isEmpty {
                mutableDict["messageRootID"] = rootID
            }
            do {
                let data = try JSONSerialization.data(withJSONObject: mutableDict, options: [])
                content = String(data: data, encoding: .utf8)
            } catch {
                print("Error serializing dictionary: \(error)")
            }
        }

        if let conversationID = conversationData.conversationID, let text = content {
            TUIChatDataProvider.saveDraft(withConversationID: conversationID, text: text)
        }
    }

    func getMainTitleLabelText() -> String {
        guard let conversationData = conversationData else { return "" }
        if let title = conversationData.title, !title.isEmpty {
            return title
        } else if let groupID = conversationData.groupID, !groupID.isEmpty {
            return groupID
        } else if let userID = conversationData.userID, !userID.isEmpty {
            return userID
        }
        return ""
    }

    func updateSubTitleLabelText() {
        if !TUIConfig.default().displayOnlineStatusIcon {
            subTitleLabel?.text = ""
            return
        }

        guard let conversationData = conversationData else { return }
        if let userID = conversationData.userID, !userID.isEmpty {
            V2TIMManager.sharedInstance().getUserStatus([userID]) { [weak self] result in
                guard let self = self, let status = result?.first else { return }
                self.subTitleLabel?.text = self.getUserStatus(status)
            } fail: { _, _ in }
        } else if let groupID = conversationData.groupID, !groupID.isEmpty {
            let filter: V2TIMGroupMemberFilter = .GROUP_MEMBER_FILTER_ALL
            let filterValue = UInt32(filter.rawValue)
            V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: filterValue, nextSeq: 0) { [weak self] _, memberList in
                guard let self = self else { return }
                let title = NSMutableString()
                var memberCount = 0
                for info in memberList ?? [] {
                    let name = info.nameCard ?? info.nickName ?? info.userID
                    if let name = name {
                        title.append("\(name)，")
                    }
                    memberCount += 1
                    if memberCount >= 5 {
                        break
                    }
                }
                if title.length > 0 {
                    title.deleteCharacters(in: NSRange(location: title.length - 1, length: 1))
                }
                self.subTitleLabel?.text = title as String
            } fail: { _, _ in }
        }
    }

    func getUserStatus(_ status: V2TIMUserStatus) -> String {
        var title: String?
        switch status.statusType {
        case .USER_STATUS_UNKNOWN:
            title = TUISwift.timCommonLocalizableString("TUIKitUserStatusUnknown")
        case .USER_STATUS_ONLINE:
            title = TUISwift.timCommonLocalizableString("TUIKitUserStatusOnline")
        case .USER_STATUS_OFFLINE:
            title = TUISwift.timCommonLocalizableString("TUIKitUserStatusOffline")
        case .USER_STATUS_UNLOGINED:
            title = TUISwift.timCommonLocalizableString("TUIKitUserStatusUnlogined")
        default:
            break
        }
        return title ?? ""
    }

    func configHeadImageView(_ convData: TUIChatConversationModel) {
        if let groupID = convData.groupID, let groupType = convData.groupType, groupID.count > 0 {
            convData.avatarImage = TUIGroupAvatar.getNormalGroupCacheAvatar(groupID, groupType: groupType)
        }

        faceUrlObservation = convData.observe(\.faceUrl, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            let groupID = convData.groupID
            let pFaceUrl = convData.faceUrl
            let groupType = convData.groupType
            var originAvatarImage: UIImage = convData.avatarImage ?? TUISwift.defaultAvatarImage()
            if let groupID = convData.groupID, groupID.count > 0 {
                originAvatarImage = convData.avatarImage ?? TUISwift.defaultGroupAvatarImage(byGroupType: groupType)
            }
            let param: [String: Any] = [
                "groupID": groupID ?? "",
                "faceUrl": pFaceUrl ?? "",
                "groupType": groupType ?? "",
                "originAvatarImage": originAvatarImage
            ]
            TUIGroupAvatar.configAvatar(byParam: param, targetView: self.avatarView ?? UIImageView())
        }
    }

    @objc func reloadTopViewsAndMessagePage() {
        TUIBaseChatViewController_Minimalist.gCustomTopView?.frame = CGRect(x: 0, y: TUIBaseChatViewController_Minimalist.gTopExtensionView?.frame.maxY ?? 0, width: TUIBaseChatViewController_Minimalist.gCustomTopView?.frame.width ?? 0, height: TUIBaseChatViewController_Minimalist.gCustomTopView?.frame.height ?? 0)

        if let groupPinTopView = TUIBaseChatViewController_Minimalist.gGroupPinTopView {
            groupPinTopView.frame = CGRect(x: 0, y: TUIBaseChatViewController_Minimalist.gCustomTopView?.frame.maxY ?? 0, width: groupPinTopView.frame.width, height: groupPinTopView.frame.height)
        }

        let topMarginByCustomView = topMarginByCustomView()
        let textViewHeight = TUIChatConfig.shared.enableMainPageInputBar ? TTextView_Height : 0
        messageController?.view.frame = CGRect(x: 0, y: topMarginByCustomView, width: view.bounds.width,
                                               height: view.bounds.height - CGFloat(textViewHeight) - TUISwift.bottom_SafeHeight() - topMarginByCustomView)

        messageController?.scrollToBottom(true)
    }

    private func topMarginByCustomView() -> CGFloat {
        let customTopViewHeight = TUIBaseChatViewController_Minimalist.customTopView?.superview != nil ? TUIBaseChatViewController_Minimalist.customTopView!.frame.height : 0
        let topExtsionHeight = TUIBaseChatViewController_Minimalist.gTopExtensionView?.superview != nil ? TUIBaseChatViewController_Minimalist.gTopExtensionView!.frame.height : 0
        let groupPinTopViewHeight = TUIBaseChatViewController_Minimalist.groupPinTopView?.superview != nil ? TUIBaseChatViewController_Minimalist.groupPinTopView!.frame.height : 0

        let height = customTopViewHeight + topExtsionHeight + groupPinTopViewHeight
        return height
    }

    // MARK: - Event

    public func send(_ message: V2TIMMessage) {
        messageController?.sendMessage(message)
    }

    public func sendMessage(_ message: V2TIMMessage, placeHolderCellData: TUIMessageCellData?) {
        messageController?.sendMessage(message, placeHolderCellData: placeHolderCellData)
    }

    func checkTitle(force: Bool) {
        guard let conversationData = conversationData else { return }
        if force || conversationData.title.isNilOrEmpty {
            if let userID = conversationData.userID, !userID.isEmpty {
                if conversationData.title.isNilOrEmpty {
                    conversationData.title = userID
                }
                TUIChatDataProvider.getFriendInfo(withUserId: userID, succ: { [weak self] friendInfoResult in
                    guard let self else { return }
                    if (friendInfoResult.relation.rawValue & V2TIMFriendRelationType.FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST.rawValue) == 1,
                       let friendInfo = friendInfoResult.friendInfo, let friendRemark = friendInfo.friendRemark,
                       let userFullInfo = friendInfo.userFullInfo
                    {
                        self.conversationData?.title = friendRemark
                        self.conversationData?.faceUrl = userFullInfo.faceURL.safeValue
                    } else {
                        TUIChatDataProvider.getUserInfo(withUserId: userID, succ: { userInfo in
                            if !userInfo.nickName.isNilOrEmpty {
                                self.conversationData?.title = userInfo.nickName.safeValue
                                self.conversationData?.faceUrl = userInfo.faceURL.safeValue
                            }
                        }, fail: { _, _ in })
                    }
                }, fail: { _, _ in })
            } else if let groupID = conversationData.groupID, !groupID.isEmpty {
                TUIChatDataProvider.getGroupInfo(withGroupID: groupID) { [weak self] groupResult in
                    guard let self else { return }
                    if let info = groupResult.info, let groupName = info.groupName {
                        self.conversationData?.title = groupName
                        self.conversationData?.faceUrl = info.faceURL.safeValue
                        self.conversationData?.groupType = info.groupType.safeValue
                    }
                } fail: { _, _ in }
            }
        }
    }

    @objc func onBackButtonClick() {
        messageController?.readReport()
        navigationController?.popViewController(animated: true)
    }

    @objc func onInfoViewTapped() {
        inputController.reset()
        guard let conversationData = conversationData else { return }
        if let userID = conversationData.userID, !userID.isEmpty {
            getUserOrFriendProfileVCWithUserID(userID, succBlock: { [weak self] vc in
                guard let self = self else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            }, failBlock: { code, desc in
                TUITool.makeToastError(code, msg: desc)
            })
        } else {
            if let groupID = conversationData.groupID {
                let param = [TUICore_TUIContactObjectFactory_GetGroupInfoVC_GroupID: groupID]
                navigationController?.push(TUICore_TUIContactObjectFactory_GetGroupInfoVC_Minimalist, param: param, forResult: nil)
            }
        }
    }

    @objc func rightBarButtonClick(_ button: UIButton) {
        guard let info = button.tui_extValueObj as? TUIExtensionInfo, let onClicked = info.onClicked else {
            return
        }

        var param: [String: Any] = [:]
        if let userID = conversationData?.userID, !userID.isEmpty {
            param[TUICore_TUIChatExtension_NavigationMoreItem_UserID] = userID
        } else if let groupID = conversationData?.groupID, !groupID.isEmpty {
            param[TUICore_TUIChatExtension_NavigationMoreItem_GroupID] = groupID
        }

        if let navigationController = navigationController {
            param[TUICore_TUIChatExtension_NavigationMoreItem_PushVC] = navigationController
        }

        onClicked(param)
    }

    func getUserOrFriendProfileVCWithUserID(_ userID: String, succBlock: @escaping (UIViewController) -> Void, failBlock: @escaping (Int, String) -> Void) {
        let param: [String: Any] = [
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey: userID,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey: succBlock,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey: failBlock
        ]

        TUICore.createObject(TUICore_TUIContactObjectFactory_Minimalist, key: TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod, param: param)
    }

    // MARK: - TUICore Notify

    public func onNotifyEvent(_ key: String, subKey: String, object anObject: Any?, param: [AnyHashable: Any]?) {
        if key == TUICore_TUIConversationNotify && subKey == TUICore_TUIConversationNotify_ClearConversationUIHistorySubKey {
            messageController?.clearUImsg()
        } else if key == TUICore_TUIContactNotify && subKey == TUICore_TUIContactNotify_UpdateConversationBackgroundImageSubKey {
            if let conversationID = param?[TUICore_TUIContactNotify_UpdateConversationBackgroundImageSubKey_ConversationID] as? String, !conversationID.isEmpty {
                updateBackgroundImageUrl(byConversationID: conversationID)
            }
        }
    }

    func updateBackgroundImageUrl(byConversationID conversationID: String) {
        if getConversationID() == conversationID {
            backgroudView?.backgroundColor = .clear
            if let imgUrl = getBackgroundImageUrl(byConversationID: conversationID) {
                backgroudView?.sd_setImage(with: URL(string: imgUrl), placeholderImage: nil)
            } else {
                backgroudView?.image = nil
            }
        }
    }

    func getBackgroundImageUrl(byConversationID targerConversationID: String) -> String? {
        guard !targerConversationID.isEmpty else { return nil }
        let dict = UserDefaults.standard.dictionary(forKey: "conversation_backgroundImage_map") ?? [:]
        let conversationID_UserID = "\(targerConversationID)_\(TUILogin.getUserID() ?? "")"
        guard dict is [String: String] && dict.keys.contains(conversationID_UserID) else { return nil }
        return dict[conversationID_UserID] as? String
    }

    func getConversationID() -> String {
        guard let conversationData = conversationData else { return "" }

        var conversationID = ""
        if let conversationIDValue = conversationData.conversationID, !conversationIDValue.isEmpty {
            conversationID = conversationIDValue
        } else if let userID = conversationData.userID, !userID.isEmpty {
            conversationID = "c2c_\(userID)"
        } else if let groupID = conversationData.groupID, !groupID.isEmpty {
            conversationID = "group_\(groupID)"
        }
        return conversationID
    }

    // MARK: - V2TIMSDKListener

    public func onUserStatusChanged(_ userStatusList: [V2TIMUserStatus]?) {
        guard let userID = conversationData?.userID else { return }

        if let statusList = userStatusList {
            for status in statusList {
                if status.userID == userID {
                    subTitleLabel?.text = getUserStatus(status)
                    break
                }
            }
        }
    }

    // MARK: - TUIInputControllerDelegate

    func inputController(_ inputController: TUIInputController_Minimalist, didChangeHeight height: CGFloat) {
        guard responseKeyboard else { return }

        guard let messageController = messageController else { return }
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            var msgFrame = messageController.view.frame
            msgFrame.size.height = self.view.frame.size.height - height - self.topMarginByCustomView()
            messageController.view.frame = msgFrame

            var inputFrame = self.inputController.view.frame
            inputFrame.origin.y = msgFrame.origin.y + msgFrame.size.height
            inputFrame.size.height = height
            self.inputController.view.frame = inputFrame
            messageController.scrollToBottom(false)
        }, completion: nil)
    }

    func inputController(_ inputController: TUIInputController_Minimalist, didSendMessage message: V2TIMMessage) {
        messageController?.sendMessage(message)
    }

    func inputControllerDidSelectMoreButton(_ inputController: TUIInputController_Minimalist) {
        guard let conversationData = conversationData else { return }
        if let userID = conversationData.userID, let groupID = conversationData.groupID {
            let items = dataProvider.getInputMoreActionItemList(userID: userID,
                                                                groupID: groupID,
                                                                conversationModel: conversationData,
                                                                pushVC: navigationController,
                                                                actionController: self)
            if !items.isEmpty {
                let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertVC.configItems(items)
                alertVC.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .cancel, handler: nil))
                present(alertVC, animated: true, completion: nil)
            }
        }
    }

    func inputControllerDidSelectCamera(_ inputController: TUIInputController_Minimalist) {
        mediaProvider?.takePicture()
    }

    func inputControllerDidInputAt(_ inputController: TUIInputController_Minimalist) {
        // Override by GroupChatVC
    }

    func inputController(_ inputController: TUIInputController_Minimalist, didDeleteAt atText: String) {
        // Override by GroupChatVC
    }

    func inputControllerDidBeginTyping(_ inputController: TUIInputController_Minimalist) {
        // Override by C2CChatVC
    }

    func inputControllerDidEndTyping(_ inputController: TUIInputController_Minimalist) {
        // Override by C2CChatVC
    }

    // MARK: - TUIBaseMessageControllerDelegate_Minimalist

    func didTap(_ controller: TUIBaseMessageController_Minimalist) {
        inputController.reset()
    }

    func willShowMenu(_ controller: TUIBaseMessageController_Minimalist, inCell cell: TUIMessageCell) -> Bool {
        if (inputController.inputBar?.inputTextView.isFirstResponder) != nil {
            inputController.inputBar?.inputTextView.overrideNextResponder = cell
            return true
        }
        return false
    }

    func onNewMessage(_ controller: TUIBaseMessageController_Minimalist?, message: V2TIMMessage) -> TUIMessageCellData? {
        return nil
    }

    func onShowMessageData(_ controller: TUIBaseMessageController_Minimalist?, data: TUIMessageCellData) -> TUIMessageCell? {
        return nil
    }

    func willDisplayCell(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell, withData cellData: TUIMessageCellData) {
        if let joinCell = cell as? TUIJoinGroupMessageCell_Minimalist {
            joinCell.joinGroupDelegate = self
        }
    }

    func onSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell) {
        var userID: String? = nil
        if !cell.messageData.innerMessage.groupID.isNilOrEmpty {
            userID = cell.messageData.innerMessage.sender.safeValue
        } else {
            if cell.messageData.isUseMsgReceiverAvatar {
                if cell.messageData.innerMessage.isSelf {
                    userID = cell.messageData.innerMessage.userID.safeValue
                } else {
                    userID = V2TIMManager.sharedInstance().getLoginUser()
                }
            } else {
                userID = cell.messageData.innerMessage.sender.safeValue
            }
        }

        if let userID = userID {
            getUserOrFriendProfileVCWithUserID(userID, succBlock: { [weak self] vc in
                guard let self = self else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            }, failBlock: { _, desc in
                print(desc)
            })
        }
    }

    func onSelectMessageContent(_ controller: TUIBaseMessageController_Minimalist?, cell: TUIMessageCell) {
        cell.disableDefaultSelectAction = false
        if cell.disableDefaultSelectAction {
            return
        }
    }

    func onSelectMessageMenu(_ controller: TUIBaseMessageController_Minimalist, menuType: NSInteger, withData data: TUIMessageCellData?) {
        onSelectMessageMenu(menuType: menuType, withData: data)
    }

    func didHideMenu(_ controller: TUIBaseMessageController_Minimalist) {
        inputController.inputBar?.inputTextView.overrideNextResponder = nil
    }

    func getTopMarginByCustomView() -> CGFloat {
        return topMarginByCustomView()
    }

    func onReEditMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {
        if let message = data?.innerMessage, message.elemType == V2TIMElemType.ELEM_TYPE_TEXT, let textElem = message.textElem {
            inputController.inputBar?.inputTextView.text = textElem.text
            inputController.inputBar?.inputTextView.becomeFirstResponder()
        }
    }

    func onSelectMessageWhenMultiCheckboxAppear(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {
        if let multiChooseView = multiChooseView,
           let uiMsgs = messageController?.multiSelectedResult(TUIMultiResultOption.all)
        {
            multiChooseView.selectedCountLabel?.text = "\(uiMsgs.count)" + TUISwift.timCommonLocalizableString("TUIKitSelected")
        }
    }

    // MARK: - TUIChatBaseDataProviderDelegate

    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardTitleWithMyName name: String) -> String {
        return forwardTitleWithMyName(name)
    }

    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardMsgAbstactForMessage message: V2TIMMessage) -> String {
        return ""
    }

    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, sendMessage message: V2TIMMessage) {
        messageController?.sendMessage(message)
    }

    func onSelectPhotoMoreCellData() {
        mediaProvider?.selectPhoto()
    }

    func onTakePictureMoreCellData() {
        mediaProvider?.takePicture()
    }

    func onTakeVideoMoreCellData() {
        mediaProvider?.takeVideo()
    }

    func onSelectFileMoreCellData() {
        mediaProvider?.selectFile()
    }

    // MARK: - TUINavigationControllerDelegate

    public func navigationControllerDidClickLeftButton(_ controller: TUINavigationController) {
        if controller.currentShowVC == self {
            messageController?.readReport()
        }
    }

    public func navigationControllerDidSideSlideReturn(_ controller: TUINavigationController, from fromViewController: UIViewController) {
        if fromViewController == self {
            messageController?.readReport()
        }
    }

    // MARK: - Message menu

    func onSelectMessageMenu(menuType: Int, withData data: TUIMessageCellData?) {
        if menuType == 0 {
            openMultiChooseBoard(isOpen: true)
        } else if menuType == 1, let data = data {
            let uiMsgs = [TUIMessageCellData](arrayLiteral: data)
            prepareForwardMessages(uiMsgs)
        }
    }

    func openMultiChooseBoard(isOpen: Bool) {
        view.endEditing(true)

        multiChooseView?.removeFromSuperview()

        if isOpen {
            multiChooseView = TUIMessageMultiChooseView_Minimalist()
            multiChooseView!.frame = UIScreen.main.bounds
            multiChooseView!.delegate = self
            multiChooseView!.titleLabel?.text = conversationData?.title ?? ""
            multiChooseView!.selectedCountLabel?.text = "1" + TUISwift.timCommonLocalizableString("TUIKitSelected")

            if #available(iOS 12.0, *) {
                if #available(iOS 13.0, *) {
                    TUITool.applicationKeywindow()?.addSubview(multiChooseView!)
                } else {
                    let view = navigationController?.view ?? self.view
                    view?.addSubview(multiChooseView!)
                }
            } else {
                UIApplication.shared.keyWindow?.addSubview(multiChooseView!)
            }
        } else {
            messageController?.enableMultiSelectedMode(false)
        }
    }

    // MARK: - TUIMessageMultiChooseViewDelegate_Minimalist

    func onCancelClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist) {
        openMultiChooseBoard(isOpen: false)
        messageController?.enableMultiSelectedMode(false)
    }

    func onRelayClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist) {
        if let uiMsgs = messageController?.multiSelectedResult(TUIMultiResultOption.all) {
            prepareForwardMessages(uiMsgs)
        }
    }

    func onDeleteClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist) {
        guard let uiMsgs = messageController?.multiSelectedResult(.all), !uiMsgs.isEmpty else {
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitRelayNoMessageTips"))
            return
        }
        messageController?.deleteMessages(uiMsgs)
        openMultiChooseBoard(isOpen: false)
        messageController?.enableMultiSelectedMode(false)
    }

    public func prepareForwardMessages(_ uiMsgs: [TUIMessageCellData]) {
        guard !uiMsgs.isEmpty else {
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitRelayNoMessageTips"))
            return
        }
        var hasUnsupportMsg = false
        for data in uiMsgs {
            if data.status != .Msg_Status_Succ {
                hasUnsupportMsg = true
                break
            }
        }
        if hasUnsupportMsg {
            let vc = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitRelayUnsupportForward"), message: nil, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Confirm"), style: .default, handler: nil))
            present(vc, animated: true, completion: nil)
            return
        }

        let tipsVc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        tipsVc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitRelayOneByOneForward"), style: .default, handler: { [weak self] _ in
            guard let self else { return }
            if uiMsgs.count <= 30 {
                self.selectTarget(false, toForwardMessage: uiMsgs, orForwardText: nil)
                return
            }
            let vc = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitRelayOneByOnyOverLimit"), message: nil, preferredStyle: .alert)
            vc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .default, handler: nil))
            vc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitRelayCombineForwad"), style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self.selectTarget(true, toForwardMessage: uiMsgs, orForwardText: nil)
            }))
            self.present(vc, animated: true, completion: nil)
        }))
        tipsVc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitRelayCombineForwad"), style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.selectTarget(true, toForwardMessage: uiMsgs, orForwardText: nil)
        }))
        tipsVc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .cancel, handler: nil))
        present(tipsVc, animated: true, completion: nil)
    }

    private func selectTarget(_ mergeForward: Bool, toForwardMessage uiMsgs: [TUIMessageCellData]?, orForwardText forwardText: String?) {
        if let vc = TUICore.createObject(TUICore_TUIConversationObjectFactory_Minimalist,
                                         key: TUICore_TUIConversationObjectFactory_ConversationSelectVC_Minimalist,
                                         param: nil) as? (UIViewController & TUIFloatSubViewControllerProtocol)
        {
            vc.navigateValueCallback = { [weak self] param in
                guard let self else { return }
                guard let selectList = param[TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList] as? [NSDictionary], !selectList.isEmpty else { return }
                var targetList = [TUIChatConversationModel]()
                for selectItem in selectList {
                    let model = TUIChatConversationModel()
                    model.title = selectItem[TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_Title] as? String ?? ""
                    model.userID = selectItem[TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_UserID] as? String ?? ""
                    model.groupID = selectItem[TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_GroupID] as? String ?? ""
                    model.conversationID = selectItem[TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_ConversationID] as? String ?? ""
                    targetList.append(model)
                }
                if let msgs = uiMsgs, msgs.count > 0 {
                    self.forwardMessages(msgs, toTargets: targetList, merge: mergeForward)
                } else if let text = forwardText, !text.isEmpty {
                    self.forwardText(text, toConversations: targetList)
                }
            }

            let floatVC = TUIFloatViewController()
            floatVC.appendChildViewController(vc, topMargin: TUISwift.kScale390(87.5))
            floatVC.topGestureView.setTitleText("", subTitleText: "", leftBtnText: TUISwift.timCommonLocalizableString("TUIKitCreateCancel"), rightBtnText: TUISwift.timCommonLocalizableString("MultiSelect"))
            floatVC.topGestureView.subTitleLabel.isHidden = true
            present(floatVC, animated: true) { [weak self] in
                guard let self else { return }
                self.openMultiChooseBoard(isOpen: false)
                self.messageController?.enableMultiSelectedMode(false)
            }
        }
    }

    private func forwardMessages(_ uiMsgs: [TUIMessageCellData], toTargets targets: [TUIChatConversationModel], merge: Bool) {
        guard !uiMsgs.isEmpty, !targets.isEmpty else { return }
        dataProvider.getForwardMessage(withCellDatas: uiMsgs, toTargets: targets, merge: merge, resultBlock: { [weak self] targetConversation, msgs in
            guard let self else { return }

            let convCellData = targetConversation
            let timeInterval = (convCellData.groupID?.count ?? 0) > 0 ? 0.09 : 0.05

            let appendParams = TUISendMessageAppendParams()
            appendParams.isSendPushInfo = true
            appendParams.isOnlineUserOnly = false
            appendParams.priority = .PRIORITY_NORMAL

            // Forward to current chat.
            if convCellData.conversationID == self.conversationData?.conversationID {
                let semaphore = DispatchSemaphore(value: 0)
                let queue = DispatchQueue.global(qos: .default)
                queue.async {
                    for imMsg in msgs {
                        DispatchQueue.main.async {
                            self.messageController?.sendMessage(imMsg)
                            semaphore.signal()
                        }
                        semaphore.wait()
                        Thread.sleep(forTimeInterval: timeInterval)
                    }
                }
                return
            }

            // Forward to other chats.
            for message in msgs {
                message.needReadReceipt = (self.conversationData?.msgNeedReadReceipt ?? false) && TUIChatConfig.shared.msgNeedReadReceipt
                _ = TUIMessageDataProvider.sendMessage(message, toConversation: convCellData, appendParams: appendParams, Progress: nil, SuccBlock: {
                    // Messages sent to other chats need to broadcast the message sending status, which is convenient to refresh the message status after entering the corresponding chat
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: TUIKitNotification_onMessageStatusChanged), object: message)
                }, FailBlock: { _, _ in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: TUIKitNotification_onMessageStatusChanged), object: message)
                })
                Thread.sleep(forTimeInterval: timeInterval)
            }
        }, fail: { _, desc in
            assertionFailure(desc ?? "")
        })
    }

    public func forwardTitleWithMyName(_ nameStr: String) -> String {
        return ""
    }

    // MARK: Message reply

    public func onRelyMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {
        inputController.exitReplyAndReference { [weak self] in
            guard let self, let data = data else { return }
            let desc = self.replyReferenceMessageDesc(data)

            let replyData = TUIReplyPreviewData()
            replyData.msgID = data.msgID
            replyData.msgAbstract = desc
            replyData.sender = data.senderName
            replyData.type = data.innerMessage.elemType
            replyData.originMessage = data.innerMessage

            var cloudResultDic = [AnyHashable: Any]()
            if let cloudCustomData = data.innerMessage.cloudCustomData as Data?,
               let originDic = TUITool.jsonData2Dictionary(cloudCustomData)
            {
                cloudResultDic.merge(originDic) { current, _ in current }
            }
            if let messageParentReply = cloudResultDic["messageReply"] as? [String: Any],
               let messageRootID = messageParentReply["messageRootID"] as? String, !messageRootID.isEmpty
            {
                replyData.messageRootID = messageRootID
            } else if let originMessageID = replyData.originMessage?.msgID, !originMessageID.isEmpty {
                replyData.messageRootID = originMessageID
            }

            self.inputController.showReplyPreview(replyData)
        }
    }

    private func replyReferenceMessageDesc(_ data: TUIMessageCellData) -> String {
        var desc = ""
        switch data.innerMessage.elemType {
        case .ELEM_TYPE_FILE:
            if let fileElem = data.innerMessage.fileElem {
                desc = fileElem.filename.safeValue
            }
        case .ELEM_TYPE_MERGER:
            if let mergerElem = data.innerMessage.mergerElem {
                desc = mergerElem.title.safeValue
            }
        case .ELEM_TYPE_CUSTOM:
            desc = TUIMessageDataProvider.getDisplayString(data.innerMessage) ?? ""
        case .ELEM_TYPE_TEXT:
            if let textElem = data.innerMessage.textElem {
                desc = textElem.text.safeValue
            }
        default:
            break
        }
        return desc
    }

    // MARK: Message quote

    public func onReferenceMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {
        inputController.exitReplyAndReference { [weak self] in
            guard let self, let data = data else { return }
            let desc = self.replyReferenceMessageDesc(data)
            let referenceData = TUIReferencePreviewData()
            referenceData.msgID = data.msgID
            referenceData.msgAbstract = desc
            referenceData.sender = data.senderName
            referenceData.type = data.innerMessage.elemType
            referenceData.originMessage = data.innerMessage
            self.inputController.showReferencePreview(referenceData)
        }
    }

    // MARK: Forward translation

    public func onForwardText(_ controller: TUIBaseMessageController_Minimalist, text: String) {
        guard !text.isEmpty else { return }
        selectTarget(false, toForwardMessage: nil, orForwardText: text)
    }

    public func forwardText(_ text: String, toConversations conversations: [TUIChatConversationModel]) {
        let appendParams = TUISendMessageAppendParams()
        appendParams.isSendPushInfo = true
        appendParams.isOnlineUserOnly = false
        appendParams.priority = .PRIORITY_NORMAL
        for conversation in conversations {
            let message = V2TIMManager.sharedInstance().createTextMessage(text)!
            DispatchQueue.main.async {
                if conversation.conversationID == self.conversationData?.conversationID {
                    self.messageController?.sendMessage(message)
                } else {
                    message.needReadReceipt = self.conversationData?.msgNeedReadReceipt ?? false && TUIChatConfig.shared.msgNeedReadReceipt
                    _ = TUIMessageBaseDataProvider.sendMessage(message, toConversation: conversation, appendParams: appendParams, Progress: nil, SuccBlock: {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TUIKitNotification_onMessageStatusChanged), object: message)
                    }, FailBlock: { _, _ in
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TUIKitNotification_onMessageStatusChanged), object: message)
                    })
                }
            }
        }
    }

    // MARK: - TUIJoinGroupMessageCellDelegate

    func didTapOnRestNameLabel(_ cell: TUIJoinGroupMessageCell_Minimalist, withIndex index: Int) {
        if let userId = cell.joinData?.userIDList?[index] as? String {
            getUserOrFriendProfileVCWithUserID(userId, succBlock: { [weak self] vc in
                guard let self = self else { return }
                self.navigationController?.pushViewController(vc, animated: true)
            }, failBlock: { code, desc in
                TUITool.makeToastError(code, msg: desc)
            })
        }
    }

    // MARK: - V2TIMConversationListener

    public func onConversationChanged(_ conversationList: [V2TIMConversation]) {
        guard let conversationData = conversationData else { return }
        for conv in conversationList {
            if conv.conversationID == conversationData.conversationID {
                if !conversationData.otherSideTyping {
                    conversationData.title = conv.showName
                }
                break
            }
        }
    }

    // MARK: - FriendInfoChangedNotification

    @objc func onFriendInfoChanged(_ notice: Notification) {
        checkTitle(force: true)
    }

    // MARK: TUIChatMediaDataListener

    public func onProvideImage(_ imageUrl: String) {
        let message = V2TIMManager.sharedInstance().createImageMessage(imageUrl)!
        send(message)
    }

    public func onProvideImageError(_ errorMessage: String) {
        TUITool.makeToast(errorMessage)
    }

    public func onProvidePlaceholderVideoSnapshot(_ snapshotUrl: String, snapImage: UIImage, completion: ((Bool, TUIMessageCellData?) -> Void)?) {
        let videoCellData = TUIVideoMessageCellData.placeholderCellData(snapshotUrl: snapshotUrl, thumbImage: snapImage)
        messageController?.sendPlaceHolderUIMessage(videoCellData)
        completion?(true, videoCellData)
    }

    public func onProvideVideo(_ videoUrl: String, snapshot: String, duration: Int, placeHolderCellData: TUIMessageCellData?) {
        if let url = URL(string: videoUrl),
           let message = V2TIMManager.sharedInstance().createVideoMessage(videoUrl, type: url.pathExtension, duration: Int32(duration), snapshotPath: snapshot)
        {
            sendMessage(message, placeHolderCellData: placeHolderCellData)
        }
    }

    public func onProvideVideoError(_ errorMessage: String) {
        TUITool.makeToast(errorMessage)
    }

    public func onProvideFile(_ fileUrl: String, filename: String, fileSize: Int) {
        let message = V2TIMManager.sharedInstance().createFileMessage(fileUrl, fileName: filename)!
        send(message)
    }

    public func onProvideFileError(_ errorMessage: String) {
        TUITool.makeToast(errorMessage)
    }

    func onProvidePlaceholderVideoSnapshot(_ snapshotUrl: String, snapImage: UIImage, completion: ((Bool, TUIMessageCellData) -> Void)?) {}
}
