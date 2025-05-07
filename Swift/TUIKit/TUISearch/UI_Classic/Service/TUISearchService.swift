import Foundation
import TIMCommon
import TUICore

public class TUISearchService: NSObject {
    static let sharedInstance = TUISearchService()

    @objc public class func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiSearchThemePath(), themeModule: TUIThemeModule.search)
    }
}
