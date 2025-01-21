import Foundation
import TIMCommon
import TUICore

enum TUITranslationViewStatus: Int {
    case unknown = 0
    case hidden = 1
    case loading = 2
    case shown = 3
    case securityStrike = 4
}

typealias TUITranslateMessageCompletion = (Int, String, TUIMessageCellData, Int, String) -> Void

class TUITranslationDataProvider: NSObject, TUINotificationProtocol, V2TIMAdvancedMsgListener {
    private static let kKeyTranslationText = "translation"
    private static let kKeyTranslationViewStatus = "translation_view_status"
    
    // MARK: - Public

    static func translateMessage(_ data: TUIMessageCellData, completion: TUITranslateMessageCompletion?) {
        let msg = data.innerMessage
        guard msg.elemType == .ELEM_TYPE_TEXT, let textElem = msg.textElem else {
            return
        }
        
        // Get @ user's nickname by userID.
        var atUserIDs = msg.groupAtUserList as? [String]
        if atUserIDs == nil || atUserIDs?.count == 0 {
            // There's not any @user info.
            translateMessage(data, atUsers: nil, completion: completion)
            return
        }
        
        // Find @All info.
        var atUserIDsExcludingAtAll = [String]()
        let atAllIndex = NSMutableIndexSet()
        for (i, userID) in atUserIDs!.enumerated() {
            if userID != kImSDK_MesssageAtALL {
                // Exclude @All.
                atUserIDsExcludingAtAll.append(userID)
            } else {
                // Record @All's location for later restore.
                atAllIndex.add(i)
            }
        }
        
        // There's only @All info.
        if atUserIDsExcludingAtAll.isEmpty {
            let atAllNames: [String] = Array(repeating: TUISwift.timCommonLocalizableString("All"), count: atAllIndex.count)
            translateMessage(data, atUsers: atAllNames, completion: completion)
            return
        }
        
        V2TIMManager.sharedInstance()?.getUsersInfo(atUserIDsExcludingAtAll, succ: { infoList in
            var atUserNames = [String]()
            for userID in atUserIDsExcludingAtAll {
                if let user = infoList?.first(where: { $0.userID == userID }) {
                    atUserNames.append((user.nickName ?? user.userID) ?? "")
                }
            }
            // Restore @All.
            atAllIndex.enumerate { idx, _ in
                atUserNames.insert(TUISwift.timCommonLocalizableString("All"), at: idx)
            }
            translateMessage(data, atUsers: atUserNames, completion: completion)
        }, fail: { _, _ in
            translateMessage(data, atUsers: atUserIDs, completion: completion)
        })
    }
    
    static func translateMessage(_ data: TUIMessageCellData, atUsers: [String]?, completion: TUITranslateMessageCompletion?) {
        let msg = data.innerMessage
        guard let textElem = msg.textElem else { return }
        
        let target = TUITranslationConfig.shared.targetLanguageCode
        let splitResult = textElem.text?.splitTextByEmojiAnd(atUsers: atUsers)
        let textArray = splitResult?[kSplitStringTextKey] as? [String] ?? []
        
        if textArray.isEmpty {
            // Nothing needs to be translated.
            saveTranslationResult(msg, text: textElem.text ?? "", status: .shown)
            completion?(0, "", data, TUITranslationViewStatus.shown.rawValue, textElem.text ?? "")
            return
        }
        
        let dict = TUITool.jsonData2Dictionary(msg.localCustomData) as? [String: Any]
        let translatedText = dict?[kKeyTranslationText] as? String
        
        if let translatedText = translatedText, !translatedText.isEmpty {
            saveTranslationResult(msg, text: translatedText, status: .shown)
            completion?(0, "", data, TUITranslationViewStatus.shown.rawValue, translatedText)
        } else {
            saveTranslationResult(msg, text: "", status: .loading)
            completion?(0, "", data, TUITranslationViewStatus.loading.rawValue, "")
        }
        
        // Send translate request.
        V2TIMManager.sharedInstance()?.translateText(textArray, sourceLanguage: nil, targetLanguage: target, completion: { code, desc, result in
            if code != 0 || result?.count == 0 {
                if code == 30007 {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TranslateLanguageNotSupport"))
                } else {
                    TUITool.makeToastError(Int(code), msg: desc)
                }
                
                saveTranslationResult(msg, text: "", status: .hidden)
                completion?(Int(code), desc ?? "", data, TUITranslationViewStatus.hidden.rawValue, "")
                return
            }
            
            let text = NSString.replacedString(with: splitResult?[kSplitStringResultKey] as? [String] ?? [],
                                               index: splitResult?[kSplitStringTextIndexKey] as? [Int] ?? [],
                                               replaceDict: result ?? [:])
            saveTranslationResult(msg, text: text, status: .shown)
            completion?(0, "", data, TUITranslationViewStatus.shown.rawValue, text)
        })
    }
    
    static func saveTranslationResult(_ message: V2TIMMessage, text: String, status: TUITranslationViewStatus) {
        if !text.isEmpty {
            saveToLocalCustomData(ofMessage: message, key: kKeyTranslationText, value: text)
        }
        saveToLocalCustomData(ofMessage: message, key: kKeyTranslationViewStatus, value: status.rawValue)
    }
    
    static func saveToLocalCustomData(ofMessage message: V2TIMMessage, key: String, value: Any) {
        guard !key.isEmpty else { return }
        var dict = TUITool.jsonData2Dictionary(message.localCustomData) as? [String: Any] ?? [:]
        dict[key] = value
        message.localCustomData = TUITool.dictionary2JsonData(dict)
    }
    
    static func shouldShowTranslation(_ message: V2TIMMessage) -> Bool {
        guard let localCustomData = message.localCustomData, !localCustomData.isEmpty else { return false }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        let status = dict?[kKeyTranslationViewStatus] as? Int ?? TUITranslationViewStatus.hidden.rawValue
        let hiddenStatus: [Int] = [TUITranslationViewStatus.unknown.rawValue, TUITranslationViewStatus.hidden.rawValue]
        return !hiddenStatus.contains(status) || status == TUITranslationViewStatus.loading.rawValue
    }
    
    static func getTranslationText(_ message: V2TIMMessage) -> String? {
        if message.hasRiskContent {
            return TUISwift.timCommonLocalizableString("TUIKitMessageTypeSecurityStrikeTranslate")
        }
        guard let localCustomData = message.localCustomData, !localCustomData.isEmpty else { return nil }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        return dict?[kKeyTranslationText] as? String
    }
    
    static func getTranslationStatus(_ message: V2TIMMessage) -> TUITranslationViewStatus {
        if message.hasRiskContent {
            return .securityStrike
        }
        guard let localCustomData = message.localCustomData, !localCustomData.isEmpty else { return .unknown }
        let dict = TUITool.jsonData2Dictionary(localCustomData) as? [String: Any]
        let status = dict?[kKeyTranslationViewStatus] as? Int ?? TUITranslationViewStatus.unknown.rawValue
        return TUITranslationViewStatus(rawValue: status) ?? .unknown
    }
}
