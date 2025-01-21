import AVFoundation
import Foundation
import TIMCommon
import TUICore

let MaxDateMessageDelay: TimeInterval = 5 * 60

@objc enum TUIMessageBaseDataProviderDataSourceChangeType: UInt {
    case insert
    case delete
    case reload
}

@objc protocol TUIMessageBaseDataProviderDataSource: NSObjectProtocol {
    func dataProviderDataSourceWillChange(_ dataProvider: TUIMessageBaseDataProvider)
    func dataProviderDataSourceChange(_ dataProvider: TUIMessageBaseDataProvider, withType type: TUIMessageBaseDataProviderDataSourceChangeType, atIndex index: UInt, animation: Bool)
    func dataProviderDataSourceDidChange(_ dataProvider: TUIMessageBaseDataProvider)
    func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, onRemoveHeightCache cellData: TUIMessageCellData)

    @objc optional func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, receiveReadMsgWithUserID userId: String, time timestamp: time_t)
    @objc optional func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, receiveReadMsgWithGroupID groupID: String, msgID: String, readCount: UInt, unreadCount: UInt)
    @objc optional func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, receiveNewUIMsg uiMsg: TUIMessageCellData)
    @objc optional func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, receiveRevokeUIMsg uiMsg: TUIMessageCellData)
    @objc optional func dataProvider(_ dataProvider: TUIMessageBaseDataProvider, customCellDataFromNewIMMessage msg: V2TIMMessage) -> TUIMessageCellData?
}

class TUIMessageBaseDataProvider: NSObject, V2TIMAdvancedMsgListener, V2TIMGroupListener, TUIMessageProgressManagerDelegate {
    func onUploadProgress(msgID: String, progress: Int) {}
    func onDownloadProgress(msgID: String, progress: Int) {}
    func onMessageSendingResultChanged(type: TUIMessageSendingResultType, messageID: String) {}

    var conversationModel: TUIChatConversationModel?
    var uiMsgs: [TUIMessageCellData] = []
    var sentReadGroupMsgSet: Set<String> = .init(minimumCapacity: 10)
    var heightCache: [String: NSNumber] = [:]
    var isLoadingData: Bool = false
    var isNoMoreMsg: Bool = false
    var isFirstLoad: Bool = true
    var lastMsg: V2TIMMessage?
    var msgForDate: V2TIMMessage?
    var groupSelfInfo: V2TIMGroupMemberFullInfo?
    var groupPinList: [V2TIMMessage] = []
    var groupInfo: V2TIMGroupInfo?
    var mergeAdjacentMsgsFromTheSameSender: Bool = false
    var pageCount: Int = 20
    weak var dataSource: TUIMessageBaseDataProviderDataSource?
    var groupRoleChanged: ((V2TIMGroupMemberRole) -> Void)?
    var pinGroupMessageChanged: (([V2TIMMessage]) -> Void)?

    var changedRole: V2TIMGroupMemberRole = .GROUP_MEMBER_UNDEFINED {
        didSet {
            if let groupRoleChanged = self.groupRoleChanged {
                groupRoleChanged(self.changedRole)
            }
        }
    }

    override init() {
        super.init()
    }

