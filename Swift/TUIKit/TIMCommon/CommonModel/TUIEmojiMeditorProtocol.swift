import Foundation

public protocol TUIEmojiMeditorProtocol: TIMInitializable {
    func updateEmojiGroups()
    func getFaceGroup() -> [TUIFaceGroup]?
    func appendFaceGroup(_ faceGroup: TUIFaceGroup)
    func getChatPopDetailGroups() -> [TUIFaceGroup]?
    func getChatContextEmojiDetailGroups() -> [TUIFaceGroup]?
    func getChatPopMenuRecentQueue() -> TUIFaceGroup?
    func updateRecentMenuQueue(_ faceName: String)
}

extension TUIEmojiMeditorProtocol {
    func updateEmojiGroups() {}
    func getFaceGroup() -> [TUIFaceGroup]? { return nil }
    func appendFaceGroup(_ faceGroup: TUIFaceGroup) {}
    func getChatPopDetailGroups() -> [TUIFaceGroup]? { return nil }
    func getChatContextEmojiDetailGroups() -> [TUIFaceGroup]? { return nil }
    func getChatPopMenuRecentQueue() -> TUIFaceGroup? { return nil }
    func updateRecentMenuQueue(_ faceName: String) {}
}
