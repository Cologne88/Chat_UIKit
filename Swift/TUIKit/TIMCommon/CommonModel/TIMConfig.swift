import Foundation

struct EmojiFaceType: OptionSet {
    let rawValue: Int

    static let keyBoard = EmojiFaceType(rawValue: 1 << 0)
    static let popDetail = EmojiFaceType(rawValue: 1 << 1)
}

public class TIMConfig: NSObject {
    @objc public class func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.timCommonThemePath(), themeModule: TUIThemeModule.timCommon)
    }
    
    public static let shared = TIMConfig()
    
    public var faceGroups: [TUIFaceGroup]? {
        let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self)
        return service?.getFaceGroup()
    }
    
    public var chatPopDetailGroups: [TUIFaceGroup]? {
        let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self)
        return service?.getChatPopDetailGroups()
    }
    
    public var enableMessageBubble: Bool = true
    
    override private init() {
        self.enableMessageBubble = true
    }
    
    public static func isClassicEntrance() -> Bool {
        let styleID = getCurrentStyleSelectID()
        return styleID == "Classic"
    }
    
    private static func getCurrentStyleSelectID() -> String {
        let styleID = UserDefaults.standard.string(forKey: "StyleSelectkey")
        if let styleID = styleID, !styleID.isEmpty {
            return styleID
        } else {
            let initStyleID = "Classic"
            UserDefaults.standard.setValue(initStyleID, forKey: "StyleSelectkey")
            UserDefaults.standard.synchronize()
            return initStyleID
        }
    }
}
