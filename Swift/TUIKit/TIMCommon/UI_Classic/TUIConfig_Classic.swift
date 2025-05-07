import Foundation
import TUICore

public class TUIConfig_Classic {
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

    /**
     * Switch the theme of TUIKit.
     * The currently supported themes are "system", "serious", "light", "lively", "dark"
     */
    static func switchTheme(to targetTheme: String) {
        TUIThemeManager.share().applyTheme(targetTheme, for: TUIThemeModule.all)
    }
}
