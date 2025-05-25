import TIMCommon
import UIKit

let kConversationCell_Minimalist_ReuseId: String = "kConversationCell_Minimalist_ReuseId"

public class TUIConversationListController_Minimalist: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, TUINotificationProtocol, TUIPopViewDelegate, UIGestureRecognizerDelegate, TUIConversationListDataProviderDelegate {
    var tableView: UITableView!
    public var multiChooseView: TUIConversationMultiChooseView_Minimalist!
    
    public weak var delegate: TUIConversationListControllerListener?
    var moreItem: UIBarButtonItem?
    var editItem: UIBarButtonItem?
    var doneItem: UIBarButtonItem?
    var isShowBanner: Bool = true
    var showCheckBox: Bool = false
    var dataSourceChanged: ((Int) -> Void)?
    
    lazy var dataProvider: TUIConversationListBaseDataProvider = {
        var provider = TUIConversationListDataProvider_Minimalist()
        provider.delegate = self
        return provider
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.isShowBanner = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isShowBanner = true
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupViews()
        dataProvider.loadNexPageConversations()
        showCheckBox = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(onFriendInfoChanged(_:)), name: NSNotification.Name(rawValue: "FriendInfoChangedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(startCreatGroupNotification(_:)), name: NSNotification.Name(rawValue: "kTUIConversationCreatGroupNotification"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        TUICore.unRegisterEvent(byObject: self)
    }
    
    func navBackColor() -> UIColor {
        return UIColor.white
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = nil
            appearance.backgroundEffect = nil
            appearance.backgroundColor = navBackColor()
            navigationController?.navigationBar.backgroundColor = navBackColor()
            navigationController?.navigationBar.barTintColor = navBackColor()
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.backgroundColor = navBackColor()
            navigationController?.navigationBar.barTintColor = navBackColor()
            navigationController?.navigationBar.shadowImage = UIImage()
        }
    }
    
    @objc func onFriendInfoChanged(_ notice: Notification) {
        guard let friendInfo = notice.object as? V2TIMFriendInfo else { return }
        for cellData in dataProvider.conversationList {
            if cellData.userID == friendInfo.userID {
                if let userFullInfo = friendInfo.userFullInfo {
                    cellData.title = friendInfo.friendRemark ?? userFullInfo.nickName ?? friendInfo.userID
                    tableView.reloadData()
                    break
                }
            }
        }
    }
    
