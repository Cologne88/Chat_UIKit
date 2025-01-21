// Swift/UI/DataProvider/TUIVoiceToTextDataProvider.swift

import Foundation
import TIMCommon
import TUICore

enum TUIVoiceToTextViewStatus: Int {
    case unknown = 0
    case hidden = 1
    case loading = 2
    case shown = 3
    case securityStrike = 4
}

typealias TUIVoiceToTextCompletion = (Int, String, TUIMessageCellData, Int, String) -> Void

class TUIVoiceToTextDataProvider: NSObject, TUINotificationProtocol, V2TIMAdvancedMsgListener {
    static let kKeyVoiceToText = "voice_to_text"
    static let kKeyVoiceToTextViewStatus = "voice_to_text_view_status"
    
    // MARK: - Public

    static func convertMessage(_ data: TUIMessageCellData, completion: TUIVoiceToTextCompletion?) {
        let msg = data.innerMessage
        guard msg.elemType == .ELEM_TYPE_SOUND else {
            completion?(-1, "element is not sound type", data, TUIVoiceToTextViewStatus.hidden.rawValue, "")
            return
        }
        
        guard msg.status == .MSG_STATUS_SEND_SUCC else {
            completion?(-2, "sound message is not sent successfully", data, TUIVoiceToTextViewStatus.hidden.rawValue, "")
            return
        }
        
        guard let soundElem = msg.soundElem else {
            completion?(-3, "soundElem is nil", data, TUIVoiceToTextViewStatus.hidden.rawValue, "")
            return
        }
        
        // Loading converted text from localCustomData firstly.
        if let convertedText = getConvertedText(msg), convertedText.count > 0 {
            saveConvertedResult(msg, text: convertedText, status: .shown)
            completion?(0, "", data, TUIVoiceToTextViewStatus.shown.rawValue, convertedText)
            return
        }
        
        // Try to request from server secondly.
        saveConvertedResult(msg, text: "", status: .loading)
        completion?(0, "", data, TUIVoiceToTextViewStatus.loading.rawValue, "")
        
        soundElem.convertVoice(toText: "") { code, desc, result in
            let status: TUIVoiceToTextViewStatus
            if let result = result, result.count > 0 && code == 0 {
                status = TUIVoiceToTextViewStatus.shown
            } else {
                status = TUIVoiceToTextViewStatus.hidden
            }
            saveConvertedResult(msg, text: result ?? "", status: status)
            completion?(Int(code), desc ?? "", data, status.rawValue, result ?? "")
        }
    }
    
    static func saveConvertedResult(_ message: V2TIMMessage, text: String, status: TUIVoiceToTextViewStatus) {
        if text.count > 0 {
            saveToLocalCustomDataOfMessage(message, key: kKeyVoiceToText, value: text)
        }
        saveToLocalCustomDataOfMessage(message, key: kKeyVoiceToTextViewStatus, value: status.rawValue)
    }
    
    static func saveToLocalCustomDataOfMessage(_ message: V2TIMMessage, key: String, value: Any) {
        guard key.count > 0 else { return }
        var dict = (TUITool.jsonData2Dictionary(message.localCustomData) as? [String: Any]) ?? [:]
        dict[key] = value
        message.localCustomData = TUITool.dictionary2JsonData(dict)
    }
    
    static func shouldShowConvertedText(_ message: V2TIMMessage) -> Bool {
        guard let localCustomData = message.localCustomData, localCustomData.count > 0 else { return false }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        let status = dict?[kKeyVoiceToTextViewStatus] as? Int ?? TUIVoiceToTextViewStatus.hidden.rawValue
        let hiddenStatus: [Int] = [TUIVoiceToTextViewStatus.unknown.rawValue, TUIVoiceToTextViewStatus.hidden.rawValue]
        return !hiddenStatus.contains(status) || status == TUIVoiceToTextViewStatus.loading.rawValue
    }
    
    static func getConvertedText(_ message: V2TIMMessage) -> String? {
        if message.hasRiskContent {
            return TUISwift.timCommonLocalizableString("TUIKitMessageTypeSecurityStrikeTranslate")
        }
        guard let localCustomData = message.localCustomData, localCustomData.count > 0 else { return nil }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        return dict?[kKeyVoiceToText] as? String
    }
    
    static func getConvertedTextStatus(_ message: V2TIMMessage) -> TUIVoiceToTextViewStatus {
        if message.hasRiskContent {
            return .securityStrike
        }
        guard let localCustomData = message.localCustomData, localCustomData.count > 0 else { return .unknown }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        let status = dict?[kKeyVoiceToTextViewStatus] as? Int ?? TUIVoiceToTextViewStatus.unknown.rawValue
        return TUIVoiceToTextViewStatus(rawValue: status) ?? .unknown
    }
}
