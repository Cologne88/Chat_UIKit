import Foundation
import TIMCommon
import TUICore

extension Notification.Name {
    static let LoginSuccess = Notification.Name("TUILoginSuccessNotification")
}

public class TUIChatService_Minimalist: NSObject, TUIServiceProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerService("TUICore_TUIChatService_Minimalist", object: shared)
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiBundlePath("TUIChatTheme_Minimalist", key: "TUIChat.TUIChatService"), themeModule: TUIThemeModule.chat_Minimalist)
    }
    
    static let shared: TUIChatService_Minimalist = {
        let instance = TUIChatService_Minimalist()
        return instance
    }()
    
    override private init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessNotification), name: .LoginSuccess, object: nil)
    }
    
    @objc func loginSuccessNotification() {
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableFloatWindowMethod", param: ["TUICore_TUICallingService_EnableFloatWindowMethod_EnableFloatWindow": TUIChatConfig.shared.enableFloatWindowForCall])
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableMultiDeviceAbilityMethod", param: ["TUICore_TUICallingService_EnableMultiDeviceAbilityMethod_EnableMultiDeviceAbility": TUIChatConfig.shared.enableMultiDeviceForCall])
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableIncomingBannerMethod", param: ["TUICore_TUICallingService_EnableIncomingBannerMethod_EnableIncomingBanner": TUIChatConfig.shared.enableIncomingBanner])
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_EnableVirtualBackgroundForCallMethod", param: ["TUICore_TUICallingService_EnableVirtualBackgroundForCallMethod_EnableVirtualBackgroundForCall": TUIChatConfig.shared.enableVirtualBackgroundForCall])
    }
    
    func getDisplayString(_ message: V2TIMMessage?) -> String {
        return TUIBaseMessageController_Minimalist.getDisplayString(message: message ?? V2TIMMessage()) ?? ""
    }
    
    public func asyncGetDisplayString(_ messageList: [V2TIMMessage], callback: TUICallServiceResultCallback?) {
        if let callback {
            TUIBaseMessageController_Minimalist.asyncGetDisplayString(messageList: messageList) { result in
                callback(0, "", result)
            }
        }
    }
    
    // MARK: - TUIServiceProtocol

    @objc public func onCall(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        if method == "TUICore_TUIChatService_GetDisplayStringMethod" {
            return getDisplayString(param?["msg"] as? V2TIMMessage)
        } else if method == "TUICore_TUIChatService_SendMessageMethod" {
            guard let param = param as? NSDictionary else {
                return nil
            }
            
            let message = param.tui_object(forKey: "TUICore_TUIChatService_SendMessageMethod_MsgKey", as: V2TIMMessage.self)
            let cellData = param.tui_object(forKey: "TUICore_TUIChatService_SendMessageMethod_PlaceHolderUIMsgKey", as: TUIMessageCellData.self)
            var userInfo: [String: Any] = [:]
            userInfo["TUICore_TUIChatService_SendMessageMethod_MsgKey"] = message
            userInfo["TUICore_TUIChatService_SendMessageMethod_PlaceHolderUIMsgKey"] = cellData
            NotificationCenter.default.post(name: Notification.Name(TUIChatSendMessageNotification), object: nil, userInfo: userInfo)
            
        } else if method == "TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI" {
            guard let param = param as? NSDictionary else {
                return nil
            }
            
            let message = param.tui_object(forKey: "TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI_MsgKey", as: V2TIMMessage.self)
            let userInfo: [String: Any] = ["TUICore_TUIChatService_SendMessageMethodWithoutUpdateUI_MsgKey": message]
            NotificationCenter.default.post(name: Notification.Name(TUIChatSendMessageWithoutUpdateUINotification), object: nil, userInfo: userInfo)
        } else if method == "TUICore_TUIChatService_SetChatExtensionMethod" {
            param?.forEach { key, value in
                if let key = key as? String, let value = value as? NSNumber {
                    if key == "TUICore_TUIChatService_SetChatExtensionMethod_EnableVideoCallKey" {
                        TUIChatConfig.shared.enableVideoCall = value.boolValue
                    } else if key == "TUICore_TUIChatService_SetChatExtensionMethod_EnableAudioCallKey" {
                        TUIChatConfig.shared.enableAudioCall = value.boolValue
                    } else if key == "TUICore_TUIChatService_SetChatExtensionMethod_EnableLinkKey" {
                        TUIChatConfig.shared.enableWelcomeCustomMessage = value.boolValue
                    }
                }
            }
        } else if method == "TUICore_TUIChatService_AppendCustomMessageMethod" {
            let businessID = param?["businessID"] as? String ?? ""
            let cellName = param?["TMessageCell_Name"] as? String ?? ""
            let cellDataName = param?["TMessageCell_Data_Name"] as? String ?? ""
            TUIMessageCellConfig_Minimalist.registerCustomMessageCell(cellName, messageCellData: cellDataName, forBusinessID: businessID, isPlugin: true)
        }
        
        return nil
    }
    
    public typealias TUICallServiceResultCallback = (Int, String, [AnyHashable: Any]) -> Void
    @objc public func onCall(_ method: String, param: [AnyHashable: Any]?, resultCallback: @escaping TUICallServiceResultCallback) -> Any? {
        if method == "TUICore_TUIChatService_AsyncGetDisplayStringMethod" {
            if let messageList = param?["TUICore_TUIChatService_AsyncGetDisplayStringMethod_MsgListKey"] as? [V2TIMMessage] {
                asyncGetDisplayString(messageList, callback: resultCallback)
            }
        }
        
        return nil
    }
}
