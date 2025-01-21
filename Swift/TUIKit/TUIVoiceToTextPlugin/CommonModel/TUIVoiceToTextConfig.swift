import Foundation
import TUICore

class TUIVoiceToTextConfig: NSObject {
    static let kVoiceToTextTargetLanguageCode = "voice_to_text_target_language_code"
    
    static let shared: TUIVoiceToTextConfig = {
        let instance = TUIVoiceToTextConfig()
        return instance
    }()
    
    /**
     * 识别目标语言码
     * Recognize target language code.
     */
    var targetLanguageCode: String? {
        didSet {
            guard let targetLanguageCode = targetLanguageCode, !targetLanguageCode.isEmpty else { return }
            if oldValue == targetLanguageCode { return }
            targetLanguageName = languageDict[targetLanguageCode]
            UserDefaults.standard.set(targetLanguageCode, forKey: TUIVoiceToTextConfig.kVoiceToTextTargetLanguageCode)
            UserDefaults.standard.synchronize()
        }
    }
    
    /**
     * 识别目标语言名称。
     * Recognize target language name.
     */
    private(set) var targetLanguageName: String?
    
    override init() {
        super.init()
        loadSavedLanguage()
    }
    
    private func loadSavedLanguage() {
        if let lang = UserDefaults.standard.string(forKey: TUIVoiceToTextConfig.kVoiceToTextTargetLanguageCode), !lang.isEmpty {
            targetLanguageCode = lang
        } else {
            targetLanguageCode = defaultTargetLanguageCode()
            targetLanguageName = languageDict[targetLanguageCode ?? ""]
        }
    }
    
    private func defaultTargetLanguageCode() -> String {
        let currentAppLanguage = TUIGlobalization.getPreferredLanguage()
        if currentAppLanguage == "zh-Hans" || currentAppLanguage == "zh-Hant" {
            return "zh"
        } else {
            return "en"
        }
    }
    
    private var languageDict: [String: String] {
        return [
            "zh": "简体中文",
            "zh-TW": "繁體中文",
            "en": "English",
            "ja": "日本語",
            "ko": "한국어",
            "fr": "Français",
            "es": "Español",
            "it": "Italiano",
            "de": "Deutsch",
            "tr": "Türkçe",
            "ru": "Русский",
            "pt": "Português",
            "vi": "Tiếng Việt",
            "id": "Bahasa Indonesia",
            "th": "ภาษาไทย",
            "ms": "Bahasa Melayu",
            "hi": "हिन्दी"
        ]
    }
}
