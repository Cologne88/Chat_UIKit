import Foundation
import TIMCommon
import TUICore

public class TUIChatObjectFactory_Minimalist: NSObject, TUIObjectProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory(TUICore_TUIChatObjectFactory_Minimalist, objectFactory: shared)
    }
    
    static let shared: TUIChatObjectFactory_Minimalist = {
        let instance = TUIChatObjectFactory_Minimalist()
        return instance
    }()
    
    // MARK: - TUIObjectProtocol

    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        guard let param = param as? [String: Any] else { return nil }
        if method == TUICore_TUIChatObjectFactory_ChatViewController_Minimalist {
            return createChatViewController(param: param)
        } else if method == TUICore_TUIContactObjectFactory_GetGroupInfoVC_Minimalist {
            let dict = param as NSDictionary
            if let groupID = dict.tui_object(forKey: TUICore_TUIContactObjectFactory_GetGroupInfoVC_GroupID, as: NSString.self) as? String {
                return createGroupInfoController(groupID)
            }
            return nil
        }
        return nil
    }

    private func createChatViewController(param: [String: Any]?) -> UIViewController? {
        guard let param = param else { return nil }
        
        let title = param[TUICore_TUIChatObjectFactory_ChatViewController_Title] as? String
        let userID = param[TUICore_TUIChatObjectFactory_ChatViewController_UserID] as? String
        let groupID = param[TUICore_TUIChatObjectFactory_ChatViewController_GroupID] as? String
        let conversationID = param[TUICore_TUIChatObjectFactory_ChatViewController_ConversationID] as? String
        let avatarImage = param[TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage] as? UIImage
        let avatarUrl = param[TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl] as? String
        let highlightKeyword = param[TUICore_TUIChatObjectFactory_ChatViewController_HighlightKeyword] as? String
        let locateMessage = param[TUICore_TUIChatObjectFactory_ChatViewController_LocateMessage] as? V2TIMMessage
        let atTipsStr = param[TUICore_TUIChatObjectFactory_ChatViewController_AtTipsStr] as? String
        let atMsgSeqs = param[TUICore_TUIChatObjectFactory_ChatViewController_AtMsgSeqs] as? [Int]
        let draft = param[TUICore_TUIChatObjectFactory_ChatViewController_Draft] as? String
        let isEnableVideoInfoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_Video_Call] as? String
        let isEnableAudioInfoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_Audio_Call] as? String
        let isEnableRoomInfoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_Room] as? String
        
        let conversationModel = TUIChatConversationModel()
        conversationModel.title = title ?? ""
        conversationModel.userID = userID ?? ""
        conversationModel.groupID = groupID ?? ""
        conversationModel.conversationID = conversationID ?? ""
        conversationModel.avatarImage = avatarImage ?? UIImage()
        conversationModel.faceUrl = avatarUrl ?? ""
        conversationModel.atTipsStr = atTipsStr ?? ""
        conversationModel.atMsgSeqs = atMsgSeqs
        conversationModel.draftText = draft ?? ""
        
        if isEnableVideoInfoStr == "0" {
            conversationModel.enableVideoCall = false
        }
        
        if isEnableAudioInfoStr == "0" {
            conversationModel.enableAudioCall = false
        }
        if isEnableRoomInfoStr == "0" {
            conversationModel.enableRoom = false
        }
        
        var chatVC: TUIBaseChatViewController_Minimalist?
        if let groupID = groupID, !groupID.isEmpty {
            chatVC = TUIGroupChatViewController_Minimalist()
        } else if let userID = userID, !userID.isEmpty {
            chatVC = TUIC2CChatViewController_Minimalist()
        }
        chatVC?.conversationData = conversationModel
        chatVC?.highlightKeyword = highlightKeyword
        chatVC?.locateMessage = locateMessage
        return chatVC
    }
    
    func createGroupInfoController(_ groupID: String) -> UIViewController {
        let vc = TUIGroupInfoController_Minimalist()
        vc.groupId = groupID
        return vc
    }
}