    func setupNavigation() {
        let editButton = UIButton(type: .custom)
        editButton.setImage(UIImage.safeImage(TUISwift.tuiConversationImagePath_Minimalist("nav_edit")), for: .normal)
        editButton.addTarget(self, action: #selector(editBarButtonClick(_:)), for: .touchUpInside)
        editButton.imageView!.contentMode = .scaleAspectFit
        editButton.frame = CGRect(x: 0, y: 0, width: 18 + 21 * 2, height: 18)
        
        let moreButton = UIButton(type: .custom)
        moreButton.setImage(UIImage.safeImage(TUISwift.tuiConversationImagePath_Minimalist("nav_add")), for: .normal)
        moreButton.addTarget(self, action: #selector(rightBarButtonClick(_:)), for: .touchUpInside)
        moreButton.imageView!.contentMode = .scaleAspectFit
        moreButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        let doneButton = UIButton(type: .custom)
        doneButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitDone"), for: .normal)
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.addTarget(self, action: #selector(doneBarButtonClick(_:)), for: .touchUpInside)
        doneButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        editItem = UIBarButtonItem(customView: editButton)
        moreItem = UIBarButtonItem(customView: moreButton)
        doneItem = UIBarButtonItem(customView: doneButton)
        
        navigationItem.rightBarButtonItems = [moreItem!, editItem!]
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    func setupViews() {
        view.backgroundColor = TUIConversationConfig.shared.listBackgroundColor ?? TUISwift.tuiConversationDynamicColor("conversation_bg_color", defaultColor: "#FFFFFF")
        let rect = view.bounds
        tableView = UITableView(frame: rect)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = view.backgroundColor
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.register(TUIConversationCell_Minimalist.self, forCellReuseIdentifier: kConversationCell_Minimalist_ReuseId)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = TUISwift.kScale390(64.0)
        tableView.rowHeight = TUISwift.kScale390(64.0)
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        view.addSubview(tableView)
        
        if isShowBanner {
            let size = CGSize(width: view.bounds.size.width, height: 60)
            let bannerView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            tableView.tableHeaderView = bannerView
            let param: [String: Any] = [
                "TUICore_TUIConversationExtension_ConversationListBanner_BannerSize": NSCoder.string(for: size),
                "TUICore_TUIConversationExtension_ConversationListBanner_ModalVC": self
            ]
            let isResponserExist = TUICore.raiseExtension("TUICore_TUIConversationExtension_ConversationListBanner_MinimalistExtensionID", parentView: bannerView, param: param)
            if !isResponserExist {
                tableView.tableHeaderView = nil
            }
        }
    }
    
    @objc func doneBarButtonClick(_ doneBarButton: UIBarButtonItem) {
        openMultiChooseBoard(false)
        if let moreItem = moreItem, let editItem = editItem {
            navigationItem.rightBarButtonItems = [moreItem, editItem]
        }
    }
    
    @objc func editBarButtonClick(_ editBarButton: UIButton) {
        openMultiChooseBoard(true)
        enableMultiSelectedMode(true)
        if let doneItem = doneItem {
            navigationItem.rightBarButtonItems = [doneItem]
        }
    }
    
    @objc func rightBarButtonClick(_ rightBarButton: UIButton) {
        let menus = [TUIPopCellData(), TUIPopCellData()]
        menus[0].image = TUISwift.tuiConversationDynamicImage("pop_icon_new_chat_img", defaultImage: UIImage.safeImage(TUISwift.tuiConversationImagePath("new_chat")))
        menus[0].title = TUISwift.timCommonLocalizableString("ChatsNewChatText")
        menus[1].image = TUISwift.tuiConversationDynamicImage("pop_icon_new_group_img", defaultImage: UIImage.safeImage(TUISwift.tuiConversationImagePath("new_groupchat")))
        menus[1].title = TUISwift.timCommonLocalizableString("ChatsNewGroupText")
        
        let height = TUIPopCell.getHeight() * CGFloat(menus.count) + TUISwift.tuiPopView_Arrow_Size().height
        let orginY = TUISwift.statusBar_Height() + TUISwift.navBar_Height()
        var orginX = TUISwift.screen_Width() - 155
        if TUISwift.isRTL() {
            orginX = 10
        }
        let popView = TUIPopView(frame: CGRect(x: orginX, y: orginY, width: 145, height: height))
        let frameInNaviView = navigationController?.view.convert(rightBarButton.frame, from: rightBarButton.superview)
        popView.arrowPoint = CGPoint(x: (frameInNaviView?.origin.x ?? 0) + (frameInNaviView?.size.width ?? 0) * 0.5, y: orginY)
        popView.delegate = self
        popView.setData(menus)
        popView.showInWindow(view.window!)
    }
    
    public func popView(_ popView: TUIPopView, didSelectRowAt index: Int) {
        if index == 0 {
            startConversation(.C2C)
        } else {
            startConversation(.GROUP)
        }
    }
    
    public func startConversation(_ type: V2TIMConversationType) {
        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { [weak self] array in
            guard let self = self else { return }
            if type == .C2C {
                let param: [String: Any] = [
                    "TUICore_TUIChatObjectFactory_ChatViewController_Title": array.first?.title ?? "",
                    "TUICore_TUIChatObjectFactory_ChatViewController_UserID": array.first?.identifier ?? "",
                    "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": array.first?.avatarImage ?? TUISwift.defaultAvatarImage() as Any,
                    "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": array.first?.avatarUrl?.absoluteString ?? ""
                ]
                navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
            } else {
                guard let loginUser = V2TIMManager.sharedInstance().getLoginUser() else { return }
                V2TIMManager.sharedInstance().getUsersInfo([loginUser]) { [weak self] infoList in
                    guard let self = self, let infoList = infoList else { return }
                    var showName = loginUser
                    if let nickName = infoList.first?.nickName {
                        showName = nickName
                    }
                    var groupName = NSMutableString(string: showName)
                    for item in array {
                        groupName.appendFormat("、%@", item.title)
                    }
                    
                    if groupName.length > 10 {
                        groupName = NSMutableString(string: String(groupName.substring(to: 10)))
                    }
                    let createGroupCompletion: (Bool, V2TIMGroupInfo?, UIImage?) -> Void = { [weak self] _, info, submitShowImage in
                        guard let self = self else { return }
                        let param: [String: Any] = [
                            "TUICore_TUIChatObjectFactory_ChatViewController_Title": info?.groupName ?? "",
                            "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": info?.groupID ?? "",
                            "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": info?.faceURL ?? "",
                            "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": submitShowImage ?? UIImage()
                        ]
                        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
                        
                        var tempArray = navigationController?.viewControllers ?? []
                        for vc in navigationController?.viewControllers ?? [] {
                            if let cls1 = NSClassFromString("TUIContact.TUIGroupCreateController"),
                               vc.isKind(of: cls1)
                            {
                                tempArray.removeAll(where: { $0 === vc })
                            } else if let cls2 = NSClassFromString("TUIContact.TUIContactSelectController"),
                                      vc.isKind(of: cls2)
                            {
                                tempArray.removeAll(where: { $0 === vc })
                            }
                        }
                        
                        navigationController?.viewControllers = tempArray
                    }
                    let param: [String: Any] = [
                        "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_TitleKey": array.first?.title ?? "",
                        "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupNameKey": groupName as String,
                        "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupTypeKey": GroupType_Work,
                        "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_CompletionKey": createGroupCompletion,
                        "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_ContactListKey": array
                    ]
                    
                    let afloatVC = TUIFloatViewController()
                    if let groupVC = TUICore.createObject("TUICore_TUIContactObjectFactory_Minimalist",
                                                          key: "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod",
                                                          param: param) as? UIViewController as? (UIViewController & TUIFloatSubViewControllerProtocol)
                    {
                        afloatVC.appendChildViewController(groupVC, topMargin: TUISwift.kScale390(87.5))
                        afloatVC.topGestureView.setTitleText(mainText: TUISwift.timCommonLocalizableString("ChatsNewGroupText"),
                                                             subTitleText: "",
                                                             leftBtnText: TUISwift.timCommonLocalizableString("TUIKitCreateCancel"),
                                                             rightBtnText: TUISwift.timCommonLocalizableString("TUIKitCreateFinish"))
                    }
                    present(afloatVC, animated: true, completion: nil)
                } fail: { _, _ in
                }
            }
        }
        let floatVC = TUIFloatViewController()
        let param: [String: Any] = [
            "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey": TUISwift.timCommonLocalizableString("ChatsSelectContact"),
            "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_MaxSelectCount": type == .C2C ? 1 : INT_MAX,
            "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey": selectContactCompletion
        ]
        if let contactVC = TUICore.createObject("TUICore_TUIContactObjectFactory_Minimalist", key: "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod", param: param) as? (UIViewController & TUIFloatSubViewControllerProtocol) {
            floatVC.appendChildViewController(contactVC, topMargin: TUISwift.kScale390(87.5))
            floatVC.topGestureView.setTitleText(mainText: (type == .C2C) ? TUISwift.timCommonLocalizableString("ChatsNewChatText") : TUISwift.timCommonLocalizableString("ChatsNewGroupText"),
                                                subTitleText: "",
                                                leftBtnText: TUISwift.timCommonLocalizableString("TUIKitCreateCancel"),
                                                rightBtnText: (type == .C2C) ? "" : TUISwift.timCommonLocalizableString("TUIKitCreateNext"))
        }
        floatVC.topGestureView.rightButton.isEnabled = false
        
        floatVC.childVC?.floatDataSourceChanged = { [weak floatVC] arr in
            guard let floatVC else { return }
            floatVC.topGestureView.rightButton.isEnabled = (arr.count != 0)
        }
        
        present(floatVC, animated: true, completion: nil)
    }
    
    public func openMultiChooseBoard(_ open: Bool) {
        view.endEditing(true)
        showCheckBox = open
        
        if let multiChooseView = multiChooseView {
            multiChooseView.removeFromSuperview()
        }
        
        if open {
            multiChooseView = TUIConversationMultiChooseView_Minimalist()
            multiChooseView.frame = UIScreen.main.bounds
            multiChooseView.titleLabel.text = ""
            multiChooseView.toolView.isHidden = true
            
            multiChooseView.readButton.setTitle(TUISwift.timCommonLocalizableString("ReadAll"), for: .normal)
            multiChooseView.hideButton.setTitle(TUISwift.timCommonLocalizableString("Hide"), for: .normal)
            multiChooseView.deleteButton.setTitle(TUISwift.timCommonLocalizableString("Delete"), for: .normal)
            multiChooseView.readButton.isEnabled = true
            multiChooseView.hideButton.isEnabled = false
            multiChooseView.deleteButton.isEnabled = false
            multiChooseView.readButton.clickCallBack = { [weak self] _ in
                guard let self = self else { return }
                self.chooseViewReadAll()
            }
            multiChooseView.hideButton.clickCallBack = { [weak self] _ in
                guard let self = self else { return }
                self.choosViewActionHide()
            }
            multiChooseView.deleteButton.clickCallBack = { [weak self] _ in
                guard let self = self else { return }
                self.chooseViewActionDelete()
            }
            
            if #available(iOS 12.0, *) {
                if #available(iOS 13.0, *) {
                    // > ios 12
                    TUITool.applicationKeywindow()?.addSubview(multiChooseView)
                } else {
                    // ios = 12
                    if let view = navigationController?.view ?? view {
                        view.addSubview(multiChooseView)
                    }
                }
            } else {
                // < ios 12
                TUITool.applicationKeywindow()?.addSubview(multiChooseView)
            }
        } else {
            delegate?.onCloseConversationMultiChooseBoard()
            enableMultiSelectedMode(false)
            if let moreItem = moreItem, let editItem = editItem {
                navigationItem.rightBarButtonItems = [moreItem, editItem]
            }
        }
    }
    
    func chooseViewReadAll() {
        delegate?.onClearAllConversationUnreadCount()
        openMultiChooseBoard(false)
    }
    
    func choosViewActionHide() {
        let uiMsgs = getMultiSelectedResult()
        if uiMsgs.isEmpty {
            return
        }
        for data in uiMsgs {
            dataProvider.markConversationHide(data)
        }
        openMultiChooseBoard(false)
    }
    
    func chooseViewActionRead() {
        let uiMsgs = getMultiSelectedResult()
        if uiMsgs.isEmpty {
            return
        }
        for data in uiMsgs {
            dataProvider.markConversationAsRead(data)
        }
        openMultiChooseBoard(false)
    }
    
    func chooseViewActionDelete() {
        let uiMsgs = getMultiSelectedResult()
        if uiMsgs.isEmpty {
            return
        }
        for data in uiMsgs {
            dataProvider.removeConversation(data)
        }
        openMultiChooseBoard(false)
    }
    
    // #pragma mark TUIConversationListDataProviderDelegate
    public func getConversationDisplayString(_ conversation: V2TIMConversation) -> String? {
        if let displayString = delegate?.getConversationDisplayString(conversation) { return displayString }
        
        guard let msg = conversation.lastMessage, let customElem = msg.customElem, let data = customElem.data else {
            return nil
        }
        
        guard let param = TUITool.jsonData2Dictionary(data) as? [String: Any], let businessID = param["businessID"] as? String else {
            return nil
        }
        
        // Check if it's a custom jump message
        if businessID == "text_link" ||
            (param["text"] as? String)?.isEmpty == false &&
            (param["link"] as? String)?.isEmpty == false
        {
            var desc = param["text"] as? String
            
            if msg.status == V2TIMMessageStatus.MSG_STATUS_LOCAL_REVOKED {
                if let _ = msg.revokerInfo, let _ = msg.revokeReason, msg.hasRiskContent {
                    desc = TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallRiskContent")
                } else if let info = msg.revokerInfo, let userName = info.nickName {
                    desc = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
                } else if msg.isSelf {
                    desc = TUISwift.timCommonLocalizableString("TUIKitMessageTipsYouRecallMessage")
                } else if let userID = msg.userID, !userID.isEmpty {
                    desc = TUISwift.timCommonLocalizableString("TUIKitMessageTipsOthersRecallMessage")
                } else if let groupID = msg.groupID, !groupID.isEmpty {
                    // For the name display of group messages, the group business card is displayed first, the nickname has the second priority, and the user ID has the lowest priority.
                    if let userName = msg.nameCard ?? msg.nickName ?? msg.sender {
                        desc = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
                    }
                }
            }
            
            return desc
        }
        
        return nil
    }
    
    public func insertConversations(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.insertConversations(at: indexPaths)
            }
            return
        }
        UIView.performWithoutAnimation {
            tableView.insertRows(at: indexPaths, with: .none)
        }
    }
    
