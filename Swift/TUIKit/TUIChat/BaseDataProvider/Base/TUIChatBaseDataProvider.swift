import Foundation
import ImSDK_Plus
import TIMCommon

protocol TUIChatBaseDataProviderDelegate: NSObjectProtocol {
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardTitleWithMyName name: String) -> String
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardMsgAbstactForMessage message: V2TIMMessage) -> String

    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, sendMessage message: V2TIMMessage)
    func onSelectPhotoMoreCellData()
    func onTakePictureMoreCellData()
    func onTakeVideoMoreCellData()
    func onMultimediaRecordMoreCellData()
    func onSelectFileMoreCellData()
}

extension TUIChatBaseDataProviderDelegate {
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardTitleWithMyName name: String) -> String { return "" }
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardMsgAbstactForMessage message: V2TIMMessage) -> String { return "" }

    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, sendMessage message: V2TIMMessage) {}
    func onSelectPhotoMoreCellData() {}
    func onTakePictureMoreCellData() {}
    func onTakeVideoMoreCellData() {}
    func onMultimediaRecordMoreCellData() {}
    func onSelectFileMoreCellData() {}
}

let Input_SendBtn_Key = "Input_SendBtn_Key"
let Input_SendBtn_Title = "Input_SendBtn_Title"
let Input_SendBtn_ImageName = "Input_SendBtn_ImageName"

var gCustomInputBtnInfo: [[String: String]]?

public class TUIChatBaseDataProvider: NSObject {
    weak var delegate: TUIChatBaseDataProviderDelegate?

    @objc public class func swiftLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeLanguage), name: NSNotification.Name(rawValue: TUIChangeLanguageNotification), object: nil)
    }

    @objc class func onChangeLanguage() {
        gCustomInputBtnInfo = nil
    }

    class func customInputBtnInfo() -> [[String: String]] {
        if gCustomInputBtnInfo == nil {
            gCustomInputBtnInfo = [[
                Input_SendBtn_Key: TUIInputMoreCellKey_Link,
                Input_SendBtn_Title: TUISwift.timCommonLocalizableString("TUIKitMoreLink"),
                Input_SendBtn_ImageName: "chat_more_link_img"
            ]]
        }
        return gCustomInputBtnInfo!
    }

    func getForwardMessage(withCellDatas uiMsgs: [TUIMessageCellData], toTargets targets: [TUIChatConversationModel], merge: Bool, resultBlock: @escaping (TUIChatConversationModel, [V2TIMMessage]) -> Void, fail: @escaping V2TIMFail) {
        if uiMsgs.isEmpty {
            fail(Int32(ERR_SVR_PROFILE_INVALID_PARAMETERS.rawValue), "uiMsgs is empty")
            return
        }

        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: targets.count) { index in
                let convCellData = targets[index]
                var tmpMsgs: [V2TIMMessage] = []
                for uiMsg in uiMsgs {
                    if let msg = uiMsg.innerMessage {
                        tmpMsgs.append(msg)
                    }
                }

                let msgs = tmpMsgs.sorted { obj1, obj2 -> Bool in
                    if let t1 = obj1.timestamp, let t2 = obj2.timestamp {
                        if t1.timeIntervalSince1970 == t2.timeIntervalSince1970 {
                            return obj1.seq < obj2.seq
                        } else {
                            return t1.compare(t2) == .orderedAscending
                        }
                    } else {
                        return true
                    }
                }

                if !merge {
                    let forwardMsgs = msgs.compactMap { msg -> V2TIMMessage? in
                        let forwardMessage = V2TIMManager.sharedInstance().createForwardMessage(message: msg)
                        forwardMessage?.isExcludedFromUnreadCount = TUIConfig.default().isExcludedFromUnreadCount
                        forwardMessage?.isExcludedFromLastMessage = TUIConfig.default().isExcludedFromLastMessage
                        return forwardMessage
                    }
                    resultBlock(convCellData, forwardMsgs)
                    return
                }

                let loginUserId = V2TIMManager.sharedInstance().getLoginUser() ?? ""
                V2TIMManager.sharedInstance().getUsersInfo([loginUserId], succ: { [weak self] infoList in
                    guard let self = self, let infoList = infoList else { return }

                    var myName = loginUserId
                    if let nickName = infoList.first?.nickName, !nickName.isEmpty {
                        myName = nickName
                    }

                    let title = self.delegate?.dataProvider(self, mergeForwardTitleWithMyName: myName) ?? ""
                    var abstractList: [String] = []

                    if !msgs.isEmpty {
                        abstractList.append(self.abstractDisplay(withMessage: msgs[0]))
                    }
                    if msgs.count > 1 {
                        abstractList.append(self.abstractDisplay(withMessage: msgs[1]))
                    }
                    if msgs.count > 2 {
                        abstractList.append(self.abstractDisplay(withMessage: msgs[2]))
                    }

                    let compatibleText = TUISwift.timCommonLocalizableString("TUIKitRelayCompatibleText")
                    guard let mergeMessage = V2TIMManager.sharedInstance().createMergerMessage(messageList: msgs,
                                                                                               title: title,
                                                                                               abstractList: abstractList,
                                                                                               compatibleText: compatibleText)
                    else {
                        fail(Int32(ERR_NO_SUCC_RESULT.rawValue), "failed to merge-forward")
                        return
                    }

                    mergeMessage.isExcludedFromUnreadCount = TUIConfig.default().isExcludedFromUnreadCount
                    mergeMessage.isExcludedFromLastMessage = TUIConfig.default().isExcludedFromLastMessage
                    resultBlock(convCellData, [mergeMessage])

                }, fail: fail)
            }
        }
    }

    func abstractDisplay(withMessage msg: V2TIMMessage) -> String {
        return ""
    }
}

