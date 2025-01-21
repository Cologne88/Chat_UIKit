import Foundation
import TIMCommon
import TUICore

public class TUIChatExtensionObserver: NSObject, TUIExtensionProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerExtension(TUICore_TUIContactExtension_FriendProfileActionMenu_ClassicExtensionID, object: shared)
        TUICore.registerExtension(TUICore_TUIChatExtension_NavigationMoreItem_ClassicExtensionID, object: shared)
    }

    static let shared: TUIChatExtensionObserver = {
        let instance = TUIChatExtensionObserver()
        return instance
    }()

    // MARK: - TUIExtensionProtocol

    public func onGetExtension(_ extensionID: String, param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let param = param as? [String: Any] else { return [] }
        if extensionID == TUICore_TUIContactExtension_FriendProfileActionMenu_ClassicExtensionID {
            return getFriendProfileActionMenuExtensionForClassicContact(param: param)
        } else if extensionID == TUICore_TUIChatExtension_NavigationMoreItem_ClassicExtensionID {
            return getNavigationMoreItemExtensionForClassicChat(param: param)
        } else {
            return nil
        }
    }

    func getFriendProfileActionMenuExtensionForClassicContact(param: [String: Any]) -> [TUIExtensionInfo] {
        let info = TUIExtensionInfo()
        info.weight = 300
        info.text = TUISwift.timCommonLocalizableString("ProfileSendMessages")
        info.onClicked = { actionParam in
            guard let userID = actionParam[TUICore_TUIContactExtension_FriendProfileActionMenu_UserID] as? String,
                  let pushVC = actionParam[TUICore_TUIContactExtension_FriendProfileActionMenu_PushVC] as? UINavigationController
            else {
                return
            }

            let conversationModel = TUIChatConversationModel()
            conversationModel.userID = userID
            conversationModel.conversationID = "c2c_\(userID)"
            let chatVC = TUIC2CChatViewController()
            chatVC.conversationData = conversationModel
            chatVC.title = conversationModel.title

            for vc in pushVC.children {
                if vc.isKind(of: chatVC.classForCoder) {
                    pushVC.popToViewController(vc, animated: true)
                    return
                }
            }

            pushVC.pushViewController(chatVC, animated: true)
        }
        return [info]
    }

    func getNavigationMoreItemExtensionForClassicChat(param: [String: Any]) -> [TUIExtensionInfo]? {
        guard let groupID = param[TUICore_TUIChatExtension_NavigationMoreItem_GroupID] as? String, !groupID.isEmpty else {
            return nil
        }

        let info = TUIExtensionInfo()
        info.icon = TUISwift.tuiChatBundleThemeImage("chat_nav_more_menu_img", defaultImage: "chat_nav_more_menu")
        info.onClicked = { param in
            if let pushVC = param[TUICore_TUIChatExtension_NavigationMoreItem_PushVC] as? UINavigationController {
                let vc = TUIGroupInfoController()
                vc.groupId = groupID
                pushVC.pushViewController(vc, animated: true)
            }
        }
        return [info]
    }
}