    init(conversationModel: TUIChatConversationModel) {
        self.conversationModel = conversationModel
        super.init()
        self.registerTUIKitNotification()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - TUIKitNotification

    func registerTUIKitNotification() {
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
        V2TIMManager.sharedInstance().addGroupListener(listener: self)

        NotificationCenter.default.addObserver(self, selector: #selector(self.onMessageStatusChanged(_:)), name: NSNotification.Name(TUIKitNotification_onMessageStatusChanged), object: nil)
    }

    @objc func onMessageStatusChanged(_ notification: Notification) {
        guard let targetMsg = notification.object as? V2TIMMessage else { return }
        let targetMsgID = targetMsg.msgID.safeValue
        var isMatch = false
        for uiMsgCellData in self.uiMsgs {
            if uiMsgCellData.msgID == targetMsgID {
                self.dataSource?.dataProviderDataSourceWillChange(self)
                let index = self.uiMsgs.firstIndex(of: uiMsgCellData)!
                self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: true)
                self.dataSource?.dataProviderDataSourceDidChange(self)
                isMatch = true
                break
            }
        }
        if !isMatch {
            self.onRecvNewMessage(targetMsg)
        }
    }

    // MARK: - V2TIMAdvancedMsgListener

    func onRecvNewMessage(_ msg: V2TIMMessage) {
        let uiMsgCellDataArray = self.transUIMsgFromIMMsg([msg])
        if uiMsgCellDataArray.isEmpty {
            return
        }

        let uiMsgCellData = uiMsgCellDataArray.last!
        uiMsgCellData.source = .Msg_Source_OnlinePush

        if uiMsgCellData is TUITypingStatusCellData {
            if !TUIChatConfig.shared.enableTypingStatus {
                return
            }
            if let statusData = uiMsgCellData as? TUITypingStatusCellData {
                if !Thread.isMainThread {
                    DispatchQueue.main.async {
                        self.dealTypingByStatusCellData(statusData)
                    }
                    return
                } else {
                    self.dealTypingByStatusCellData(statusData)
                }
            }
            return
        }

        self.preProcessMessage(uiMsgCellDataArray) { [weak self] in
            guard let self else { return }
            self.dataSource?.dataProviderDataSourceWillChange(self)
            autoreleasepool {
                for uiMsg in uiMsgCellDataArray {
                    self.addUIMsg(uiMsg)
                    self.dataSource?.dataProviderDataSourceChange(self, withType: .insert, atIndex: UInt(self.uiMsgs.count - 1), animation: true)
                }
            }
            self.dataSource?.dataProviderDataSourceDidChange(self)
            self.dataSource?.dataProvider?(self, receiveNewUIMsg: uiMsgCellDataArray.last!)
        }
    }

    public func transUIMsgFromIMMsg(_ msgs: [V2TIMMessage]) -> [TUIMessageCellData] {
        var msgCellDataArray: [TUIMessageCellData] = []
        for k in stride(from: msgs.count - 1, through: 0, by: -1) {
            let msg = msgs[k]
            if (!msg.userID.isNilOrEmpty && msg.userID != self.conversationModel?.userID) || (!msg.groupID.isNilOrEmpty && msg.groupID.safeValue != (self.conversationModel?.groupID)) {
                continue
            }

            var cellData: TUIMessageCellData? = nil
            cellData = self.dataSource?.dataProvider?(self, customCellDataFromNewIMMessage: msg)

            if cellData == nil {
                cellData = type(of: self).convertToCellData(from: msg)
            }
            if let cellData = cellData {
                if let dateMsg = self.getSystemMsgFromDate(msg.timestamp) {
                    if self.mergeAdjacentMsgsFromTheSameSender {
                        dateMsg.showName = false
                    }
                    self.msgForDate = msg
                    msgCellDataArray.append(dateMsg)
                }
                if self.mergeAdjacentMsgsFromTheSameSender {
                    cellData.showName = false
                }
                msgCellDataArray.append(cellData)
            }
        }
        return msgCellDataArray
    }

    func onRecvMessageRead(_ receiptList: [V2TIMMessageReceipt]) {
        if safeArray(receiptList).isEmpty {
            print("group receipt data is empty, ignore")
            return
        }
        if !(self.dataSource?.responds(to: #selector(TUIMessageBaseDataProviderDataSource.dataProvider(_:receiveReadMsgWithGroupID:msgID:readCount:unreadCount:))) ?? false) {
            print("data source can not respond to protocol, ignore")
        }
        var dict: [String: V2TIMMessageReceipt] = [:]
        for receipt in receiptList {
            if let msgID = receipt.msgID {
                dict[msgID] = receipt
            }
        }
        for data in self.uiMsgs {
            if dict.keys.contains(data.innerMessage.msgID.safeValue) {
                let receipt = dict[data.innerMessage.msgID.safeValue]!
                data.messageReceipt = receipt
                if let msgID = receipt.msgID {
                    self.dataSource?.dataProvider?(self, receiveReadMsgWithGroupID: receipt.groupID.safeValue, msgID: msgID, readCount: UInt(receipt.readCount), unreadCount: UInt(receipt.unreadCount))
                }
            }
        }
    }

    func onRecvMessageRevoked(_ msgID: String, operateUser: V2TIMUserFullInfo?, reason: String?) {
        DispatchQueue.main.async {
            for uiMsg in self.uiMsgs {
                if uiMsg.msgID == msgID {
                    self.dataSource?.dataProviderDataSourceWillChange(self)
                    let index = self.uiMsgs.firstIndex(of: uiMsg)!
                    if let revokeCellData = type(of: self).getRevokeCellData(uiMsg.innerMessage) as? TUISystemMessageCellData {
                        revokeCellData.content = type(of: self).getRevokeDispayString(uiMsg.innerMessage, operateUser: operateUser, reason: reason)
                        if (operateUser?.userID.isNilOrEmpty ?? true) && operateUser?.userID != uiMsg.innerMessage.sender.safeValue {
                            revokeCellData.supportReEdit = false
                        }
                        self.replaceUIMsg(revokeCellData, atIndex: index)
                        self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: true)
                        self.dataSource?.dataProviderDataSourceDidChange(self)
                        self.dataSource?.dataProvider?(self, receiveRevokeUIMsg: uiMsg)
                        break
                    }
                }
            }
        }
    }

    func onRecvMessageModified(_ msg: V2TIMMessage) {
        for uiMsg in self.uiMsgs {
            if uiMsg.msgID == msg.msgID {
                if uiMsg.customReloadCell(withNewMsg: msg) {
                    return
                }
                let uiMsgCellDataArray = self.transUIMsgFromIMMsg([msg])
                if uiMsgCellDataArray.isEmpty {
                    return
                }
                let uiMsgCellData = uiMsgCellDataArray.last!
                uiMsgCellData.messageReceipt = uiMsg.messageReceipt
                self.preProcessMessage([uiMsgCellData]) {
                    let index = self.uiMsgs.firstIndex(of: uiMsg)!
                    if index < self.uiMsgs.count {
                        self.dataSource?.dataProviderDataSourceWillChange(self)
                        self.replaceUIMsg(uiMsgCellData, atIndex: index)
                        self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: true)
                        self.dataSource?.dataProviderDataSourceDidChange(self)
                    }
                }
                return
            }
        }
    }

