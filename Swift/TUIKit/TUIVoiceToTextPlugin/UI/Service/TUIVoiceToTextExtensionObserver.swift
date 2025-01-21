// Swift/UI/Service/TUIVoiceToTextExtensionObserver.swift

import Foundation
import TIMCommon
import TUIChat
import TUICore

public class TUIVoiceToTextExtensionObserver: NSObject, TUIExtensionProtocol {
    weak var navVC: UINavigationController?
    weak var cellData: TUICommonTextCellData?
    
    static let shared: TUIVoiceToTextExtensionObserver = {
        let instance = TUIVoiceToTextExtensionObserver()
        return instance
    }()
    
    override init() {
        super.init()
        TUICore.registerExtension(TUICore_TUIChatExtension_BottomContainer_ClassicExtensionID, object: self)
        TUICore.registerExtension(TUICore_TUIChatExtension_BottomContainer_MinimalistExtensionID, object: self)
    }
    
    @objc public static func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiVoiceToTextThemePath(), themeModule: TUIThemeModule.voiceToText)
        
        // UI extensions in pop menu when message is long pressed.
        TUICore.registerExtension(TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID, object: TUIVoiceToTextExtensionObserver.shared)
        
        TUICore.registerExtension(TUICore_TUIChatExtension_PopMenuActionItem_MinimalistExtensionID, object: TUIVoiceToTextExtensionObserver.shared)
    }
    
    // MARK: - TUIExtensionProtocol

    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        guard let data = param?[TUICore_TUIChatExtension_BottomContainer_CellData] as? TUIMessageCellData,
              data.innerMessage.elemType == .ELEM_TYPE_SOUND,
              data.innerMessage.status == .MSG_STATUS_SEND_SUCC
        else {
            return false
        }
        
        var cacheMap = parentView.tui_extValueObj as? [String: Any] ?? [:]
        var cacheView = cacheMap["TUIVoiceToTextView"] as? TUIVoiceToTextView
        
        cacheView?.removeFromSuperview()
        cacheView = nil
        
        let view = TUIVoiceToTextView(data: data)
        parentView.addSubview(view)
        
        cacheMap["TUIVoiceToTextView"] = view
        parentView.tui_extValueObj = cacheMap
        return true
    }
    
    public func onGetExtension(_ extensionID: String, param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let param = param,
              TUIChatConfig.shared.enablePopMenuConvertAction,
              let cell = param[TUICore_TUIChatExtension_PopMenuActionItem_ClickCell] as? TUIMessageCell,
              cell.messageData.innerMessage.elemType == .ELEM_TYPE_SOUND,
              cell.messageData.innerMessage.status == .MSG_STATUS_SEND_SUCC,
              !TUIVoiceToTextDataProvider.shouldShowConvertedText(cell.messageData.innerMessage),
              !cell.messageData.innerMessage.hasRiskContent
        else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.weight = 2000
        info.text = TUISwift.timCommonLocalizableString("TUIKitConvertToText")
        info.icon = TUISwift.tuiChatBundleThemeImage("chat_icon_convert_voice_to_text_img", defaultImage: "icon_convert_voice_to_text")
        
        info.onClicked = { _ in
            guard let cellData = cell.messageData else { return }
            let message = cellData.innerMessage
            guard message.elemType == .ELEM_TYPE_SOUND else { return }
            
            TUIVoiceToTextDataProvider.convertMessage(cellData) { code, _, _, status, text in
                if code != 0 || (text.count == 0 && status == TUIVoiceToTextViewStatus.hidden.rawValue) {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitConvertToTextFailed"))
                }
                let param = [TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data: cellData]
                TUICore.notifyEvent(TUICore_TUIPluginNotify, subKey: TUICore_TUIPluginNotify_DidChangePluginViewSubKey, object: nil, param: param)
            }
        }
        
        return [info]
    }
}
