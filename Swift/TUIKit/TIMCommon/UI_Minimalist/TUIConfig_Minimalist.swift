import Foundation

public class TUIConfig_Minimalist {
    /**
     * Show the toast prompt built in TUIKit.
     * The default value is YES.
     */
    static func enableToast(_ enable: Bool) {
        TUIConfig.default().enableToast = enable
    }

    /**
     * Switch the language of TUIKit.
     * The currently supported languages are "en", "zh-Hans", and "ar".
     */
    static func switchLanguage(to targetLanguage: String) {
        TUIGlobalization.setPreferredLanguage(targetLanguage)
    }
}
