import ImSDK_Plus
import TIMCommon
import TUICore
import UIKit

class TUIRepliesDetailViewController_Minimalist: TUIChatFlexViewController,
    TUIInputControllerDelegate_Minimalist, UITableViewDelegate, UITableViewDataSource,
    TUIMessageBaseDataProviderDataSource, TUIMessageCellDelegate, TUINotificationProtocol, V2TIMAdvancedMsgListener
{
    weak var delegate: TUIBaseMessageControllerDelegate_Minimalist?
    var mergerElem: V2TIMMergerElem?
    var willCloseCallback: (() -> Void)?
    var inputController: TUIInputController_Minimalist?
    var parentPageDataProvider: TUIMessageDataProvider?
    
    var cellData: TUIMessageCellData?
    var msgDataProvider: TUIMessageDataProvider?
    var headerView: UIView?
    var imMsgs: [V2TIMMessage] = []
    var uiMsgs: [TUIMessageCellData] = []
    var responseKeyboard: Bool = false
    var conversationData: TUIChatConversationModel?
    var originCellLayout: TUIMessageCellLayout?
    var direction: TMsgDirection = .MsgDirectionIncoming
    var showAvatar: Bool = false
    var sameToNextMsgSender: Bool = false
    var isMsgNeedReadReceipt: Bool = false
    
    var cancelButton: UIButton?
    var titleLabel: UILabel?
    
    lazy var tableView: UITableView? = {
        let rect = CGRect(x: 0, y: topGestureView.frame.size.height, width: containerView.frame.size.width,
                          height: containerView.frame.size.height - topGestureView.frame.size.height)
        tableView = UITableView(frame: rect, style: .plain)
        if #available(iOS 15.0, *) {
            tableView!.sectionHeaderTopPadding = 0
        }
        containerView.addSubview(tableView!)
        return tableView
    }()
    
    lazy var messageCellConfig: TUIMessageCellConfig_Minimalist = .init()
    
    // MARK: - Life cycle

    init(cellData: TUIMessageCellData, conversationData: TUIChatConversationModel) {
        self.cellData = cellData
        self.showAvatar = cellData.showAvatar
        self.sameToNextMsgSender = cellData.sameToNextMsgSender
        self.cellData?.showAvatar = true
        self.cellData?.sameToNextMsgSender = false
        self.conversationData = conversationData
        super.init()
        
        setConversation(conversationData)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        resetCellDataState()
        TUICore.unRegisterEvent(byObject: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        // setupInputViewController() // Uncomment if needed
        
        setnormalTop()
        topImgView.isHidden = true
        
        cancelButton = UIButton(type: .custom)
        cancelButton!.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        cancelButton!.setTitleColor(.systemBlue, for: .normal)
        cancelButton!.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        cancelButton!.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
        cancelButton!.sizeToFit()
        topGestureView.addSubview(cancelButton!)
        
        titleLabel = UILabel()
        titleLabel!.text = String(format: "0 %@", TUISwift.timCommonLocalizableString("TUIKitThreadQuote"))
        titleLabel!.font = UIFont.boldSystemFont(ofSize: 16.0)
        titleLabel!.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel!.sizeToFit()
        topGestureView.addSubview(titleLabel!)
        
        updateSubContainerView()
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
        TUICore.registerEvent(TUICore_TUIPluginNotify, subKey: TUICore_TUIPluginNotify_DidChangePluginViewSubKey, object: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateRootMsg()
        applyData()
        updateTableViewConstraint()
        updateSubContainerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        responseKeyboard = true
        isMsgNeedReadReceipt = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        responseKeyboard = false
        revertRootMsg()

        resetCellDataState()
        willCloseCallback?()
    }
    
    func resetCellDataState() {
        cellData?.showAvatar = showAvatar
        cellData?.sameToNextMsgSender = sameToNextMsgSender
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let inputController = inputController else { return }
        if inputController.status == .input || inputController.status == .inputKeyboard {
            let offset = tableView?.contentOffset
            DispatchQueue.main.async {
                self.responseKeyboard = true
                TUITool.applicationKeywindow()?.endEditing(true)
                self.inputController(inputController, didChangeHeight: CGRectGetMaxY(inputController.inputBar?.frame ?? CGRectMake(0, 0, 0, 0)) + TUISwift.bottom_SafeHeight())
                self.tableView?.contentOffset = offset ?? CGPointZero
            }
        }
    }

    // MARK: - Setup views and data

    override func updateSubContainerView() {
        // super.updateSubContainerView() // Uncomment if needed
        topGestureView.frame = CGRect(x: 0,
                                      y: 0,
                                      width: containerView.frame.size.width,
                                      height: TUISwift.kScale390(60))
        cancelButton?.frame = CGRect(x: TUISwift.kScale390(15),
                                     y: (topGestureView.bounds.size.height - TUISwift.kScale390(22)) * 0.5,
                                     width: (cancelButton?.frame.size.width ?? 0),
                                     height: TUISwift.kScale390(22))
        titleLabel?.frame = CGRect(x: (topGestureView.bounds.size.width - (titleLabel?.frame.size.width ?? 0)) * 0.5,
                                   y: cancelButton?.frame.origin.y ?? 0,
                                   width: titleLabel?.frame.size.width ?? 0,
                                   height: TUISwift.kScale390(22))
            
        tableView?.frame = CGRect(x: 0,
                                  y: topGestureView.frame.size.height,
                                  width: containerView.frame.size.width,
                                  height: containerView.frame.size.height - topGestureView.frame.size.height)
        if TUISwift.isRTL() {
            cancelButton?.resetFrameToFitRTL()
        }
    }
    
    func applyData() {
        guard let messageModifyReplies = cellData?.messageModifyReplies as? [[String: Any]] else { return }
        var msgIDArray = [String]()
        for dic in messageModifyReplies {
            if let messageID = dic["messageID"] as? String, !messageID.isEmpty {
                msgIDArray.append(messageID)
            }
        }
        if msgIDArray.isEmpty {
            navigationController?.popViewController(animated: true)
            return
        }
        titleLabel?.text = String(format: "%lu %@", msgIDArray.count, TUISwift.timCommonLocalizableString("TUIKitThreadQuote"))
        titleLabel?.sizeToFit()
        TUIChatDataProvider.findMessages(msgIDArray) { [weak self] _, _, msgs in
            guard let self = self else { return }
            if msgs.count > 0 {
                self.imMsgs = msgs
                self.uiMsgs = self.transUIMsgFromIMMsg(msgs)
                for data in self.uiMsgs {
                    TUIMessageDataProvider.updateUIMsgStatus(data, uiMsgArray: self.uiMsgs)
                }
                DispatchQueue.main.async {
                    if self.uiMsgs.count != 0 {
                        self.tableView?.reloadData()
                        self.tableView?.layoutIfNeeded()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.scrollToBottom(false)
                        }
                    }
                }
            }
        }
    }
    
    func updateTableViewConstraint() {
        let textViewHeight = TUIChatConfig.shared.enableMainPageInputBar ? TTextView_Height : 0
        let height = CGFloat(textViewHeight) + TUISwift.bottom_SafeHeight()
        tableView?.frame.size.height = view.frame.size.height - height
    }
    
    func setupViews() {
        title = TUISwift.timCommonLocalizableString("TUIKitRepliesDetailTitle")
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        tableView?.scrollsToTop = false
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.separatorStyle = .none
        tableView?.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        messageCellConfig.bindTableView(tableView)
    }
    
    func setupInputViewController() {
        inputController = TUIInputController_Minimalist()
        inputController!.delegate = self
        inputController!.view.frame = CGRect(x: 0, y: containerView.frame.size.height - CGFloat(TTextView_Height) - TUISwift.bottom_SafeHeight(),
                                             width: containerView.frame.size.width, height: CGFloat(TTextView_Height) + TUISwift.bottom_SafeHeight())
        inputController!.view.autoresizingMask = .flexibleTopMargin
        addChild(inputController!)
        containerView.addSubview(inputController!.view)
        
        if let group = TIMConfig.default().faceGroups.first {
            inputController!.faceSegementScrollView?.setItems([group], delegate: inputController!)
            
            let data = TUIMenuCellData()
            data.path = group.menuPath
            data.isSelected = true
            inputController!.menuView?.data = [data]
        }
        
        let margin: CGFloat = 20
        let padding: CGFloat = 10
        guard let inputBar = inputController!.inputBar else { return }
        inputBar.inputTextView.frame = CGRect(x: margin, y: inputBar.inputTextView.frame.origin.y, width: inputBar.frame.size.width - inputBar.faceButton.frame.size.width - margin * 2 - padding, height: inputBar.inputTextView.frame.size.height)
        inputBar.faceButton.frame = CGRect(x: inputBar.frame.size.width - inputBar.faceButton.frame.size.width - margin, y: inputBar.faceButton.frame.origin.y, width: inputBar.faceButton.frame.size.width, height: inputBar.faceButton.frame.size.height)
        inputBar.micButton.removeFromSuperview()
        inputBar.moreButton.removeFromSuperview()
        inputBar.cameraButton.removeFromSuperview()
    }
    
    func updateRootMsg() {
        guard let cellData = cellData else { return }
        originCellLayout = cellData.cellLayout
        direction = cellData.direction
        
        var layout = TUIMessageCellLayout.incommingMessage()
        if cellData is TUITextMessageCellData {
            layout = TUIMessageCellLayout.incommingTextMessage()
        } else if cellData is TUIReferenceMessageCellData {
            layout = TUIMessageCellLayout.incommingTextMessage()
        } else if cellData is TUIVoiceMessageCellData {
            layout = TUIMessageCellLayout.incommingVoiceMessage()
        }
        
        cellData.cellLayout = layout
        cellData.direction = .MsgDirectionIncoming
        cellData.showMessageModifyReplies = false
    }
    
    func revertRootMsg() {
        cellData?.cellLayout = originCellLayout ?? TUIMessageCellLayout()
        cellData?.direction = direction
        cellData?.showMessageModifyReplies = true
    }
    
    func transUIMsgFromIMMsg(_ msgs: [V2TIMMessage]) -> [TUIMessageCellData] {
        var uiMsgs = [TUIMessageCellData]()
        
        for msg in msgs {
            let data = TUITextMessageCellData.getCellData(msg)
            var layout = TUIMessageCellLayout.incommingMessage()
            if data is TUITextMessageCellData {
                layout = TUIMessageCellLayout.incommingTextMessage()
            }
            data.direction = .MsgDirectionIncoming
            data.cellLayout = layout
            data.innerMessage = msg
            uiMsgs.append(data)
        }
        
        let sortedArray = uiMsgs.sorted { obj1, obj2 -> Bool in
            if obj1.innerMessage.timestamp.timeIntervalSince1970 == obj2.innerMessage.timestamp.timeIntervalSince1970 {
                return obj1.innerMessage.seq > obj2.innerMessage.seq
            } else {
                return obj1.innerMessage.timestamp < obj2.innerMessage.timestamp
            }
        }
        
        return sortedArray
    }
    
    // MARK: - UITableViewDataSource & Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 20 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0.5 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let line = UIView(frame: CGRectMake(0, 0, TUISwift.screen_Width(), 0.5))
            line.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
            return line
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return uiMsgs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return messageCellConfig.getHeightFromMessageCellData(cellData)
        } else {
            if indexPath.row < uiMsgs.count {
                let cellData = uiMsgs[indexPath.row]
                return messageCellConfig.getHeightFromMessageCellData(cellData)
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellData = cellData else { return UITableViewCell() }
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: cellData.reuseId, for: indexPath) as? TUIMessageCell {
                cell.delegate = self
                cell.fill(with: cellData)
                cell.notifyBottomContainerReady(of: nil)
                return cell
            }
        } else {
            let data = uiMsgs[indexPath.row]
            data.showCheckBox = false
            if let cell = tableView.dequeueReusableCell(withIdentifier: data.reuseId, for: indexPath) as? TUIMessageCell {
                cell.fill(with: data)
                cell.notifyBottomContainerReady(of: nil)
                cell.delegate = self
                return cell
            }
        }
        return UITableViewCell()
    }
    
    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        inputController?.reset()
    }
    
    // MARK: - TUIInputControllerDelegate_Minimalist

    func inputController(_ inputController: TUIInputController_Minimalist, didChangeHeight height: CGFloat) {
        guard responseKeyboard else { return }
        
        if self.inputController?.replyData == nil {
            onRelyMessage(cellData)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            guard let tableView = self.tableView, let inputController = self.inputController else { return }
            var msgFrame = tableView.frame
            msgFrame.size.height = self.view.frame.size.height - height
            tableView.frame = msgFrame
            
            var inputFrame = inputController.view.frame
            inputFrame.origin.y = msgFrame.origin.y + msgFrame.size.height
            inputFrame.size.height = height
            inputController.view.frame = inputFrame
            
            self.scrollToBottom(false)
        }, completion: nil)
    }
    
    func inputController(_ inputController: TUIInputController_Minimalist, didSendMessage msg: V2TIMMessage) {
        sendMessage(msg)
    }
    
    func sendMessage(_ message: V2TIMMessage) {
        guard let cellData = TUIMessageDataProvider.convertToCellData(from: message) else { return }
        cellData.innerMessage.needReadReceipt = isMsgNeedReadReceipt
        sendUIMessage(cellData)
    }
    
    func sendUIMessage(_ cellData: TUIMessageCellData) {
        guard let conversationData = conversationData else { return }
        parentPageDataProvider?.sendUIMsg(cellData, toConversation: conversationData, willSendBlock: { [weak self] _, _ in
            guard let self = self else { return }
            let delay = cellData is TUIImageMessageCellData ? 0 : 1
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay * 1000)) {
                if cellData.status == .Msg_Status_Sending {
                    self.changeMsg(cellData, status: .Msg_Status_Sending_2)
                }
            }
        }, SuccBlock: { [weak self] in
            guard let self = self else { return }
            self.changeMsg(cellData, status: .Msg_Status_Succ)
            self.scrollToBottom(true)
        }, FailBlock: { [weak self] code, desc in
            guard let self = self else { return }
            TUITool.makeToastError(Int(code), msg: desc)
            self.changeMsg(cellData, status: .Msg_Status_Fail)
        })
    }
    
    func scrollToBottom(_ animated: Bool) {
        guard uiMsgs.count > 0 else { return }
        tableView?.scrollToRow(at: IndexPath(row: uiMsgs.count - 1, section: 1), at: .bottom, animated: animated)
    }
    
    @objc func onCancel(_ btn: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func changeMsg(_ msg: TUIMessageCellData, status: TMsgStatus) {
        msg.status = status
        if let index = uiMsgs.firstIndex(of: msg) {
            if (tableView?.numberOfRows(inSection: 0) ?? 0) > index {
                if let cell = tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? TUIMessageCell {
                    cell.fill(with: msg)
                }
            } else {
                print("lack of cell")
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name("kTUINotifyMessageStatusChanged"), object: nil, userInfo: [
            "msg": msg,
            "status": status.rawValue,
            "msgSender": self
        ])
    }
    
    func onRelyMessage(_ data: TUIMessageCellData?) {
        guard let data = data else { return }
        let desc = replyReferenceMessageDesc(data)
        
        let replyData = TUIReplyPreviewData()
        replyData.msgID = data.msgID
        replyData.msgAbstract = desc
        replyData.sender = data.senderName
        replyData.type = data.innerMessage.elemType
        replyData.originMessage = data.innerMessage
        inputController?.replyData = replyData
    }
    
    func replyReferenceMessageDesc(_ data: TUIMessageCellData?) -> String {
        guard let message = data?.innerMessage else { return "" }
        var str: String? = nil
        switch message.elemType {
        case .ELEM_TYPE_FILE:
            if let fileElem = message.fileElem {
                str = fileElem.filename.safeValue
            }
        case .ELEM_TYPE_MERGER:
            if let mergerElem = message.mergerElem {
                str = mergerElem.title.safeValue
            }
        case .ELEM_TYPE_CUSTOM:
            str = TUIMessageDataProvider.getDisplayString(message) ?? ""
        case .ELEM_TYPE_TEXT:
            if let textElem = message.textElem {
                str = textElem.text.safeValue
            }
        default: break
        }
        return str ?? ""
    }
    
    func onSelectMessage(_ cell: TUIMessageCell?) {
        guard let cell = cell else { return }
        if let result = TUIChatConfig.shared.eventConfig.chatEventListener?.onMessageClicked?(cell, messageCellData: cell.messageData), result == true {
            return
        }
        
        switch cell {
        case let imageCell as TUIImageMessageCell_Minimalist:
            showImageMessage(imageCell)
        case let voiceCell as TUIVoiceMessageCell_Minimalist:
            playVoiceMessage(voiceCell)
        case let videoCell as TUIVideoMessageCell_Minimalist:
            showVideoMessage(videoCell)
        case let fileCell as TUIFileMessageCell_Minimalist:
            showFileMessage(fileCell)
        case let mergeCell as TUIMergeMessageCell_Minimalist:
            let mergeVc = TUIMergeMessageListController_Minimalist()
            mergeVc.mergerElem = mergeCell.mergeData?.mergerElem
            mergeVc.delegate = delegate
            let nav = UINavigationController(rootViewController: mergeVc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false, completion: nil)
        case let linkCell as TUILinkCell_Minimalist:
            showLinkMessage(linkCell)
        // Uncomment if needed
        // case let replyCell as TUIReplyMessageCell:
        //     showReplyMessage(replyCell)
        // case let referenceCell as TUIReferenceMessageCell:
        //     showReplyMessage(referenceCell)
        default:
            break
        }
        
        delegate?.onSelectMessageContent?(nil, cell: cell)
    }

    func onLongPressMessage(_ cell: TUIMessageCell!) {}

    func onRetryMessage(_ cell: TUIMessageCell!) {}

    func onSelectMessageAvatar(_ cell: TUIMessageCell!) {}

    func onLongSelectMessageAvatar(_ cell: TUIMessageCell!) {}

    func onSelectReadReceipt(_ cell: TUIMessageCellData!) {}

    func onJump(toRepliesDetailPage data: TUIMessageCellData!) {}

    func onJump(toMessageInfoPage data: TUIMessageCellData!, select cell: TUIMessageCell!) {}
    
    // MARK: - V2TIMAdvancedMsgListener

    func onRecvNewMessage(_ msg: V2TIMMessage?) {
        guard let imMsg = msg else { return }
        if imMsg.msgID == cellData?.msgID {
            if let cellData = TUIMessageDataProvider.convertToCellData(from: imMsg) {
                self.cellData?.messageModifyReplies = cellData.messageModifyReplies
                applyData()
            }
        }
    }
    
    func onRecvMessageModified(_ msg: V2TIMMessage?) {
        guard let imMsg = msg else { return }
        if imMsg.msgID == cellData?.msgID {
            if let cellData = TUIMessageDataProvider.convertToCellData(from: imMsg) {
                self.cellData?.messageModifyReplies = cellData.messageModifyReplies
                applyData()
            }
        }
    }
    
    // MARK: - dataProviderDataChange

    func dataProviderDataSourceWillChange(_ dataProvider: TUIMessageBaseDataProvider) {}
    
    func dataProviderDataSourceChange(_ dataProvider: TUIMessageBaseDataProvider, withType type: TUIMessageBaseDataProviderDataSourceChangeType, atIndex index: UInt, animation: Bool) {}
    
    func dataProviderDataSourceDidChange(_ dataProvider: TUIMessageBaseDataProvider) {}
    
    func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, onRemoveHeightCache cellData: TUIMessageCellData) {
        messageCellConfig.removeHeightCacheOfMessageCellData(cellData)
    }
    
    // MARK: - Action

    func showImageMessage(_ cell: TUIImageMessageCell_Minimalist) {
        guard let cellData = cellData else { return }
        let frame = cell.thumb.convert(cell.thumb.bounds, to: UIApplication.shared.delegate?.window ?? UIWindow())
        let mediaView = TUIMediaView_Minimalist(frame: CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: TUISwift.screen_Height()))
        mediaView.setThumb(cell.thumb, frame: frame)
        mediaView.setCurMessage(cell.messageData.innerMessage, allMessages: [cellData.innerMessage])
        TUITool.applicationKeywindow()?.addSubview(mediaView)
    }
    
    func playVoiceMessage(_ cell: TUIVoiceMessageCell_Minimalist) {
        guard let uiMsg = cell.voiceData else {
            return
        }
        if uiMsg == cellData {
            uiMsg.playVoiceMessage()
            cell.voiceReadPoint.isHidden = true
        } else {
            uiMsg.stopVoiceMessage()
        }
    }
    
    func showVideoMessage(_ cell: TUIVideoMessageCell_Minimalist) {
        guard let cellData = cellData else { return }
        let frame = cell.thumb.convert(cell.thumb.bounds, to: UIApplication.shared.delegate?.window ?? UIWindow())
        let mediaView = TUIMediaView_Minimalist(frame: CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: TUISwift.screen_Height()))
        mediaView.setThumb(cell.thumb, frame: frame)
        mediaView.setCurMessage(cell.messageData.innerMessage, allMessages: [cellData.innerMessage])
        mediaView.onClose = {
            self.tableView?.reloadData()
        }
        TUITool.applicationKeywindow()?.addSubview(mediaView)
    }
    
    func showFileMessage(_ cell: TUIFileMessageCell_Minimalist) {
        guard let fileData = cell.fileData else { return }
        if !fileData.isLocalExist() {
            fileData.downloadFile()
            return
        }
        
        let fileVC = TUIFileViewController_Minimalist()
        fileVC.data = cell.fileData
        fileVC.dismissClickCallback = {
            self.dismiss(animated: true, completion: nil)
        }
        
        let nav = UINavigationController(rootViewController: fileVC)
        present(nav, animated: false, completion: nil)
    }
    
    func showLinkMessage(_ cell: TUILinkCell_Minimalist?) {
        if let cellData = cell?.customData {
            UIApplication.shared.open(URL(string: cellData.link)!, options: [:], completionHandler: nil)
        }
    }
    
    func setConversation(_ conversationData: TUIChatConversationModel) {
        if msgDataProvider == nil {
            msgDataProvider = TUIMessageDataProvider(conversationModel: conversationData)
            msgDataProvider?.dataSource = self
        }
        loadMessage()
    }
    
    func loadMessage() {
        if msgDataProvider?.isLoadingData == true || msgDataProvider?.isNoMoreMsg == true {
            return
        }
        
        msgDataProvider?.loadMessageSucceedBlock({ _, _, _ in }, FailBlock: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }
    
    // MARK: - TUINotificationProtocol

    func onNotifyEvent(_ key: String, subKey: String, object anObject: Any?, param: [AnyHashable: Any]?) {
        if key == TUICore_TUIPluginNotify && subKey == TUICore_TUIPluginNotify_DidChangePluginViewSubKey {
            if let data = param?[TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data] as? TUIMessageCellData {
                let section = data.msgID == cellData?.msgID ? 0 : 1
                messageCellConfig.removeHeightCacheOfMessageCellData(data)
                if let msgID = data.innerMessage.msgID {
                    reloadAndScrollToBottomOfMessage(msgID, section: section)
                }
            }
        }
    }
    
    func reloadAndScrollToBottomOfMessage(_ messageID: String, section: Int) {
        DispatchQueue.main.async {
            self.reloadCellOfMessage(messageID, section: section)
            DispatchQueue.main.async {
                self.scrollCellToBottomOfMessage(messageID, section: section)
            }
        }
    }
    
    func reloadCellOfMessage(_ messageID: String, section: Int) {
        guard let indexPath = indexPathOfMessage(messageID, section: section) as? IndexPath else { return }
        UIView.performWithoutAnimation {
            DispatchQueue.main.async {
                self.tableView?.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    func scrollCellToBottomOfMessage(_ messageID: String, section: Int) {
        guard let tableView = tableView else { return }
        guard let indexPath = indexPathOfMessage(messageID, section: section) else { return }
        
        let cellRect = tableView.rectForRow(at: indexPath as IndexPath)
        let tableViewRect = tableView.bounds
        let isBottomInvisible = cellRect.origin.y < tableViewRect.maxY && cellRect.maxY > tableViewRect.maxY
        
        if isBottomInvisible {
            tableView.scrollToRow(at: indexPath as IndexPath, at: .bottom, animated: true)
        }
    }
    
    func indexPathOfMessage(_ messageID: String, section: Int) -> NSIndexPath? {
        if section == 0 {
            return NSIndexPath(row: 0, section: section)
        } else {
            return uiMsgs.firstIndex(where: { $0.innerMessage.msgID == messageID }).map { NSIndexPath(row: $0, section: section) }
        }
    }
}
    