extension TUIChatBaseDataProvider {
    class func getTotalUnreadMessageCount(succ: @escaping (UInt64) -> Void, fail: ((Int, String) -> Void)?) {
        V2TIMManager.sharedInstance().getTotalUnreadMessageCount(succ: { totalCount in
            succ(UInt64(totalCount))
        }, fail: { code, desc in
            fail?(Int(code), desc ?? "")
        })
    }

    class func saveDraft(withConversationID conversationId: String, text: String) {
        let draft = text.trimmingCharacters(in: .whitespacesAndNewlines)
        V2TIMManager.sharedInstance().setConversationDraft(conversationID: conversationId, draftText: draft, succ: nil, fail: nil)
    }

    class func getFriendInfo(withUserId userID: String?, succ: @escaping (V2TIMFriendInfoResult) -> Void, fail: ((Int, String) -> Void)?) {
        guard let userID = userID else {
            fail?(Int(ERR_INVALID_PARAMETERS.rawValue), "userID is nil")
            return
        }

        V2TIMManager.sharedInstance().getFriendsInfo([userID], succ: { resultList in
            if let resultList = resultList, let result = resultList.first {
                succ(result)
            }
        }) { _, _ in
            // Handle error
        }
    }

    class func getUserInfo(withUserId userID: String, succ: @escaping (V2TIMUserFullInfo) -> Void, fail: ((Int, String) -> Void)?) {
        guard !userID.isEmpty else {
            fail?(Int(ERR_INVALID_PARAMETERS.rawValue), "userID is nil")
            return
        }

        V2TIMManager.sharedInstance().getUsersInfo([userID], succ: { infoList in
            if let infoList = infoList, let info = infoList.first {
                succ(info)
            }
        }) { _, _ in
            // Handle error
        }
    }

    class func getGroupInfo(withGroupID groupID: String, succ: @escaping (V2TIMGroupInfoResult) -> Void, fail: ((Int, String) -> Void)?) {
        guard !groupID.isEmpty else {
            fail?(Int(ERR_INVALID_PARAMETERS.rawValue), "groupID is nil")
            return
        }

        V2TIMManager.sharedInstance().getGroupsInfo([groupID], succ: { groupResultList in
            if let groupResultList = groupResultList, let result = groupResultList.first {
                if result.resultCode == 0 {
                    succ(result)
                } else {
                    fail?(Int(result.resultCode), result.resultMsg ?? "")
                }
                succ(result)
            }
        }) { _, _ in
            // Handle error
        }
    }

    class func findMessages(_ msgIDs: [String], callback: ((Bool, String?, [V2TIMMessage]) -> Void)?) {
        V2TIMManager.sharedInstance().findMessages(messageIDList: msgIDs, succ: { msgs in
            guard let msgs = msgs else { return }
            callback?(true, nil, msgs)
        }, fail: { _, desc in
            callback?(false, desc, [])
        })
    }

    class func insertLocalTipsMessage(_ content: String, chatID: String, isGroup: Bool) {
        let dic: [String: Any] = [
            "version": 1,
            "businessID": "local_tips",
            "content": content.isEmpty ? "" : content
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted),
              let msg = V2TIMManager.sharedInstance().createCustomMessage(data: data)
        else {
            return
        }

        let senderID = TUILogin.getUserID()

        if isGroup {
            let groupID = chatID.isEmpty ? "" : chatID
            _ = V2TIMManager.sharedInstance().insertGroupMessageToLocalStorage(msg: msg,
                                                                               to: groupID,
                                                                               sender: senderID,
                                                                               succ: {
                                                                                   let userInfo: [String: Any] = [
                                                                                       "message": msg,
                                                                                       "needScrollToBottom": "1"
                                                                                   ]
                                                                                   NotificationCenter.default.post(
                                                                                       name: NSNotification.Name("TUIChatInsertMessageWithoutUpdateUINotification"),
                                                                                       object: nil,
                                                                                       userInfo: userInfo
                                                                                   )
                                                                               },
                                                                               fail: { _, _ in
                                                                               })
        } else {
            let userID = chatID.isEmpty ? "" : chatID
            _ = V2TIMManager.sharedInstance().insertC2CMessageToLocalStorage(msg: msg,
                                                                             to: userID,
                                                                             sender: senderID,
                                                                             succ: {
                                                                                 let userInfo: [String: Any] = [
                                                                                     "message": msg,
                                                                                     "needScrollToBottom": "1"
                                                                                 ]
                                                                                 NotificationCenter.default.post(
                                                                                     name: NSNotification.Name("TUIChatInsertMessageWithoutUpdateUINotification"),
                                                                                     object: nil,
                                                                                     userInfo: userInfo
                                                                                 )
                                                                             },
                                                                             fail: { _, _ in
                                                                             })
        }
    }
}
