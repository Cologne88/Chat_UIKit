import Foundation
import TIMCommon
import TUICore

public class TUISearchService_Minimalist: NSObject {
    static let sharedInstance = TUISearchService_Minimalist()

    @objc public class func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiBundlePath("TUISearchTheme_Minimalist", key: "TUISearch.TUISearchService"), themeModule: TUIThemeModule.search_Minimalist)
    }
}
