
import Foundation
import TIMCommon

public class TUIEmojiMeditorProtocolProvider: NSObject, TUIEmojiMeditorProtocol {
    @objc public class func swiftLoad() {
        TIMCommonMediator.share().registerService(TUIEmojiMeditorProtocol.self, class: Self.self)
    }
    
    override public init() {
        super.init()
        TIMCommonMediator.share().registerService(TUIEmojiMeditorProtocol.self, class: type(of: self))
    }
    
    public func getFaceGroup() -> Any {
        return TUIEmojiConfig.shared.faceGroups
    }
    
    public func append(_ faceGroup: TUIFaceGroup) {
        TUIEmojiConfig.shared.appendFaceGroup(faceGroup)
    }
    
    public func getChatPopDetailGroups() -> Any {
        return TUIEmojiConfig.shared.chatPopDetailGroups
    }
    
    public func getChatContextEmojiDetailGroups() -> Any {
        return TUIEmojiConfig.shared.chatContextEmojiDetailGroups
    }
    
    public func getChatPopMenuRecentQueue() -> Any {
        return TUIEmojiConfig.shared.getChatPopMenuRecentQueue() as Any
    }
    
    public func updateRecentMenuQueue(_ faceName: String) {
        TUIEmojiConfig.shared.updateRecentMenuQueue(faceName)
    }
    
    public func updateEmojiGroups() {
        TUIEmojiConfig.shared.updateEmojiGroups()
    }
}
