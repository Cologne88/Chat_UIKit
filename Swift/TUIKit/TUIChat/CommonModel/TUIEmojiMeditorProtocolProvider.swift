
import Foundation
import TIMCommon

public class TUIEmojiMeditorProtocolProvider: NSObject, TUIEmojiMeditorProtocol {
    @objc public class func swiftLoad() {
        TIMCommonMediator.shared.registerService(TUIEmojiMeditorProtocol.self, class: TUIEmojiMeditorProtocolProvider.self)
    }
    
    override public required init() {
        super.init()
    }
    
    // MARK: - TUIEmojiMeditorProtocol

    public func updateEmojiGroups() {
        TUIEmojiConfig.shared.updateEmojiGroups()
    }
    
    public func getFaceGroup() -> [TIMCommon.TUIFaceGroup]? {
        return TUIEmojiConfig.shared.faceGroups
    }
    
    public func appendFaceGroup(_ faceGroup: TIMCommon.TUIFaceGroup) {
        TUIEmojiConfig.shared.appendFaceGroup(faceGroup)
    }
    
    public func getChatPopDetailGroups() -> [TIMCommon.TUIFaceGroup]? {
        return TUIEmojiConfig.shared.chatPopDetailGroups
    }
    
    public func getChatContextEmojiDetailGroups() -> [TIMCommon.TUIFaceGroup]? {
        return TUIEmojiConfig.shared.chatContextEmojiDetailGroups
    }
    
    public func getChatPopMenuRecentQueue() -> TIMCommon.TUIFaceGroup? {
        if let queue = TUIEmojiConfig.shared.getChatPopMenuRecentQueue() {
            return queue
        }
        return nil
    }
    
    public func updateRecentMenuQueue(_ faceName: String) {
        TUIEmojiConfig.shared.updateRecentMenuQueue(faceName)
    }
}
