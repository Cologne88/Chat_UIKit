import Foundation

open class TUIRelationUserModel {
    public var userID: String = ""
    public var nickName: String?
    public var faceURL: String?
    public var friendRemark: String?
    public var nameCard: String?

    public init() {}

    open func getDisplayName() -> String {
        return [nameCard, friendRemark, nickName, userID].compactMap { $0?.isEmpty == false ? $0 : nil }.first ?? userID
    }
}
