import Foundation
import TIMCommon
import TUICore

public class TUIConversationService_Minimalist: NSObject {
    @objc public class func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiBundlePath("TUIConversationTheme_Minimalist", key: "TUIConversation.TUIConversationService"), themeModule: TUIThemeModule.conversation_Minimalist)
    }

    static let shared: TUIConversationService_Minimalist = {
        let instance = TUIConversationService_Minimalist()
        return instance
    }()

    override private init() {}
}