    func dealTypingByStatusCellData(_ statusData: TUITypingStatusCellData) {
        if statusData.typingStatus == 1 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.resetTypingStatus), object: nil)

            self.conversationModel?.otherSideTyping = true
            self.perform(#selector(self.resetTypingStatus), with: nil, afterDelay: 5.0)
        } else {
            self.conversationModel?.otherSideTyping = false
        }
    }

    @objc func resetTypingStatus() {
        self.conversationModel?.otherSideTyping = false
    }

    // MARK: - Msgs

    func loadMessageSucceedBlock(_ succeedBlock: @escaping (Bool, Bool, [TUIMessageCellData]) -> Void, FailBlock failBlock: @escaping (Int, String) -> Void) {
        if self.isLoadingData || self.isNoMoreMsg {
            failBlock(Int(ERR_SUCC.rawValue), "refreshing")
            return
        }
        self.isLoadingData = true

        if let userID = self.conversationModel?.userID, userID.count > 0 {
            V2TIMManager.sharedInstance().getC2CHistoryMessageList(userID, count: Int32(self.pageCount), lastMsg: self.lastMsg, succ: { msgs in
                if let msgs = msgs, msgs.count > 0 {
                    self.lastMsg = msgs.last
                    self.loadMessages(msgs, SucceedBlock: succeedBlock)
                }
            }, fail: { code, desc in
                self.isLoadingData = false
                failBlock(Int(code), desc ?? "")
            })
        } else if let groupID = self.conversationModel?.groupID, groupID.count > 0 {
            V2TIMManager.sharedInstance().getGroupHistoryMessageList(groupID, count: Int32(self.pageCount), lastMsg: self.lastMsg, succ: { msgs in
                if let msgs = msgs, msgs.count > 0 {
                    self.lastMsg = msgs.last
                    self.loadMessages(msgs, SucceedBlock: succeedBlock)
                }
            }, fail: { code, desc in
                self.isLoadingData = false
                failBlock(Int(code), desc ?? "")
            })
        }
    }

    func loadMessages(_ msgs: [V2TIMMessage], SucceedBlock succeedBlock: @escaping (Bool, Bool, [TUIMessageCellData]) -> Void) {
        let uiMsgArray = self.transUIMsgFromIMMsg(msgs)
        if uiMsgArray.isEmpty {
            return
        }
        self.preProcessMessage(uiMsgArray) {
            if msgs.count < self.pageCount {
                self.isNoMoreMsg = true
            }
            if !uiMsgArray.isEmpty {
                let indexSet = IndexSet(integersIn: 0..<uiMsgArray.count)
                self.insertUIMsgs(uiMsgArray, atIndexes: indexSet)
            }

            self.isLoadingData = false
            succeedBlock(self.isFirstLoad, self.isNoMoreMsg, uiMsgArray)
            self.isFirstLoad = false
        }
    }

    public func preProcessMessage(_ uiMsgArray: [TUIMessageCellData], callback: (() -> Void)?) {
        self.processMessageSync(uiMsgArray, callback: callback)
        self.processMessageAsync(uiMsgArray)
    }

    func processMessageSync(_ uiMsgArray: [TUIMessageCellData], callback: (() -> Void)?) {
        callback?()
    }

    func processMessageAsync(_ uiMsgArray: [TUIMessageCellData]) {
        self.getReactFromMessage(uiMsgArray)

        self.requestForAdditionalUserInfo(uiMsgArray) {
            DispatchQueue.main.async {
                self.dataSource?.dataProviderDataSourceWillChange(self)
                for uiMsg in uiMsgArray {
                    let userIDList = self.getUserIDListForAdditionalUserInfo([uiMsg])
                    if userIDList.isEmpty {
                        continue
                    }
                    if let index = self.uiMsgs.firstIndex(of: uiMsg) {
                        if index != NSNotFound {
                            self.dataSource?.dataProvider(self, onRemoveHeightCache: uiMsg)
                            self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: true)
                        }
                    }
                }
                self.dataSource?.dataProviderDataSourceDidChange(self)
            }
            self.processQuoteMessage(uiMsgArray)
        }
    }

    func getReactFromMessage(_ uiMsgArray: [TUIMessageCellData]) {
        if uiMsgArray.isEmpty {
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name("TUIKitFetchReactNotification"), object: uiMsgArray)
    }

    func requestForAdditionalUserInfo(_ uiMsgArray: [TUIMessageCellData], callback: @escaping () -> Void) {
        let userIDList = self.getUserIDListForAdditionalUserInfo(uiMsgArray)
        if userIDList.isEmpty {
            callback()
            return
        }

        self.requestForUserDetailsInfo(userIDList) { result in
            for cellData in uiMsgArray {
                var additionalUserInfoResult: [String: TUIRelationUserModel] = [:]
                let userIDList = self.getUserIDListForAdditionalUserInfo([cellData])
                for userID in userIDList {
                    if let userInfo = result[userID] {
                        additionalUserInfoResult[userID] = userInfo
                    }
                }
                cellData.additionalUserInfoResult = additionalUserInfoResult
            }
            callback()
        }
    }

    func requestForUserDetailsInfo(_ userIDList: [String], callback: (([String: TUIRelationUserModel]) -> Void)?) {
        var result: [String: TUIRelationUserModel] = [:]
        if let groupID = self.conversationModel?.groupID, groupID.count > 0 {
            V2TIMManager.sharedInstance().getGroupMembersInfo(groupID, memberList: userIDList, succ: { memberList in
                guard let memberList = memberList else {
                    callback?(result)
                    return
                }
                for obj in memberList {
                    if let userID = obj.userID, !userID.isEmpty {
                        let userInfo = TUIRelationUserModel()
                        userInfo.userID = userID
                        userInfo.nickName = obj.nickName.safeValue
                        userInfo.friendRemark = obj.friendRemark.safeValue
                        userInfo.nameCard = obj.nameCard.safeValue
                        userInfo.faceURL = obj.faceURL.safeValue
                        result[userID] = userInfo
                    }
                }
                callback?(result)
            }, fail: { _, _ in
                callback?(result)
            })
        } else {
            V2TIMManager.sharedInstance().getFriendsInfo(userIDList, succ: { resultList in
                guard let resultList = resultList else {
                    callback?(result)
                    return
                }
                for item in resultList {
                    if let friendInfo = item.friendInfo, let userID = friendInfo.userID, let userFullInfo = friendInfo.userFullInfo {
                        let userInfo = TUIRelationUserModel()
                        userInfo.userID = userID
                        userInfo.nickName = userFullInfo.nickName.safeValue
                        userInfo.friendRemark = friendInfo.friendRemark.safeValue
                        userInfo.faceURL = userFullInfo.faceURL.safeValue
                        result[userID] = userInfo
                    }
                }
                callback?(result)
            }, fail: { _, _ in
                callback?(result)
            })
        }
    }

    func getUserIDListForAdditionalUserInfo(_ uiMsgArray: [TUIMessageCellData]) -> [String] {
        var userIDSet: Set<String> = []

        for cellData in uiMsgArray {
            if let messageModifyReplies = cellData.messageModifyReplies as? [NSDictionary], !messageModifyReplies.isEmpty {
                for obj in messageModifyReplies {
                    if let dic = obj as? [String: Any], let messageSender = dic["messageSender"] as? String, !messageSender.isEmpty {
                        userIDSet.insert(messageSender)
                    }
                }
            }
        }

        for cellData in uiMsgArray {
            let array = cellData.requestForAdditionalUserInfo()
            if !array.isEmpty {
                userIDSet.formUnion(array)
            }
        }

        return Array(userIDSet)
    }

    func processQuoteMessage(_ uiMsgCellDataArray: [TUIMessageCellData]) {
        // Subclasses implement this method
    }

    func sendUIMsg(_ uiMsg: TUIMessageCellData, toConversation conversationData: TUIChatConversationModel, willSendBlock: ((Bool, TUIMessageCellData?) -> Void)?, SuccBlock succ: V2TIMSucc?, FailBlock fail: V2TIMFail?) {
        self.preProcessMessage([uiMsg]) {
            DispatchQueue.main.async {
                let imMsg = uiMsg.innerMessage
                let placeholderCellData = uiMsg.placeHolder
                var dateMsg: TUIMessageCellData? = nil
                var isReSent = false
                if uiMsg.status == .Msg_Status_Init {
                    dateMsg = self.getSystemMsgFromDate(imMsg.timestamp)
                } else {
                    isReSent = true
                    dateMsg = self.getSystemMsgFromDate(Date())
                }

                imMsg.isExcludedFromUnreadCount = TUIConfig.default().isExcludedFromUnreadCount
                imMsg.isExcludedFromLastMessage = TUIConfig.default().isExcludedFromLastMessage

                uiMsg.identifier = TUILogin.getUserID()!

                self.dataSource?.dataProviderDataSourceWillChange(self)

                if isReSent {
                    let row = self.uiMsgs.firstIndex(of: uiMsg)!
                    self.removeUImsgAtIndex(row)
                    self.dataSource?.dataProviderDataSourceChange(self, withType: .delete, atIndex: UInt(row), animation: true)
                }
                if let placeholderCellData = placeholderCellData {
                    let row = self.uiMsgs.firstIndex(of: placeholderCellData)!
                    self.replaceUIMsg(uiMsg, atIndex: row)
                    self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(row), animation: false)
                } else {
                    if let dateMsg = dateMsg {
                        self.addUIMsg(dateMsg)
                        self.dataSource?.dataProviderDataSourceChange(self, withType: .insert, atIndex: UInt(self.uiMsgs.count - 1), animation: true)
                    }
                    self.addUIMsg(uiMsg)
                    self.dataSource?.dataProviderDataSourceChange(self, withType: .insert, atIndex: UInt(self.uiMsgs.count - 1), animation: true)
                }

                self.dataSource?.dataProviderDataSourceDidChange(self)

                willSendBlock?(isReSent, dateMsg)

                if dateMsg != nil {
                    self.msgForDate = imMsg
                }

                let appendParams = TUISendMessageAppendParams()
                appendParams.isSendPushInfo = true
                appendParams.isOnlineUserOnly = false
                appendParams.priority = .PRIORITY_NORMAL
                uiMsg.msgID = type(of: self).sendMessage(imMsg, toConversation: conversationData, appendParams: appendParams, Progress: { progress in
                    TUIMessageProgressManager.shared.appendUploadProgress(uiMsg.msgID, progress: Int(progress))
                }, SuccBlock: {
                    TUIMessageProgressManager.shared.appendUploadProgress(uiMsg.msgID, progress: 100)
                    succ?()
                    TUIMessageProgressManager.shared.notifyMessageSendingResult(uiMsg.msgID, result: TUIMessageSendingResultType.success)
                }, FailBlock: { code, desc in
                    fail?(code, desc)
                    TUIMessageProgressManager.shared.notifyMessageSendingResult(uiMsg.msgID, result: TUIMessageSendingResultType.failure)
                })
            }
        }
    }

    func revokeUIMsg(_ uiMsg: TUIMessageCellData, SuccBlock succ: V2TIMSucc?, FailBlock fail: V2TIMFail?) {
        let imMsg = uiMsg.innerMessage
        let index = self.uiMsgs.firstIndex(of: uiMsg)
        if index == nil {
            fail?(ERR_INVALID_PARAMETERS.rawValue, "not found cellData in uiMsgs")
            return
        }

        type(of: self).revokeMessage(imMsg, succ: {
            succ?()
        }, fail: fail)
    }

    func deleteUIMsgs(_ uiMsgArray: [TUIMessageCellData], SuccBlock succ: V2TIMSucc?, FailBlock fail: V2TIMFail?) {
        // Implement delete logic here
    }

    func addUIMsg(_ cellData: TUIMessageCellData) {
        self.uiMsgs.append(cellData)
        if self.mergeAdjacentMsgsFromTheSameSender {
            type(of: self).updateUIMsgStatus(cellData, uiMsgArray: self.uiMsgs)
        }
    }

    func removeUIMsg(_ cellData: TUIMessageCellData) {
        if let index = self.uiMsgs.firstIndex(of: cellData) {
            self.uiMsgs.remove(at: index)
            self.dataSource?.dataProvider(self, onRemoveHeightCache: cellData)
            if self.mergeAdjacentMsgsFromTheSameSender {
                TUIMessageBaseDataProvider.updateUIMsgStatus(cellData, uiMsgArray: self.uiMsgs)
            }
        }
    }

    func sendPlaceHolderUIMessage(_ placeHolderCellData: TUIMessageCellData) {
        let imMsg = placeHolderCellData.innerMessage
        var dateMsg: TUIMessageCellData? = nil
        if placeHolderCellData.status == .Msg_Status_Init && imMsg.timestamp != nil {
            dateMsg = self.getSystemMsgFromDate(imMsg.timestamp)
        }

        self.dataSource?.dataProviderDataSourceWillChange(self)

        if let dateMsg = dateMsg {
            self.addUIMsg(dateMsg)
            self.dataSource?.dataProviderDataSourceChange(self, withType: .insert, atIndex: UInt(self.uiMsgs.count - 1), animation: true)
        }

        self.addUIMsg(placeHolderCellData)
        self.dataSource?.dataProviderDataSourceChange(self, withType: .insert, atIndex: UInt(self.uiMsgs.count - 1), animation: true)
        self.dataSource?.dataProviderDataSourceDidChange(self)
    }

    func insertUIMsgs(_ uiMsgArray: [TUIMessageCellData], atIndexes indexes: IndexSet) {
        var currentIndex = indexes.startIndex
        for (offset, index) in indexes.enumerated() {
            if offset < uiMsgArray.count {
                self.uiMsgs.insert(uiMsgArray[offset], at: index)
            }
            currentIndex = indexes.index(after: currentIndex)
        }
        if self.mergeAdjacentMsgsFromTheSameSender {
            for cellData in uiMsgArray {
                Self.updateUIMsgStatus(cellData, uiMsgArray: self.uiMsgs)
            }
        }
    }

    func addUIMsgs(_ uiMsgArray: [TUIMessageCellData]) {
        self.uiMsgs.append(contentsOf: uiMsgArray)
        if self.mergeAdjacentMsgsFromTheSameSender {
            for cellData in uiMsgArray {
                type(of: self).updateUIMsgStatus(cellData, uiMsgArray: self.uiMsgs)
            }
        }
    }

    func removeUIMsgList(_ cellDatas: [TUIMessageCellData]) {
        for uiMsg in cellDatas {
            self.removeUIMsg(uiMsg)
        }
    }

    func removeUImsgAtIndex(_ index: Int) {
        if index < self.uiMsgs.count {
            let msg = self.uiMsgs[index]
            self.removeUIMsg(msg)
        }
    }

    func clearUIMsgList() {
        let clearArray = Array(self.uiMsgs)
        self.removeUIMsgList(clearArray)
        self.msgForDate = nil
        self.uiMsgs = []
    }

    func replaceUIMsg(_ cellData: TUIMessageCellData, atIndex index: Int) {
        if index < self.uiMsgs.count {
            let oldMsg = self.uiMsgs[index]
            self.dataSource?.dataProvider(self, onRemoveHeightCache: oldMsg)
            self.uiMsgs[index] = cellData
            if self.mergeAdjacentMsgsFromTheSameSender {
                type(of: self).updateUIMsgStatus(cellData, uiMsgArray: self.uiMsgs)
            }
        }
    }

    func sendLatestMessageReadReceipt() {
        self.sendMessageReadReceiptAtIndexes([self.uiMsgs.count - 1])
    }

    func sendMessageReadReceiptAtIndexes(_ indexes: [Int]) {
        if indexes.isEmpty {
            print("sendMessageReadReceipt, but indexes is empty, ignore")
            return
        }
        var array: [V2TIMMessage] = []
        for i in indexes {
            if i < 0 || i >= self.uiMsgs.count {
                continue
            }
            let data = self.uiMsgs[i]
            if data.innerMessage.isSelf {
                continue
            }
            let msgID = data.msgID
            if !msgID.isEmpty {
                if self.sentReadGroupMsgSet.contains(msgID) {
                    continue
                } else {
                    self.sentReadGroupMsgSet.insert(msgID)
                }
            }
            if !data.innerMessage.needReadReceipt {
                continue
            }
            array.append(data.innerMessage)
        }
        if array.isEmpty {
            return
        }
        type(of: self).sendMessageReadReceipts(array)
    }

    func getIndexOfMessage(_ msgID: String) -> Int {
        if msgID.isEmpty {
            return -1
        }
        for i in 0..<self.uiMsgs.count {
            let data = self.uiMsgs[i]
            if data.msgID == msgID {
                return i
            }
        }
        return -1
    }

    private func getSystemMsgFromDate(_ date: Date) -> TUIMessageCellData? {
        if self.msgForDate == nil || abs(date.timeIntervalSince(self.msgForDate!.timestamp)) > MaxDateMessageDelay {
            return type(of: self).getSystemMsgFromDate(date)
        }
        return nil
    }

    static func updateUIMsgStatus(_ cellData: TUIMessageCellData, uiMsgArray: [TUIMessageCellData]) {
        if !uiMsgArray.contains(cellData) {
            return
        }
        let index = uiMsgArray.firstIndex(of: cellData)!
        let data = uiMsgArray[index]

        var lastData: TUIMessageCellData? = nil
        if index >= 1 {
            lastData = uiMsgArray[index - 1]
            if !(lastData is TUISystemMessageCellData) {
                if lastData!.identifier == data.identifier && !(data is TUISystemMessageCellData) && lastData!.direction == data.direction {
                    lastData!.sameToNextMsgSender = true
                    lastData!.showAvatar = false
                } else {
                    lastData!.sameToNextMsgSender = false
                    lastData!.showAvatar = (lastData!.direction == .MsgDirectionIncoming)
                }
            }
        }

        var nextData: TUIMessageCellData? = nil
        if index < uiMsgArray.count - 1 {
            nextData = uiMsgArray[index + 1]
            if data.identifier == nextData!.identifier && data.direction == nextData!.direction {
                data.sameToNextMsgSender = true
                data.showAvatar = false
            } else {
                data.sameToNextMsgSender = false
                data.showAvatar = (data.direction == .MsgDirectionIncoming)
            }
        }

        if index == uiMsgArray.count - 1 {
            data.showAvatar = (data.direction == .MsgDirectionIncoming)
            data.sameToNextMsgSender = false
        }
    }

    func getPinMessageList() {
        if let groupID = self.conversationModel?.groupID, groupID.count > 0 {
            V2TIMManager.sharedInstance().getPinnedGroupMessageList(groupID, succ: { messageList in
                self.groupPinList = messageList ?? []
                self.pinGroupMessageChanged?(self.groupPinList)
            }, fail: { _, _ in
                self.groupPinList = []
                self.pinGroupMessageChanged?(self.groupPinList)
            })
        }
    }

    func loadGroupInfo(_ callback: @escaping () -> Void) {
        guard let groupID = self.conversationModel?.groupID, groupID.count > 0 else {
            callback()
            return
        }

        V2TIMManager.sharedInstance().getGroupsInfo([groupID], succ: { groupResultList in
            if groupResultList?.count == 1 {
                self.groupInfo = groupResultList?[0].info
            }
            callback()
        }, fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
        })
    }

    func getSelfInfoInGroup(_ callback: (() -> Void)?) {
        guard let loginUserID = V2TIMManager.sharedInstance().getLoginUser() else {
            callback?()
            return
        }

        if let enableRoom = self.conversationModel?.enableRoom, !enableRoom {
            callback?()
            return
        }

        if let groupID = self.conversationModel?.groupID {
            V2TIMManager.sharedInstance().getGroupMembersInfo(groupID, memberList: [loginUserID], succ: { memberList in
                guard let memberList = memberList else {
                    callback?()
                    return
                }
                for item in memberList {
                    if item.userID == loginUserID {
                        self.groupSelfInfo = item
                        if self.groupInfo?.owner == loginUserID {
                            self.changedRole = .GROUP_MEMBER_ROLE_SUPER
                        } else {
                            self.changedRole = V2TIMGroupMemberRole(rawValue: Int(item.role))!
                        }
                        break
                    }
                }
                callback?()
            }, fail: { code, desc in
                TUITool.makeToastError(Int(code), msg: desc)
                callback?()
            })
        }
    }

    func isCurrentUserRoleSuperAdminInGroup() -> Bool {
        if self.changedRole != .GROUP_MEMBER_UNDEFINED {
            return self.changedRole == .GROUP_MEMBER_ROLE_ADMIN || self.changedRole == .GROUP_MEMBER_ROLE_SUPER
        }
        return self.groupInfo?.owner == V2TIMManager.sharedInstance().getLoginUser() || self.groupSelfInfo?.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue) || self.groupSelfInfo?.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue)
    }

    func isCurrentMessagePin(_ msgID: String) -> Bool {
        return self.groupPinList.contains { $0.msgID == msgID }
    }

    func pinGroupMessage(_ groupID: String, message: V2TIMMessage, isPinned: Bool, succ: V2TIMSucc?, fail: V2TIMFail?) {
        V2TIMManager.sharedInstance().pinGroupMessage(groupID, message: message, isPinned: isPinned, succ: {
            if isPinned {
                // del from changed
            } else {
                // add from changed
            }
            succ?()
        }, fail: { code, desc in
            fail?(code, desc)
        })
    }

    func onGroupMessagePinned(_ groupID: String, message: V2TIMMessage, isPinned: Bool, opUser: V2TIMGroupMemberInfo?) {
        if isPinned {
            self.groupPinList.append(message)
        } else {
            self.groupPinList.removeAll { $0.msgID == message.msgID.safeValue }
        }
        self.pinGroupMessageChanged?(self.groupPinList)
    }

    func onGroupInfoChanged(_ groupID: String, changeInfoList: [V2TIMGroupChangeInfo]) {
        if groupID != self.conversationModel?.groupID {
            return
        }

        for changeInfo in changeInfoList {
            if changeInfo.type == .GROUP_INFO_CHANGE_TYPE_OWNER {
                let ownerID = changeInfo.value
                if ownerID == TUILogin.getUserID() {
                    self.changedRole = .GROUP_MEMBER_ROLE_SUPER
                } else if self.changedRole == .GROUP_MEMBER_ROLE_SUPER {
                    self.changedRole = .GROUP_MEMBER_ROLE_MEMBER
                }
                return
            }
        }
    }

    func onGrantAdministrator(_ groupID: String, opUser: V2TIMGroupMemberInfo?, memberList: [V2TIMGroupMemberInfo]) {
        if groupID != self.conversationModel?.groupID {
            return
        }
        for changeInfo in memberList {
            if changeInfo.userID == TUILogin.getUserID() {
                self.changedRole = .GROUP_MEMBER_ROLE_ADMIN
                return
            }
        }
    }

    func onRevokeAdministrator(_ groupID: String, opUser: V2TIMGroupMemberInfo?, memberList: [V2TIMGroupMemberInfo]) {
        if groupID != self.conversationModel?.groupID {
            return
        }
        for changeInfo in memberList {
            if changeInfo.userID == TUILogin.getUserID() {
                self.changedRole = .GROUP_MEMBER_ROLE_MEMBER
                return
            }
        }
    }
}

