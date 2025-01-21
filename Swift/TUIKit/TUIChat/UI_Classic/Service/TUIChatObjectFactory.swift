import Foundation
import TIMCommon
import TUICore

public class TUIChatObjectFactory: NSObject, TUIObjectProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory(TUICore_TUIChatObjectFactory, objectFactory: shared)
    }

    static let shared: TUIChatObjectFactory = {
        let instance = TUIChatObjectFactory()
        return instance
    }()

    // MARK: - TUIObjectProtocol

    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        guard let param = param as? [String: Any] else { return nil }
        if method == TUICore_TUIChatObjectFactory_ChatViewController_Classic {
            return createChatViewController(param: param)
        } else if method == TUICore_TUIContactObjectFactory_GetGroupInfoVC_Classic {
            let dict = param as NSDictionary
            if let groupID = dict.tui_object(forKey: TUICore_TUIContactObjectFactory_GetGroupInfoVC_GroupID, as: NSString.self) as? String {
                return createGroupInfoController(groupID)
            }
            return nil
        }
        return nil
    }

    // MARK: - Private

    private func createChatViewController(param: [String: Any]) -> UIViewController? {
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
        let isLimitedPortraitOrientationStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Limit_Portrait_Orientation] as? String
        let isEnablePollInfoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_Poll] as? String
        let isEnableGroupNoteInfoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_GroupNote] as? String
        let isEnableWelcomeCustomMessage = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_WelcomeCustomMessage] as? String
        let isEnableTakePhotoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_TakePhoto] as? String
        let isEnableRecordVideoStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_RecordVideo] as? String
        let isEnableFileStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_File] as? String
        let isEnableAlbumStr = param[TUICore_TUIChatObjectFactory_ChatViewController_Enable_Album] as? String
        
        let conversationModel = TUIChatConversationModel()
        conversationModel.title = title
        conversationModel.userID = userID
        conversationModel.groupID = groupID
        conversationModel.conversationID = conversationID
        conversationModel.avatarImage = avatarImage
        conversationModel.faceUrl = avatarUrl
        conversationModel.atTipsStr = atTipsStr
        conversationModel.atMsgSeqs = atMsgSeqs
        conversationModel.draftText = draft
        
        if isEnableVideoInfoStr == "0" {
            conversationModel.enableVideoCall = false
        }
        
        if isEnableAudioInfoStr == "0" {
            conversationModel.enableAudioCall = false
        }
        
        if isEnableRoomInfoStr == "0" {
            conversationModel.enableRoom = false
        }
        
        if isLimitedPortraitOrientationStr == "1" {
            conversationModel.isLimitedPortraitOrientation = true
        }
        
        if isEnableWelcomeCustomMessage == "0" {
            conversationModel.enableWelcomeCustomMessage = false
        }
        
        if isEnablePollInfoStr == "0" {
            conversationModel.enablePoll = false
        }
        
        if isEnableGroupNoteInfoStr == "0" {
            conversationModel.enableGroupNote = false
        }
        
        if isEnableTakePhotoStr == "0" {
            conversationModel.enableTakePhoto = false
        }
        
        if isEnableRecordVideoStr == "0" {
            conversationModel.enableRecordVideo = false
        }
        
        if isEnableFileStr == "0" {
            conversationModel.enableFile = false
        }
        
        if isEnableAlbumStr == "0" {
            conversationModel.enableAlbum = false
        }
        
        var chatVC: TUIBaseChatViewController?
        if let groupID = conversationModel.groupID, !groupID.isEmpty {
            chatVC = TUIGroupChatViewController()
        } else if let userID = conversationModel.userID, !userID.isEmpty {
            chatVC = TUIC2CChatViewController()
        }
        
        chatVC?.conversationData = conversationModel
        chatVC?.title = conversationModel.title
        chatVC?.highlightKeyword = highlightKeyword
        chatVC?.locateMessage = locateMessage
        
        return chatVC
    }
    
    func createGroupInfoController(_ groupID: String) -> UIViewController {
        let vc = TUIGroupInfoController()
        vc.groupId = groupID
        return vc
    }
}
