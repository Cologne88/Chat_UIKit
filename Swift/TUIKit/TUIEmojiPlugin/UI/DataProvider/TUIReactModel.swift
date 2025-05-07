import TIMCommon
import UIKit

class TUIReactUserModel: TUIRelationUserModel {
    override func getDisplayName() -> String {
        return [nameCard, friendRemark, nickName, userID].compactMap { $0?.isEmpty == false ? $0 : nil }.first ?? userID
    }
}

public class TUIReactModel: NSObject {
    /**
     * Label name
     */
    var name: String = ""
    
    /**
     * Label alias
     */
    var alias: String = ""
    
    /**
     * The color of label displaying name
     */
    var textColor: UIColor = .init()
    
    var isSelect: Bool = false
    
    var defaultColor: UIColor = .init()
    
    var selectColor: UIColor = .init()
    
    var emojiKey: String = ""
    
    lazy var followIDs: [String] = .init()
    
    lazy var followUserNames: [String] = .init()
    
    lazy var followUserModels: [TUIReactUserModel] = .init()
    
    var maxWidth: Double = 0.0
    var emojiPath: String = ""
    var totalUserCount: Int = 0
    var reactedByMyself: Bool = false
    
    func descriptionFollowUserStr() -> String {
        if followUserNames.isEmpty {
            return ""
        }
        let str = followUserNames.joined(separator: ",")
        return str
    }
    
    class func createTagsModelByReaction(_ reaction: V2TIMMessageReaction) -> TUIReactModel {
        let totalUserCount = reaction.totalUserCount
        
        let model = TUIReactModel()
        model.defaultColor = TUISwift.timCommonDynamicColor("", defaultColor: "#444444").withAlphaComponent(0.1)
        model.textColor = TUISwift.timCommonDynamicColor("chat_react_desc_color", defaultColor: "#888888")
        if let reactionID = reaction.reactionID {
            model.emojiKey = reactionID
            model.emojiPath = reactionID.getEmojiImagePath() ?? ""
        }
        model.reactedByMyself = reaction.reactedByMyself
        model.totalUserCount = Int(totalUserCount)
        
        if let partialUserList = reaction.partialUserList {
            for obj in partialUserList {
                let userModel = TUIReactUserModel()
                userModel.userID = obj.userID ?? ""
                userModel.nickName = obj.nickName
                userModel.faceURL = obj.faceURL
                let userID = userModel.userID
                if !userID.isEmpty {
                    model.followIDs.append(userID)
                }
                let name = userModel.getDisplayName()
                if !name.isEmpty {
                    model.followUserNames.append(name)
                }
                model.followUserModels.append(userModel)
            }
        }

        return model
    }
}