extension TUIMessageBaseDataProvider {
    static let kOfflinePushVersion = 1

    static func sendMessage(_ message: V2TIMMessage, toConversation conversationData: TUIChatConversationModel, appendParams: TUISendMessageAppendParams?, Progress progress: V2TIMProgress?, SuccBlock succ: V2TIMSucc?, FailBlock fail: V2TIMFail?) -> String {
        let userID = conversationData.userID ?? ""
        let groupID = conversationData.groupID ?? ""
        var conversationID = ""
        if appendParams == nil {
            print("appendParams cannot be nil")
        }
        let isSendPushInfo = appendParams?.isSendPushInfo ?? false
        let isOnlineUserOnly = appendParams?.isOnlineUserOnly ?? false
        let priority = appendParams?.priority ?? .PRIORITY_NORMAL
        if !userID.isEmpty {
            conversationID = "c2c_\(userID)"
        }

        if !groupID.isEmpty {
            conversationID = "group_\(groupID)"
        }

        if let convID = conversationData.conversationID, !convID.isEmpty {
            conversationID = convID
        }

        var pushInfo: V2TIMOfflinePushInfo? = nil
        if isSendPushInfo {
            pushInfo = V2TIMOfflinePushInfo()
            let isGroup = !groupID.isEmpty
            var senderId = isGroup ? groupID : TUILogin.getUserID()
            senderId = senderId ?? ""
            var nickName = isGroup ? conversationData.title : (TUILogin.getNickName() ?? TUILogin.getUserID())
            nickName = nickName ?? ""
            let content = self.getDisplayString(message) ?? ""
            let extInfo = OfflinePushExtInfo()
            let entity = extInfo.entity
            entity.action = 1
            entity.content = content
            entity.sender = senderId ?? ""
            entity.nickname = nickName ?? ""
            entity.faceUrl = TUILogin.getFaceUrl() ?? ""
            entity.chatType = isGroup ? V2TIMConversationType.GROUP.rawValue : V2TIMConversationType.C2C.rawValue
            entity.version = self.kOfflinePushVersion
            pushInfo?.ext = extInfo.toReportExtString()
            if !content.isEmpty {
                pushInfo?.desc = content
            }
            if let nickName = nickName {
                pushInfo?.title = nickName
            }
            pushInfo?.androidOPPOChannelID = "tuikit"
            pushInfo?.androidSound = TUIConfig.default().enableCustomRing ? "private_ring" : nil
            pushInfo?.androidHuaWeiCategory = "IM"
            pushInfo?.androidVIVOCategory = "IM"
        }

        if let groupType = conversationData.groupType, let groupID = conversationData.groupID, self.isGroupCommunity(groupType, groupID: groupID) || self.isGroupAVChatRoom(groupType) {
            message.needReadReceipt = false
        }

        if !conversationID.isEmpty {
            V2TIMManager.sharedInstance().markConversation([conversationID], markType: NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_HIDE.rawValue), enableMark: false, succ: nil, fail: nil)
        }

