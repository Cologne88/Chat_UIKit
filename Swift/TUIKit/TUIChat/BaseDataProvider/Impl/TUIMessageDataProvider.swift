import AVFoundation
import Foundation
import TIMCommon
import TUICore

let MaxReEditMessageDelay: Double = 2 * 60

@objc protocol TUIMessageDataProviderDataSource: TUIMessageBaseDataProviderDataSource {
    @objc optional static func onGetCustomMessageCellDataClass(businessID: String) -> AnyClass?
}

class TUIMessageDataProvider: TUIMessageBaseDataProvider {
    static var gDataSourceClass: TUIMessageDataProviderDataSource.Type? = nil

    deinit {
        TUIMessageDataProvider.gCallingDataProvider = nil
    }

    static func setDataSourceClass(_ dataSourceClass: TUIMessageDataProviderDataSource.Type) {
        gDataSourceClass = dataSourceClass
    }

    override class func convertToCellData(from message: V2TIMMessage) -> TUIMessageCellData? {
        var data = parseMessageCellDataFromMessageStatus(message)
        if data == nil {
            data = parseMessageCellDataFromMessageCustomData(message)
        }
        if data == nil {
            data = parseMessageCellDataFromMessageElement(message)
        }

        if let data = data {
            fillPropertyToCellData(data, ofMessage: message)
        } else {
            print("current message will be ignored in chat page, msg:\(message)")
        }

        return data
    }

    static func parseMessageCellDataFromMessageStatus(_ message: V2TIMMessage) -> TUIMessageCellData? {
        var data: TUIMessageCellData? = nil
        if message.status == .MSG_STATUS_LOCAL_REVOKED {
            data = getRevokeCellData(message)
        }
        return data
    }

    static func parseMessageCellDataFromMessageCustomData(_ message: V2TIMMessage) -> TUIMessageCellData? {
        var data: TUIMessageCellData? = nil
        if message.isContainsCloudCustom(of: .messageReply) {
            data = TUIReplyMessageCellData.getCellData(message)
        } else if message.isContainsCloudCustom(of: .messageReference) {
            data = TUIReferenceMessageCellData.getCellData(message)
        }
        return data
    }

    static func parseMessageCellDataFromMessageElement(_ message: V2TIMMessage) -> TUIMessageCellData? {
        var data: TUIMessageCellData? = nil
        switch message.elemType {
        case .ELEM_TYPE_TEXT:
            data = TUITextMessageCellData.getCellData(message)
        case .ELEM_TYPE_IMAGE:
            data = TUIImageMessageCellData.getCellData(message)
        case .ELEM_TYPE_SOUND:
            data = TUIVoiceMessageCellData.getCellData(message)
        case .ELEM_TYPE_VIDEO:
            data = TUIVideoMessageCellData.getCellData(message)
        case .ELEM_TYPE_FILE:
            data = TUIFileMessageCellData.getCellData(message)
        case .ELEM_TYPE_FACE:
            data = TUIFaceMessageCellData.getCellData(message)
        case .ELEM_TYPE_GROUP_TIPS:
            data = getSystemCellData(message)
        case .ELEM_TYPE_MERGER:
            data = TUIMergeMessageCellData.getCellData(message)
        case .ELEM_TYPE_CUSTOM:
            data = getCustomMessageCellData(message)
        default:
            data = getUnsupportedCellData(message)
        }
        return data
    }

