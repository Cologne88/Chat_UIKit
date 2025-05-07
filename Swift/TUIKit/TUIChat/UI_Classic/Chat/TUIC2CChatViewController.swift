import ImSDK_Plus
import TIMCommon
import UIKit

public class TUIC2CChatViewController: TUIBaseChatViewController {
    var sendTypingBaseCondationInVC: Bool = false

    deinit {
        sendTypingBaseCondationInVC = false
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        sendTypingBaseCondationInVC = false

        if let userID = conversationData?.userID {
            let param: [String: Any] = ["TUICore_TUIChatNotify_ChatVC_ViewDidLoadSubKey_UserID": userID]
            TUICore.notifyEvent("TUICore_TUIChatNotify",
                                subKey: "TUICore_TUIChatNotify_ChatVC_ViewDidLoadSubKey",
                                object: nil,
                                param: param)
        }
    }

    // Override Methods

    override func inputControllerDidInputAt(_ inputController: TUIInputController) {
        super.inputControllerDidInputAt(inputController)
        let spaceString = NSAttributedString(string: "@", attributes: [NSAttributedString.Key.font: kTUIInputNormalFont, NSAttributedString.Key.foregroundColor: kTUIInputNormalTextColor])
        inputController.inputBar?.addWordsToInputBar(spaceString)
    }

    override public func forwardTitleWithMyName(_ nameStr: String) -> String {
        let title = String(format: TUISwift.timCommonLocalizableString("TUIKitRelayChatHistoryForSomebodyFormat"), conversationData?.title ?? "", nameStr)
        return rtlString(title)
    }

    override func inputControllerDidBeginTyping(_ inputController: TUIInputController) {
        super.inputControllerDidBeginTyping(inputController)
        sendTypingMsgByStatus(true)
    }

    override func inputControllerDidEndTyping(_ inputController: TUIInputController) {
        super.inputControllerDidEndTyping(inputController)
        sendTypingMsgByStatus(false)
    }

    func sendTypingBaseCondation() -> Bool {
        if sendTypingBaseCondationInVC {
            return true
        }
        let kC2CTypingTime: TimeInterval = 3000.0
        if let vc = messageController as? TUIMessageController, let lastMsg = vc.C2CIncomingLastMsg {
            if let messageFeatureDic = lastMsg.parseCloudCustomData(messageFeature) as? [String: Any], messageFeatureDic.keys.contains("needTyping"), messageFeatureDic.keys.contains("version") {
                let needTyping = messageFeatureDic["needTyping"] as? Int == 1
                let versionControl = messageFeatureDic["version"] as? Int == 1
                let timeControl = floor(Date().timeIntervalSince1970) - floor(lastMsg.timestamp?.timeIntervalSince1970 ?? 0) <= kC2CTypingTime

                if needTyping && versionControl && timeControl {
                    sendTypingBaseCondationInVC = true
                    return true
                }
            }
        }
        return false
    }

    func sendTypingMsgByStatus(_ editing: Bool) {
        guard TUIChatConfig.shared.enableTypingStatus, sendTypingBaseCondation() else {
            return
        }

        let param: [String: Any] = [
            "businessID": "user_typing_status",
            "typingStatus": editing ? 1 : 0,
            "version": 1,
            "userAction": 14,
            "actionParam": editing ? "EIMAMSG_InputStatus_Ing" : "EIMAMSG_InputStatus_End"
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: param, options: []) else {
            return
        }

        let msg = TUIMessageDataProvider.getCustomMessageWithJsonData(data)
        msg.isExcludedFromContentModeration = true
        let appendParams = TUISendMessageAppendParams()
        appendParams.isSendPushInfo = false
        appendParams.isOnlineUserOnly = true
        appendParams.priority = .PRIORITY_DEFAULT

        guard let conversationData = conversationData else { return }
        _ = TUIMessageDataProvider.sendMessage(msg, toConversation: conversationData, appendParams: appendParams, Progress: nil, SuccBlock: nil, FailBlock: nil)
    }
}