    public func reloadConversations(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadConversations(at: indexPaths)
            }
            return
        }
        if tableView.isEditing {
            tableView.isEditing = false
        }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: indexPaths, with: .none)
        }
    }
    
    public func deleteConversation(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.deleteConversation(at: indexPaths)
            }
            return
        }
        tableView.deleteRows(at: indexPaths, with: .none)
    }
    
    public func reloadAllConversations() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadAllConversations()
            }
            return
        }
        tableView.reloadData()
    }
    
    // MARK: - UITableView Delegate & Datasource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let dataSourceChanged = dataSourceChanged {
            dataSourceChanged(dataProvider.conversationList.count)
        }
        return dataProvider.conversationList.count
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.row < dataProvider.conversationList.count else { return nil }
        var rowActions: [UITableViewRowAction] = []
        let cellData = dataProvider.conversationList[indexPath.row]
        
        // Mark as read action
        let markAsReadAction = UITableViewRowAction(style: .default, title: (cellData.isMarkAsUnread || cellData.unreadCount > 0) ? TUISwift.timCommonLocalizableString("MarkAsRead") : TUISwift.timCommonLocalizableString("MarkAsUnRead")) { [weak self] _, _ in
            guard let self = self else { return }
            if cellData.isMarkAsUnread || cellData.unreadCount > 0 {
                self.dataProvider.markConversationAsRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_FoldItemIsUnread(false)
                }
            } else {
                self.dataProvider.markConversationAsUnRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_FoldItemIsUnread(true)
                }
            }
        }
        markAsReadAction.backgroundColor = TUISwift.rgb(20, g: 122, b: 255)
        
        // Mark as hide action
        let markHideAction = UITableViewRowAction(style: .default, title: TUISwift.timCommonLocalizableString("MarkHide")) { [weak self] _, _ in
            guard let self = self else { return }
            self.dataProvider.markConversationHide(cellData)
            if cellData.isLocalConversationFoldList {
                TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_HideFoldItem(true)
            }
        }
        markHideAction.backgroundColor = TUISwift.rgb(242, g: 147, b: 64)
        
        // More action
        let moreAction = UITableViewRowAction(style: .default, title: "more") { [weak self] _, _ in
            guard let self = self else { return }
            self.tableView.isEditing = false
            self.showMoreAction(cellData)
        }
        moreAction.backgroundColor = .black
        
        // config Actions
        if cellData.isLocalConversationFoldList {
            rowActions.append(markHideAction)
        } else {
            rowActions.append(markAsReadAction)
            rowActions.append(moreAction)
        }
        return rowActions
    }
    
    @available(iOS 11.0, *)
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if showCheckBox {
            return nil
        }
        guard indexPath.row < dataProvider.conversationList.count else { return nil }
        let cellData = dataProvider.conversationList[indexPath.row]
        var arrayM = [UIContextualAction]()
        let language = TUIGlobalization.tk_localizableLanguageKey() ?? ""

        // Mark as read action
        let markAsReadAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            completionHandler(true)
            if cellData.isMarkAsUnread || cellData.unreadCount > 0 {
                self.dataProvider.markConversationAsRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_FoldItemIsUnread(false)
                }
            } else {
                self.dataProvider.markConversationAsUnRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_FoldItemIsUnread(true)
                }
            }
        }
        
        let read = cellData.isMarkAsUnread || cellData.unreadCount > 0
        markAsReadAction.backgroundColor = read ? TUISwift.rgb(37, g: 104, b: 240) : TUISwift.rgb(102, g: 102, b: 102)
        var markAsReadImageName = read ? "icon_conversation_swipe_read" : "icon_conversation_swipe_unread"
        
        if language.contains("zh-") {
            markAsReadImageName.append("_zh")
        } else if language.contains("ar") {
            markAsReadImageName.append("_ar")
        }
        markAsReadAction.image = TUISwift.tuiDynamicImage("", themeModule: TUIThemeModule.conversation_Minimalist, defaultImage: UIImage.safeImage(TUISwift.tuiConversationImagePath_Minimalist(markAsReadImageName)))
        
        // Mark as hide action
        let markHideAction = UIContextualAction(style: .normal, title: TUISwift.timCommonLocalizableString("MarkHide")) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            completionHandler(true)
            self.dataProvider.markConversationHide(cellData)
            if cellData.isLocalConversationFoldList {
                TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_HideFoldItem(true)
            }
        }
        markHideAction.backgroundColor = UIColor.tui_color(withHex: "#0365F9")

        // More action
        let moreAction = UIContextualAction(style: .normal, title: "") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            completionHandler(true)
            self.tableView.isEditing = false
            self.showMoreAction(cellData)
        }
        moreAction.backgroundColor = TUISwift.rgb(0, g: 0, b: 0)
        var moreImageName = "icon_conversation_swipe_more"
        if language.contains("zh-") {
            moreImageName.append("_zh")
        } else if language.contains("ar") {
            moreImageName.append("_ar")
        }
        moreAction.image = TUISwift.tuiDynamicImage("", themeModule: TUIThemeModule.conversation_Minimalist, defaultImage: UIImage.safeImage(TUISwift.tuiConversationImagePath_Minimalist(moreImageName)))

        // config Actions
        if cellData.isLocalConversationFoldList {
            arrayM.append(markHideAction)
        } else {
            arrayM.append(markAsReadAction)
            arrayM.append(moreAction)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: arrayM)
        configuration.performsFirstActionWithFullSwipe = false

        // fix bug:
        // In iOS 12, image in SwipeActions will be rendered with template
        // The method is adding a new image to the origin
        // The purpose of using async is to ensure UISwipeActionPullView has been rendered in UITableView
        DispatchQueue.main.async {
            if #available(iOS 12.0, *) {
                self.reRenderingSwipeView()
            }
        }
        
        return configuration
    }
    
    static var kSwipeImageViewTag: UInt = 0
    @available(iOS 12.0, *)
    func reRenderingSwipeView() {
        if #available(iOS 13.0, *) {
            return
        }
        
        if TUIConversationListController_Minimalist.kSwipeImageViewTag == 0 {
            TUIConversationListController_Minimalist.kSwipeImageViewTag = UInt(NSStringFromClass(classForCoder).hashValue)
        }

        for view in tableView.subviews {
            if let pullView = NSClassFromString("UISwipeActionPullView") {
                if !view.isKind(of: pullView) {
                    continue
                }
            }
            for subview in view.subviews {
                if let standardButton = NSClassFromString("UISwipeActionStandardButton") {
                    if !subview.isKind(of: standardButton) {
                        continue
                    }
                }
                for sub in subview.subviews {
                    if !(sub is UIImageView) {
                        continue
                    }
                    if sub.viewWithTag(Int(TUIConversationListController_Minimalist.kSwipeImageViewTag)) == nil {
                        let addedImageView = UIImageView(frame: sub.bounds)
                        addedImageView.tag = Int(TUIConversationListController_Minimalist.kSwipeImageViewTag)
                        if let imageView = sub as? UIImageView {
                            addedImageView.image = imageView.image?.withRenderingMode(.alwaysOriginal)
                        }
                        sub.addSubview(addedImageView)
                    }
                }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataProvider.conversationList.count else { return UITableViewCell() }
        if let cell = tableView.dequeueReusableCell(withIdentifier: kConversationCell_Minimalist_ReuseId, for: indexPath) as? TUIConversationCell_Minimalist {
            let data = dataProvider.conversationList[indexPath.row]
            data.showCheckBox = showCheckBox
            if data.isLocalConversationFoldList {
                data.showCheckBox = false
            }
            cell.fill(with: data)
            return cell
        }
        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < dataProvider.conversationList.count else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? TUIConversationCell_Minimalist else { return }
        let data = dataProvider.conversationList[indexPath.row]
        data.avatarImage = cell.headImageView.image
        tableView.reloadData()

        if showCheckBox {
            if data.isLocalConversationFoldList {
                return
            }
            data.selected.toggle()

            let uiMsgs = getMultiSelectedResult()
            if uiMsgs.isEmpty {
                multiChooseView.readButton.isEnabled = false
                multiChooseView.deleteButton.isEnabled = false
                multiChooseView.hideButton.isEnabled = false
                return
            }

            multiChooseView.readButton.isEnabled = false
            multiChooseView.hideButton.isEnabled = true
            multiChooseView.deleteButton.isEnabled = true
            multiChooseView.readButton.setTitle(TUISwift.timCommonLocalizableString("MarkAsRead"), for: .normal)
            multiChooseView.readButton.clickCallBack = { [weak self] _ in
                self?.chooseViewActionRead()
            }

            for data in uiMsgs {
                if data.unreadCount > 0 {
                    multiChooseView.readButton.isEnabled = true
                    break
                }
            }
            return
        }

        if data.isLocalConversationFoldList {
            TUIConversationListBaseDataProvider.cacheConversationFoldListSettings_FoldItemIsUnread(false)

            let foldVC = TUIFoldListViewController_Minimalist()
            navigationController?.pushViewController(foldVC, animated: true)

            foldVC.dismissCallback = { [weak self] foldStr, sortArr, needRemoveFromCacheMapArray in
                guard let self = self else { return }
                data.foldSubTitle = foldStr
                data.subTitle = data.foldSubTitle
                data.isMarkAsUnread = false

                if sortArr.isEmpty {
                    data.orderKey = 0
                    if self.dataProvider.conversationList.contains(data) == true {
                        self.dataProvider.hideConversation(data)
                    }
                }

                for removeId in needRemoveFromCacheMapArray {
                    self.dataProvider.markFoldMap.removeValue(forKey: removeId as? String ?? "")
                }

                TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_FoldItemIsUnread(false)
                self.tableView.reloadData()
            }
            return
        }

        if let delegate = delegate, delegate.conversationListController(self, didSelectConversation: data) {
        } else {
            let param: [String: Any] = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": data.title ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_UserID": data.userID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": data.groupID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": data.avatarImage ?? UIImage(),
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": data.faceUrl ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_ConversationID": data.conversationID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AtTipsStr": data.atTipsStr ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AtMsgSeqs": data.atMsgSeqs ?? [],
                "TUICore_TUIChatObjectFactory_ChatViewController_Draft": data.draftText ?? ""
            ]
            navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let needLastLineFromZeroToMax = false
        if cell.responds(to: Selector(("setSeparatorInset:"))) {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 75, bottom: 0, right: 0)
            if needLastLineFromZeroToMax && indexPath.row == dataProvider.conversationList.count - 1 {
                cell.separatorInset = .zero
            }
        }

        if needLastLineFromZeroToMax && cell.responds(to: Selector(("setPreservesSuperviewLayoutMargins:"))) {
            cell.preservesSuperviewLayoutMargins = false
        }

        if needLastLineFromZeroToMax && cell.responds(to: Selector(("setLayoutMargins:"))) {
            cell.layoutMargins = .zero
        }
    }

    public func adaptivePresentationStyle(for presentationController: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dataProvider.loadNexPageConversations()
    }

    public func enableMultiSelectedMode(_ enable: Bool) {
        showCheckBox = enable
        if !enable {
            for cellData in dataProvider.conversationList {
                cellData.selected = false
            }
        }
        tableView.reloadData()
    }

    func getMultiSelectedResult() -> [TUIConversationCellData_Minimalist] {
        var arrayM = [TUIConversationCellData_Minimalist]()
        if !showCheckBox {
            return arrayM
        }
        for data in dataProvider.conversationList {
            if data.selected {
                if let cellData = data as? TUIConversationCellData_Minimalist {
                    arrayM.append(cellData)
                }
            }
        }
        
        return arrayM
    }
    
    func showMoreAction(_ cellData: TUIConversationCellData) {
        var hideHide = false
        var hidePin = false
        var hideClear = false
        var hideDelete = false
        var customizedItems: [UIAlertAction] = []
        
        if let dataSource = TUIConversationConfig.shared.moreMenuDataSource {
            let flag = dataSource.conversationShouldHideItemsInMoreMenu(cellData)
            hideHide = ((flag.rawValue & TUIConversationItemInMoreMenu.Hide.rawValue) != 0)
            hidePin = ((flag.rawValue & TUIConversationItemInMoreMenu.Pin.rawValue) != 0)
            hideClear = ((flag.rawValue & TUIConversationItemInMoreMenu.Clear.rawValue) != 0)
            hideDelete = ((flag.rawValue & TUIConversationItemInMoreMenu.Delete.rawValue) != 0)
            
            customizedItems = dataSource.conversationShouldAddNewItemsToMoreMenu(cellData) as? [UIAlertAction] ?? []
        }
        
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if !hideHide {
            ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("MarkHide"), style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider_Minimalist.cacheConversationFoldListSettings_HideFoldItem(true)
                }
            }))
        }
        
        if !cellData.isMarkAsFolded {
            if !hidePin {
                ac.tuitheme_addAction(UIAlertAction(title: cellData.isOnTop ? TUISwift.timCommonLocalizableString("UnPin") : TUISwift.timCommonLocalizableString("Pin"), style: .default, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.dataProvider.pinConversation(cellData, pin: !cellData.isOnTop)
                }))
            }
        }
        
        if !hideClear {
            ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("ClearHistoryChatMessage"), style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.dataProvider.markConversationAsRead(cellData)
                self.dataProvider.clearHistoryMessage(cellData)
            }))
        }
        
        if !hideDelete {
            ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Delete"), style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                self.dataProvider.removeConversation(cellData)
            }))
        }
        
        for action in customizedItems {
            ac.tuitheme_addAction(action)
        }
        
        ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }

    @objc func startCreatGroupNotification(_ noti: Notification) {
        startConversation(.GROUP)
    }
}

class IUConversationView_Minimalist: UIView {
    var view: UIView

    override init(frame: CGRect) {
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        super.init(frame: frame)
        addSubview(view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