    static func fillPropertyToCellData(_ data: TUIMessageCellData, ofMessage message: V2TIMMessage) {
        data.innerMessage = message
        if !message.groupID.isNilOrEmpty && !message.isSelf && !(data is TUISystemMessageCellData) {
            data.showName = true
        }
        switch message.status {
        case .MSG_STATUS_SEND_SUCC:
            data.status = .Msg_Status_Succ
        case .MSG_STATUS_SEND_FAIL:
            data.status = .Msg_Status_Fail
        case .MSG_STATUS_SENDING:
            data.status = .Msg_Status_Sending
        default:
            break
        }

        if !message.msgID.isNilOrEmpty {
            guard let msgID = message.msgID else { return }
            let uploadProgress = TUIMessageProgressManager.shared.uploadProgress(forMessage: msgID)
            let downloadProgress = TUIMessageProgressManager.shared.downloadProgress(forMessage: msgID)
            if let data = data as? TUIMessageCellDataFileUploadProtocol {
                data.uploadProgress = UInt(uploadProgress)
            }
            if let data = data as? TUIMessageCellDataFileDownloadProtocol {
                data.downladProgress = UInt(downloadProgress)
                data.isDownloading = (downloadProgress != 0) && (downloadProgress != 100)
            }
        }

        if message.isContainsCloudCustom(of: .messageReplies) {
            message.doThingsInContainsCloudCustom(of: .messageReplies) { isContains, obj in
                if isContains {
                    if data is TUISystemMessageCellData || data is TUIJoinGroupMessageCellData {
                        data.showMessageModifyReplies = false
                    } else {
                        data.showMessageModifyReplies = true
                    }
                    if let dic = obj as? [String: Any] {
                        let typeStr = TUICloudCustomDataTypeCenter.convertType2String(.messageReplies) ?? ""
                        if let messageReplies = dic[typeStr] as? [String: Any],
                           let repliesArr = messageReplies["replies"] as? [Any]
                        {
                            data.messageModifyReplies = repliesArr
                        }
                    }
                }
            }
        }
    }

    static func getCustomMessageCellData(_ message: V2TIMMessage) -> TUIMessageCellData? {
        var data: TUIMessageCellData? = nil
        var callingInfo: TUIChatCallingInfoProtocol? = nil
        if callingDataProvider.isCallingMessage(message, callingInfo: &callingInfo) {
            if let callingInfo = callingInfo {
                if callingInfo.excludeFromHistory {
                    data = nil
                } else {
                    data = getCallingCellData(callingInfo)
                    if data == nil {
                        data = getUnsupportedCellData(message)
                    }
                }
            } else {
                data = getUnsupportedCellData(message)
            }
            return data
        }

        var businessID: String? = nil
        var excludeFromHistory = false

        if let signalingInfo = V2TIMManager.sharedInstance().getSignallingInfo(message) {
            excludeFromHistory = message.isExcludedFromLastMessage && message.isExcludedFromUnreadCount
            businessID = getSignalingBusinessID(signalingInfo)
        } else {
            excludeFromHistory = false
            businessID = getCustomBusinessID(message)
        }

        if excludeFromHistory {
            return nil
        }

        if let businessID = businessID, !businessID.isEmpty {
            if let gDataSourceClass = gDataSourceClass,
               let cellDataClass = gDataSourceClass.onGetCustomMessageCellDataClass?(businessID: businessID)
            {
                let data = cellDataClass.getCellData(message)
                if data.shouldHide() {
                    return nil
                } else {
                    data.reuseId = businessID
                    return data
                }
            }
            if businessID.contains(BussinessID_CustomerService) {
                return nil
            }
            return getUnsupportedCellData(message)
        } else {
            return getUnsupportedCellData(message)
        }
    }