        if let userID = conversationData.userID, !userID.isEmpty {
            let cloudCustomDataDic: [String: Any] = [
                "needTyping": 1,
                "version": 1
            ]
            message.setCloudCustomData(cloudCustomDataDic as NSObject, forType: messageFeature)
        }

        return V2TIMManager.sharedInstance().send(message, receiver: userID, groupID: groupID, priority: priority, onlineUserOnly: isOnlineUserOnly, offlinePushInfo: pushInfo, progress: progress, succ: {
            succ?()
        }, fail: { code, desc in
            if code == ERR_SDK_INTERFACE_NOT_SUPPORT.rawValue {
                TUITool.postUnsupportNotification(ofService: TUISwift.tuiKitLocalizableString("TUIKitErrorUnsupportIntefaceMessageRead"))
            }
            fail?(code, desc)
        })
    }

    func getLastMessage(_ isFromLocal: Bool, succ: @escaping (V2TIMMessage?) -> Void, fail: V2TIMFail?) {
        let option = V2TIMMessageListGetOption()
        if let userID = self.conversationModel?.userID, !userID.isEmpty {
            option.userID = userID
        }
        if let groupID = self.conversationModel?.groupID, !groupID.isEmpty {
            option.groupID = groupID
        }
        option.getType = isFromLocal ? .GET_LOCAL_OLDER_MSG : .GET_CLOUD_OLDER_MSG
        option.lastMsg = nil
        option.count = 1
        V2TIMManager.sharedInstance().getHistoryMessageList(option, succ: { msgs in
            succ(msgs?.first)
        }, fail: { code, desc in
            fail?(code, desc)
        })
    }

    static func isGroupCommunity(_ groupType: String, groupID: String) -> Bool {
        return groupType == "Community" || groupID.hasPrefix("@TGS#_")
    }

    static func isGroupAVChatRoom(_ groupType: String) -> Bool {
        return groupType == "AVChatRoom"
    }

    static func markC2CMessageAsRead(_ userID: String, succ: V2TIMSucc?, fail: V2TIMFail?) {
        let conversationID = "c2c_\(userID)"
        V2TIMManager.sharedInstance().cleanConversationUnreadMessageCount(conversationID, cleanTimestamp: 0, cleanSequence: 0, succ: succ, fail: fail)
    }

    static func markGroupMessageAsRead(_ groupID: String, succ: V2TIMSucc?, fail: V2TIMFail?) {
        let conversationID = "group_\(groupID)"
        V2TIMManager.sharedInstance().cleanConversationUnreadMessageCount(conversationID, cleanTimestamp: 0, cleanSequence: 0, succ: succ, fail: fail)
    }

    static func markConversationAsUndead(_ conversationIDList: [String], enableMark: Bool) {
        V2TIMManager.sharedInstance().markConversation(conversationIDList, markType: NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_UNREAD.rawValue), enableMark: enableMark, succ: nil, fail: nil)
    }

    static func revokeMessage(_ msg: V2TIMMessage, succ: V2TIMSucc?, fail: V2TIMFail?) {
        V2TIMManager.sharedInstance().revokeMessage(msg, succ: succ, fail: fail)
    }

    static func deleteMessages(_ msgList: [V2TIMMessage], succ: V2TIMSucc?, fail: V2TIMFail?) {
        V2TIMManager.sharedInstance().delete(msgList, succ: succ, fail: fail)
    }

    static func modifyMessage(_ msg: V2TIMMessage, completion: V2TIMMessageModifyCompletion?) {
        V2TIMManager.sharedInstance().modifyMessage(msg, completion: completion)
    }

    static func sendMessageReadReceipts(_ msgs: [V2TIMMessage]) {
        V2TIMManager.sharedInstance().sendMessageReadReceipts(msgs, succ: {
            print("sendMessageReadReceipts succeed")
        }, fail: { code, _ in
            if code == ERR_SDK_INTERFACE_NOT_SUPPORT.rawValue {
                TUITool.postUnsupportNotification(ofService: TUISwift.tuiKitLocalizableString("TUIKitErrorUnsupportIntefaceMessageRead"))
            }
        })
    }

    static func getReadMembersOfMessage(_ msg: V2TIMMessage, filter: V2TIMGroupMessageReadMembersFilter, nextSeq: UInt, completion: @escaping (Int, String?, [V2TIMGroupMemberInfo], UInt, Bool) -> Void) {
        V2TIMManager.sharedInstance().getGroupMessageReadMemberList(msg, filter: filter, nextSeq: UInt64(nextSeq), count: 100, succ: { members, nextSeq, isFinished in
            if let members = members as? [V2TIMGroupMemberInfo] {
                completion(0, nil, members, UInt(nextSeq), isFinished)
            }
        }, fail: { code, desc in
            completion(Int(code), desc, [], 0, false)
        })
    }

    static func getMessageReadReceipt(_ messages: [V2TIMMessage], succ: V2TIMMessageReadReceiptsSucc?, fail: V2TIMFail?) {
        if messages.isEmpty {
            fail?(-1, "messages empty")
            return
        }
        V2TIMManager.sharedInstance().getMessageReadReceipts(messages, succ: succ, fail: fail)
    }

    @objc class func convertToCellData(from message: V2TIMMessage) -> TUIMessageCellData? {
        // subclass override required
        return nil
    }

    @objc class func getSystemMsgFromDate(_ date: Date) -> TUIMessageCellData? {
        // subclass override required
        return nil
    }

    @objc class func getRevokeCellData(_ message: V2TIMMessage) -> TUIMessageCellData? {
        // subclass override required
        return nil
    }

    @objc class func getDisplayString(_ message: V2TIMMessage) -> String? {
        // subclass override required
        return nil
    }

    static func getRevokeDispayString(_ message: V2TIMMessage) -> String {
        return self.getRevokeDispayString(message, operateUser: nil, reason: nil)
    }

    static func getRevokeDispayString(_ message: V2TIMMessage, operateUser: V2TIMUserFullInfo?, reason: String?) -> String {
        let revokerInfo = message.revokerInfo ?? operateUser
        _ = message.hasRiskContent
        var revoker = message.sender.safeValue
        let messageSender = message.sender.safeValue
        if let revokerInfo = revokerInfo {
            revoker = revokerInfo.userID.safeValue
        }
        var content = TUISwift.timCommonLocalizableString("TUIKitMessageTipsNormalRecallMessage")
        if revoker == messageSender {
            if message.isSelf {
                content = TUISwift.timCommonLocalizableString("TUIKitMessageTipsYouRecallMessage")
            } else {
                if !message.userID.isNilOrEmpty {
                    content = TUISwift.timCommonLocalizableString("TUIKitMessageTipsOthersRecallMessage")
                } else if !message.groupID.isNilOrEmpty {
                    let userName = self.getShowName(message)
                    content = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
                }
            }
        } else {
            var userName = self.getShowName(message)
            if let revokerInfo = revokerInfo {
                userName = revokerInfo.showName()
            }
            content = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
        }
        return rtlString(content ?? "")
    }

    static func getGroupTipsDisplayString(_ message: V2TIMMessage) -> String {
        guard let tips = message.groupTipsElem else { return "" }
        let opUser = self.getOpUserName(tips.opMember!)
        let userList = self.getUserNameList(tips.memberList!)
        var str: String? = nil
        switch tips.type {
        case .GROUP_TIPS_TYPE_JOIN:
            if !opUser.isEmpty {
                if userList.isEmpty || (userList.count == 1 && opUser == userList.first) {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsJoinGroupFormat"), opUser)
                } else {
                    let users = userList.joined(separator: "、")
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsInviteJoinGroupFormat"), opUser, users)
                }
            }
        case .GROUP_TIPS_TYPE_INVITE:
            if !userList.isEmpty {
                let users = userList.joined(separator: "、")
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsInviteJoinGroupFormat"), opUser, users)
            }
        case .GROUP_TIPS_TYPE_QUIT:
            if !opUser.isEmpty {
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsLeaveGroupFormat"), opUser)
            }
        case .GROUP_TIPS_TYPE_KICKED:
            if !userList.isEmpty {
                let users = userList.joined(separator: "、")
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsKickoffGroupFormat"), opUser, users)
            }
        case .GROUP_TIPS_TYPE_SET_ADMIN:
            if !userList.isEmpty {
                let users = userList.joined(separator: "、")
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsSettAdminFormat"), users)
            }
        case .GROUP_TIPS_TYPE_CANCEL_ADMIN:
            if !userList.isEmpty {
                let users = userList.joined(separator: "、")
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsCancelAdminFormat"), users)
            }
        case .GROUP_TIPS_TYPE_GROUP_INFO_CHANGE:
            str = self.opGroupInfoChagedFormatStr(opUser, ofUserList: userList, ofTips: tips)
            if let strCache = str, !strCache.isEmpty {
                str = String(strCache.prefix(strCache.count - 1))
            }
        case .GROUP_TIPS_TYPE_MEMBER_INFO_CHANGE:
            for info in tips.memberChangeInfoList {
                let userId = info.userID
                let muteTime = info.muteTime
                let myId = V2TIMManager.sharedInstance().getLoginUser()
                let showName = self.getUserName(tips, with: userId ?? "")
                str = String(format: "%@ %@", userId == myId ? TUISwift.timCommonLocalizableString("You") : showName, muteTime == 0 ? TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnmute") : TUISwift.timCommonLocalizableString("TUIKitMessageTipsMute"))
                break
            }
        case .GROUP_TIPS_TYPE_PINNED_MESSAGE_ADDED:
            if !opUser.isEmpty {
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsGroupPinMessage"), opUser)
            }
        case .GROUP_TIPS_TYPE_PINNED_MESSAGE_DELETED:
            if !opUser.isEmpty {
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsGroupUnPinMessage"), opUser)
            }
        default:
            break
        }
        return rtlString(str ?? "")
    }

    static func getCustomMessageWithJsonData(_ data: Data) -> V2TIMMessage {
        return V2TIMManager.sharedInstance().createCustomMessage(data)
    }

    static func getCustomMessageWithJsonData(_ data: Data, desc: String, extensionInfo: String) -> V2TIMMessage {
        return V2TIMManager.sharedInstance().createCustomMessage(data: data, desc: desc, ext: extensionInfo)
    }

    static func opGroupInfoChagedFormatStr(_ opUser: String, ofUserList userList: [String], ofTips tips: V2TIMGroupTipsElem) -> String {
        var str = "\(opUser)"
        for info in tips.groupChangeInfoList {
            switch info.type {
            case .GROUP_INFO_CHANGE_TYPE_NAME:
                if let value = info.value {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIkitMessageTipsEditGroupNameFormat"), str, value)
                }
            case .GROUP_INFO_CHANGE_TYPE_INTRODUCTION:
                if let value = info.value {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupIntroFormat"), str, value)
                }
            case .GROUP_INFO_CHANGE_TYPE_NOTIFICATION:
                if let value = info.value {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupAnnounceFormat"), str, value)
                } else {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsDeleteGroupAnnounceFormat"), str)
                }
            case .GROUP_INFO_CHANGE_TYPE_FACE:
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupAvatarFormat"), str)
            case .GROUP_INFO_CHANGE_TYPE_OWNER:
                if !userList.isEmpty {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupOwnerFormat"), str, userList.first!)
                } else if let value = info.value {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupOwnerFormat"), str, value)
                }
            case .GROUP_INFO_CHANGE_TYPE_SHUT_UP_ALL:
                if info.boolValue {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitSetShutupAllFormat"), opUser)
                } else {
                    str = String(format: TUISwift.timCommonLocalizableString("TUIKitCancelShutupAllFormat"), opUser)
                }
            case .GROUP_INFO_CHANGE_TYPE_GROUP_ADD_OPT:
                let addOpt = info.intValue
                var addOptDesc = "unknown"
                if addOpt == V2TIMGroupAddOpt.GROUP_ADD_FORBID.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileJoinDisable")
                } else if addOpt == V2TIMGroupAddOpt.GROUP_ADD_AUTH.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAdminApprove")
                } else if addOpt == V2TIMGroupAddOpt.GROUP_ADD_ANY.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
                }
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupAddOptFormat"), str, addOptDesc)
            case .GROUP_INFO_CHANGE_TYPE_GROUP_APPROVE_OPT:
                let addOpt = info.intValue
                var addOptDesc = "unknown"
                if addOpt == V2TIMGroupAddOpt.GROUP_ADD_FORBID.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileInviteDisable")
                } else if addOpt == V2TIMGroupAddOpt.GROUP_ADD_AUTH.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAdminApprove")
                } else if addOpt == V2TIMGroupAddOpt.GROUP_ADD_ANY.rawValue {
                    addOptDesc = TUISwift.timCommonLocalizableString("TUIKitGroupProfileAutoApproval")
                }
                str = String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsEditGroupInviteOptFormat"), str, addOptDesc)
            default:
                break
            }
        }
        return rtlString(str)
    }

    static func getOpUserName(_ info: V2TIMGroupMemberInfo) -> String {
        if !info.nameCard.isNilOrEmpty {
            return info.nameCard.safeValue
        } else if !info.nickName.isNilOrEmpty {
            return info.nickName.safeValue
        } else {
            return info.userID.safeValue
        }
    }

    static func getUserNameList(_ infoList: [V2TIMGroupMemberInfo]) -> [String] {
        var userNameList: [String] = []
        for info in infoList {
            if !info.nameCard.isNilOrEmpty {
                userNameList.append(info.nameCard.safeValue)
            } else if !info.nickName.isNilOrEmpty {
                userNameList.append(info.nickName.safeValue)
            } else if !info.userID.isNilOrEmpty {
                userNameList.append(info.userID.safeValue)
            }
        }
        return userNameList
    }

    static func getUserIDList(_ infoList: [V2TIMGroupMemberInfo]) -> [String] {
        var userIDList: [String] = []
        for info in infoList {
            if !info.userID.isNilOrEmpty {
                userIDList.append(info.userID.safeValue)
            }
        }
        return userIDList
    }

    static func getShowName(_ message: V2TIMMessage?) -> String {
        guard let message = message else { return "" }
        var showName = message.sender.safeValue
        if !message.nameCard.isNilOrEmpty {
            showName = message.nameCard.safeValue
        } else if !message.friendRemark.isNilOrEmpty {
            showName = message.friendRemark.safeValue
        } else if !message.nickName.isNilOrEmpty {
            showName = message.nickName.safeValue
        }
        return showName
    }

    static func getUserName(_ tips: V2TIMGroupTipsElem, with userId: String) -> String {
        var str = ""
        for info in tips.memberList {
            if info.userID == userId {
                if !info.nameCard.isNilOrEmpty {
                    str = info.nameCard.safeValue
                } else if !info.friendRemark.isNilOrEmpty {
                    str = info.friendRemark.safeValue
                } else if !info.nickName.isNilOrEmpty {
                    str = info.nickName.safeValue
                } else {
                    str = userId
                }
                break
            }
        }
        return str
    }
}
