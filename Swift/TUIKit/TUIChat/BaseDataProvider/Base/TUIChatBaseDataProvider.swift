import Foundation
import ImSDK_Plus
import TIMCommon

@objc protocol TUIChatBaseDataProviderDelegate: NSObjectProtocol {
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardTitleWithMyName name: String) -> String
    func dataProvider(_ dataProvider: TUIChatBaseDataProvider, mergeForwardMsgAbstactForMessage message: V2TIMMessage) -> String

    @objc optional func dataProvider(_ dataProvider: TUIChatBaseDataProvider, sendMessage message: V2TIMMessage)
    @objc optional func onSelectPhotoMoreCellData()
    @objc optional func onTakePictureMoreCellData()
    @objc optional func onTakeVideoMoreCellData()
    @objc optional func onMultimediaRecordMoreCellData()
    @objc optional func onSelectFileMoreCellData()
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
                    tmpMsgs.append(uiMsg.innerMessage)
                }

                let msgs = tmpMsgs.sorted { (obj1, obj2) -> Bool in
                    if obj1.timestamp.timeIntervalSince1970 == obj2.timestamp.timeIntervalSince1970 {
                        return obj1.seq < obj2.seq
                    } else {
                        return obj1.timestamp.compare(obj2.timestamp) == .orderedAscending
                    }
                }

                if !merge {
                    let forwardMsgs = msgs.compactMap { msg -> V2TIMMessage? in
                        let forwardMessage = V2TIMManager.sharedInstance()?.createForwardMessage(msg)
                        forwardMessage?.isExcludedFromUnreadCount = TUIConfig.default().isExcludedFromUnreadCount
                        forwardMessage?.isExcludedFromLastMessage = TUIConfig.default().isExcludedFromLastMessage
                        return forwardMessage
                    }
                    resultBlock(convCellData, forwardMsgs)
                    return
                }

                let loginUserId = V2TIMManager.sharedInstance()?.getLoginUser() ?? ""
                V2TIMManager.sharedInstance()?.getUsersInfo([loginUserId], succ: { [weak self] infoList in
                    guard let self = self else { return }

                    var myName = loginUserId
                    if let nickName = infoList?.first?.nickName, !nickName.isEmpty {
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
                    guard let mergeMessage = V2TIMManager.sharedInstance()?.createMergerMessage(msgs,
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
        V2TIMManager.sharedInstance()?.getTotalUnreadMessageCount({ totalCount in
            succ(totalCount)
        }, fail: { code, desc in
            fail?(Int(code), desc ?? "")
        })
    }

    class func saveDraft(withConversationID conversationId: String, text: String) {
        let draft = text.trimmingCharacters(in: .whitespacesAndNewlines)
        V2TIMManager.sharedInstance()?.setConversationDraft(conversationId, draftText: draft, succ: nil, fail: nil)
    }

    class func getFriendInfo(withUserId userID: String?, succ: @escaping (V2TIMFriendInfoResult) -> Void, fail: ((Int, String) -> Void)?) {
        guard let userID = userID else {
            fail?(Int(ERR_INVALID_PARAMETERS.rawValue), "userID is nil")
            return
        }

        V2TIMManager.sharedInstance()?.getFriendsInfo([userID], succ: { resultList in
            if let result = resultList?.first {
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

        V2TIMManager.sharedInstance()?.getUsersInfo([userID], succ: { infoList in
            if let info = infoList?.first {
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

        V2TIMManager.sharedInstance()?.getGroupsInfo([groupID], succ: { groupResultList in
            if let result = groupResultList?.first {
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
        V2TIMManager.sharedInstance()?.findMessages(msgIDs, succ: { msgs in
            callback?(true, nil, msgs ?? [])
        }, fail: { _, desc in
            callback?(false, desc, [])
        })
    }
}