    static func getUnsupportedCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        let cellData = TUITextMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        cellData.content = TUISwift.timCommonLocalizableString("TUIKitNotSupportThisMessage")
        cellData.reuseId = TTextMessageCell_ReuseId
        return cellData
    }

    static func getSystemCellData(_ message: V2TIMMessage) -> TUISystemMessageCellData? {
        guard let tip = message.groupTipsElem else { return nil }
        var opUserName = ""
        var opUserID = ""
        if let opMember = tip.opMember {
            opUserName = getOpUserName(opMember)
            opUserID = opMember.userID ?? ""
        }
        var userNameList = [String]()
        var userIDList = [String]()
        if let memberList = tip.memberList {
            userNameList = getUserNameList(memberList)
            userIDList = getUserIDList(memberList)
        }
        if tip.type == .GROUP_TIPS_TYPE_JOIN ||
            tip.type == .GROUP_TIPS_TYPE_INVITE ||
            tip.type == .GROUP_TIPS_TYPE_KICKED ||
            tip.type == .GROUP_TIPS_TYPE_GROUP_INFO_CHANGE ||
            tip.type == .GROUP_TIPS_TYPE_QUIT ||
            tip.type == .GROUP_TIPS_TYPE_PINNED_MESSAGE_ADDED ||
            tip.type == .GROUP_TIPS_TYPE_PINNED_MESSAGE_DELETED
        {
            let joinGroupData = TUIJoinGroupMessageCellData(direction: .MsgDirectionIncoming)
            joinGroupData.content = getDisplayString(message) ?? ""
            joinGroupData.opUserName = opUserName
            joinGroupData.opUserID = opUserID
            joinGroupData.userNameList = userNameList
            joinGroupData.userIDList = userIDList
            joinGroupData.reuseId = TJoinGroupMessageCell_ReuseId
            return joinGroupData
        } else {
            let sysdata = TUISystemMessageCellData(direction: .MsgDirectionIncoming)
            sysdata.content = getDisplayString(message) ?? ""
            sysdata.reuseId = TSystemMessageCell_ReuseId
            if !sysdata.content.isEmpty {
                return sysdata
            }
        }
        return nil
    }

    override class func getRevokeCellData(_ message: V2TIMMessage) -> TUISystemMessageCellData? {
        let revoke = TUISystemMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        revoke.reuseId = TSystemMessageCell_ReuseId
        revoke.content = getRevokeDispayString(message)
        revoke.innerMessage = message
        let revokerInfo = message.revokerInfo
        if message.isSelf {
            if message.elemType == .ELEM_TYPE_TEXT && abs(Date().timeIntervalSince(message.timestamp)) < MaxReEditMessageDelay {
                if let revokerInfo = revokerInfo, revokerInfo.userID != message.sender {
                    revoke.supportReEdit = false
                } else {
                    revoke.supportReEdit = true
                }
            }
        } else if !message.groupID.isNilOrEmpty {
            let userName = TUIMessageDataProvider.getShowName(message)
            let joinGroupData = TUIJoinGroupMessageCellData(direction: .MsgDirectionIncoming)
            joinGroupData.content = getRevokeDispayString(message)
            joinGroupData.opUserID = message.sender
            joinGroupData.opUserName = userName
            joinGroupData.reuseId = TJoinGroupMessageCell_ReuseId
            return joinGroupData
        }
        return revoke
    }

    override class func getSystemMsgFromDate(_ date: Date) -> TUIMessageCellData? {
        let system = TUISystemMessageCellData(direction: .MsgDirectionOutgoing)
        system.content = TUITool.convertDate(toStr: date)
        system.reuseId = TSystemMessageCell_ReuseId
        system.type = .date
        return system
    }

    static func asyncGetDisplayString(_ messageList: [V2TIMMessage], callback: (([String: String]) -> Void)?) {
        guard let callback = callback else { return }

        var originDisplayMap = [String: String]()
        var cellDataList = [TUIMessageCellData]()
        for message in messageList {
            if let cellData = convertToCellData(from: message) {
                cellDataList.append(cellData)
            }

            if let displayString = getDisplayString(message), let msgID = message.msgID {
                originDisplayMap[msgID] = displayString
            }
        }

        if cellDataList.isEmpty {
            callback([:])
            return
        }

        let provider = TUIMessageDataProvider()
        let additionUserIDList = provider.getUserIDListForAdditionalUserInfo(cellDataList)
        if additionUserIDList.isEmpty {
            callback([:])
            return
        }

        var result = [String: String]()
        provider.requestForAdditionalUserInfo(cellDataList) {
            for cellData in cellDataList {
                for (key, obj) in cellData.additionalUserInfoResult {
                    let str = "{\(key)}"
                    var showName = obj.userID
                    if !obj.nameCard.isEmpty {
                        showName = obj.nameCard
                    } else if !obj.friendRemark.isEmpty {
                        showName = obj.friendRemark
                    } else if !obj.nickName.isEmpty {
                        showName = obj.nickName
                    }

                    if var displayString = originDisplayMap[cellData.msgID], displayString.contains(str) {
                        displayString = displayString.replacingOccurrences(of: str, with: showName)
                        result[cellData.msgID] = displayString
                    }

                    callback(result)
                }
            }
        }
    }

    override class func getDisplayString(_ message: V2TIMMessage) -> String? {
        let hasRiskContent = message.hasRiskContent
        let isRevoked = (message.status == .MSG_STATUS_LOCAL_REVOKED)
        if hasRiskContent && !isRevoked {
            return TUISwift.timCommonLocalizableString("TUIKitMessageDisplayRiskContent")
        }
        var str = parseDisplayStringFromMessageStatus(message)
        if str == nil {
            str = parseDisplayStringFromMessageElement(message)
        }

        if str == nil {
            print("current message will be ignored in chat page or conversation list page, msg:\(message)")
        }
        return str
    }

    static func parseDisplayStringFromMessageStatus(_ message: V2TIMMessage) -> String? {
        var str: String? = nil
        if message.status == .MSG_STATUS_LOCAL_REVOKED {
            str = getRevokeDispayString(message)
        }
        return str
    }

    static func parseDisplayStringFromMessageElement(_ message: V2TIMMessage) -> String? {
        var str: String? = nil
        switch message.elemType {
        case .ELEM_TYPE_TEXT:
            str = TUITextMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_IMAGE:
            str = TUIImageMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_SOUND:
            str = TUIVoiceMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_VIDEO:
            str = TUIVideoMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_FILE:
            str = TUIFileMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_FACE:
            str = TUIFaceMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_MERGER:
            str = TUIMergeMessageCellData.getDisplayString(message)
        case .ELEM_TYPE_GROUP_TIPS:
            str = getGroupTipsDisplayString(message)
        case .ELEM_TYPE_CUSTOM:
            str = getCustomDisplayString(message)
        default:
            str = TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnsupportCustomMessage")
        }
        return str
    }

    static func getCustomDisplayString(_ message: V2TIMMessage) -> String? {
        var str: String? = nil
        var callingInfo: TUIChatCallingInfoProtocol? = nil
        if callingDataProvider.isCallingMessage(message, callingInfo: &callingInfo) {
            if let callingInfo = callingInfo {
                if callingInfo.excludeFromHistory {
                    str = nil
                } else {
                    let content: String? = callingInfo.content
                    str = content ?? TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnsupportCustomMessage")
                }
            } else {
                str = TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnsupportCustomMessage")
            }
            return str
        }

        var businessID: String? = nil
        var excludeFromHistory = false

        if let signalingInfo = V2TIMManager.sharedInstance().getSignallingInfo(message) {
            excludeFromHistory = message.isExcludedFromLastMessage && message.isExcludedFromUnreadCount
            businessID = getSignalingBusinessID(signalingInfo)
        } else {
            excludeFromHistory = false
            businessID = getCustomBusinessID(message)
        }

        if excludeFromHistory {
            return nil
        }

        if let businessID = businessID, !businessID.isEmpty {
            if let gDataSourceClass = gDataSourceClass,
               let cellDataClass = gDataSourceClass.onGetCustomMessageCellDataClass?(businessID: businessID),
               let data = cellDataClass.getDisplayString(message)
            {
                return data
            }
            if businessID.contains(BussinessID_CustomerService) {
                return nil
            }
            return TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnsupportCustomMessage")
        } else {
            return TUISwift.timCommonLocalizableString("TUIKitMessageTipsUnsupportCustomMessage")
        }
    }

    override func processQuoteMessage(_ uiMsgs: [TUIMessageCellData]) {
        if uiMsgs.isEmpty {
            return
        }

        let concurrentQueue = DispatchQueue.global(qos: .default)
        let group = DispatchGroup()

        concurrentQueue.async(group: group) {
            for cellData in uiMsgs {
                guard let myData = cellData as? TUIReplyMessageCellData else { continue }

                myData.onFinish = {
                    DispatchQueue.main.async {
                        if let index = self.uiMsgs.firstIndex(of: myData) {
                            UIView.performWithoutAnimation {
                                self.dataSource?.dataProviderDataSourceWillChange(self)
                                self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: false)
                                self.dataSource?.dataProviderDataSourceDidChange(self)
                            }
                        }
                    }
                }
                group.enter()
                self.loadOriginMessage(from: myData) {
                    group.leave()
                    DispatchQueue.main.async {
                        if let index = self.uiMsgs.firstIndex(of: myData) {
                            UIView.performWithoutAnimation {
                                self.dataSource?.dataProviderDataSourceWillChange(self)
                                self.dataSource?.dataProvider(self, onRemoveHeightCache: myData)
                                self.dataSource?.dataProviderDataSourceChange(self, withType: .reload, atIndex: UInt(index), animation: false)
                                self.dataSource?.dataProviderDataSourceDidChange(self)
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            // complete
        }
    }

    override func deleteUIMsgs(_ uiMsgArray: [TUIMessageCellData], SuccBlock succ: V2TIMSucc?, FailBlock fail: V2TIMFail?) {
        var uiMsgList = [TUIMessageCellData]()
        var imMsgList = [V2TIMMessage]()
        for uiMsg in uiMsgArray {
            if uiMsgs.contains(uiMsg) {
                uiMsgList.append(uiMsg)
                imMsgList.append(uiMsg.innerMessage)

                var index = uiMsgs.firstIndex(of: uiMsg)!
                index -= 1
                if index >= 0 && index < uiMsgs.count, let systemCellData = uiMsgs[index] as? TUISystemMessageCellData, systemCellData.type == .date {
                    uiMsgList.append(systemCellData)
                }
            }
        }

        if imMsgList.count == 0 {
            fail?(ERR_INVALID_PARAMETERS.rawValue, "not found uiMsgs")
            return
        }

        TUIMessageDataProvider.deleteMessages(imMsgList, succ: {
            self.dataSource?.dataProviderDataSourceWillChange(self)
            for uiMsg in uiMsgList {
                if let index = self.uiMsgs.firstIndex(of: uiMsg) {
                    self.dataSource?.dataProviderDataSourceChange(self, withType: .delete, atIndex: UInt(index), animation: true)
                }
            }
            self.removeUIMsgList(uiMsgList)
            self.dataSource?.dataProviderDataSourceDidChange(self)
            succ?()
        }, fail: fail)
    }

    override func removeUIMsgList(_ cellDatas: [TUIMessageCellData]) {
        for uiMsg in cellDatas {
            removeUIMsg(uiMsg)
        }
    }

    static func getCustomBusinessID(_ message: V2TIMMessage) -> String? {
        guard let customElem = message.customElem else { return nil }
        guard let data = customElem.data else { return nil }
        do {
            if let param = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                if let businessID = param[BussinessID] as? String, !businessID.isEmpty {
                    return businessID
                } else if param.keys.contains(BussinessID_CustomerService), let src = param[BussinessID_Src_CustomerService] as? String, !src.isEmpty {
                    return "\(BussinessID_CustomerService)\(src)"
                }
            }
        } catch {
            print("parse customElem data error: \(error)")
        }
        return nil
    }

    static func getSignalingBusinessID(_ signalInfo: V2TIMSignalingInfo) -> String? {
        guard let data = signalInfo.data else { return nil }
        do {
            if let param = try JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: .allowFragments) as? [String: Any], let businessID = param[BussinessID] as? String {
                return businessID
            }
        } catch {
            print("parse customElem data error: \(error)")
        }
        return nil
    }

    static var gCallingDataProvider: TUIChatCallingDataProvider?
    static var callingDataProvider: TUIChatCallingDataProvider {
        if gCallingDataProvider == nil {
            gCallingDataProvider = TUIChatCallingDataProvider()
        }
        return gCallingDataProvider!
    }

    static func getCallingCellData(_ callingInfo: TUIChatCallingInfoProtocol) -> TUIMessageCellData? {
        let direction: TMsgDirection = callingInfo.direction == TUICallMessageDirection.incoming ? .MsgDirectionIncoming : .MsgDirectionOutgoing

        if callingInfo.participantType == .c2c {
            let cellData = TUITextMessageCellData(direction: direction)
            cellData.isAudioCall = callingInfo.streamMediaType == .voice
            cellData.isVideoCall = callingInfo.streamMediaType == .video
            cellData.content = callingInfo.content
            cellData.isCaller = callingInfo.participantRole == .caller
            cellData.showUnreadPoint = callingInfo.showUnreadPoint
            cellData.isUseMsgReceiverAvatar = callingInfo.isUseReceiverAvatar
            cellData.reuseId = TTextMessageCell_ReuseId
            return cellData
        } else if callingInfo.participantType == .group {
            let cellData = TUISystemMessageCellData(direction: direction)
            cellData.content = callingInfo.content
            cellData.replacedUserIDList = callingInfo.participantIDList
            cellData.reuseId = TSystemMessageCell_ReuseId
            return cellData
        } else {
            return nil
        }
    }
}
