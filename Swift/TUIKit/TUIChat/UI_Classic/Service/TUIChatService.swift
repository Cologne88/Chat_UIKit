// UI_Classic/Service/TUIChatService.swift

import Foundation
import ImSDK_Plus
import TIMCommon
import TUICore

public class TUIChatService: NSObject, TUIServiceProtocol, TUINotificationProtocol, TUIExtensionProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerService("TUICore_TUIChatService", object: shared)
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiChatThemePath(), themeModule: TUIThemeModule.chat)
    }

    static let shared: TUIChatService = {
        let instance = TUIChatService()
        return instance
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessNotification), name: NSNotification.Name("TUILoginSuccessNotification"), object: nil)
    }

    @objc func loginSuccessNotification() {
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableFloatWindowMethod", param: ["TUICore_TUICallingService_EnableFloatWindowMethod_EnableFloatWindow": TUIChatConfig.shared.enableFloatWindowForCall])

        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableMultiDeviceAbilityMethod", param: ["TUICore_TUICallingService_EnableMultiDeviceAbilityMethod_EnableMultiDeviceAbility": TUIChatConfig.shared.enableMultiDeviceForCall])

        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableIncomingBannerMethod", param: ["TUICore_TUICallingService_EnableIncomingBannerMethod_EnableIncomingBanner": TUIChatConfig.shared.enableIncomingBanner])

        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableVirtualBackgroundForCallMethod", param: ["TUICore_TUICallingService_EnableVirtualBackgroundForCallMethod_EnableVirtualBackgroundForCall": TUIChatConfig.shared.enableVirtualBackgroundForCall])
    }

    func getDisplayString(message: V2TIMMessage) -> String {
        return TUIBaseMessageController.getDisplayString(message: message) ?? ""
    }

    func asyncGetDisplayString(_ messageList: [V2TIMMessage], callback: @escaping TUICallServiceResultCallback) {
        TUIBaseMessageController.asyncGetDisplayString(messageList: messageList) { result in
            callback(0, "", result)
        }
    }

    // MARK: - TUIServiceProtocol

    public func onCall(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        guard let param = param as? [String: Any] else { return nil }

        if method == "TUICore_TUIChatService_GetDisplayStringMethod" {
            return getDisplayString(message: param["msg"] as! V2TIMMessage)
        } else if method == "TUICore_TUIChatService_SendMessageMethod" {
            let message = param["TUICore_TUIChatService_SendMessageMethod_MsgKey"] as? V2TIMMessage
            let cellData = param["TUICore_TUIChatService_SendMessageMethod_PlaceHolderUIMsgKey"] as? TUIMessageCellData
            if message == nil && cellData == nil {
                return nil
            }
            var userInfo: [String: Any] = [:]
            if let message = message {
                userInfo["TUICore_TUIChatService_SendMessageMethod_MsgKey"] = message
            }
            if let cellData = cellData {
                userInfo["TUICore_TUIChatService_SendMessageMethod_PlaceHolderUIMsgKey"] = cellData
            }
            NotificationCenter.default.post(name: NSNotification.Name(TUIChatSendMessageNotification), object: nil, userInfo: userInfo)
        } else if method == "TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI" {
            if let message = param["TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI_MsgKey"] as? V2TIMMessage {
                let userInfo = ["TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI_MsgKey": message]
                NotificationCenter.default.post(name: NSNotification.Name(TUIChatSendMessageWithoutUpdateUINotification), object: nil, userInfo: userInfo)
            }
        } else if method == "TUICore_TUIChatService_SetChatExtensionMethod" {
        } else if method == "TUICore_TUIChatService_AppendCustomMessageMethod" {
            if let businessID = param["businessID"] as? String,
               let cellName = param["TMessageCell_Name"] as? String,
               let cellDataName = param["TMessageCell_Data_Name"] as? String
            {
                TUIMessageCellConfig.registerCustomMessageCell(cellName, messageCellData: cellDataName, forBusinessID: businessID, isPlugin: true)
            }

        } else if method == "TUICore_TUIChatService_SetMaxTextSize" {
            if let sizeVa = param["maxsize"] as? CGSize {
                TUIMessageCellConfig.setMaxTextSize(sizeVa)
            }
        }
        return nil
    }

    public func onCall(_ method: String, param: [AnyHashable: Any]?, resultCallback: @escaping TUICallServiceResultCallback) -> Any? {
        if method == "TUICore_TUIChatService_AsyncGetDisplayStringMethod" {
            if let messageList = param?["TUICore_TUIChatService_AsyncGetDisplayStringMethod_MsgListKey"] as? [V2TIMMessage] {
                asyncGetDisplayString(messageList, callback: resultCallback)
            }
            return nil
        }
        return nil
    }
}
