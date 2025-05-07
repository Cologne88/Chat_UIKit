import Foundation
import TIMCommon
import TUICore

public class TUIChatExtensionObserver_Minimalist: NSObject, TUIExtensionProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerExtension("TUICore_TUIContactExtension_FriendProfileActionMenu_MinimalistExtensionID", object: shared)
        TUICore.registerExtension("TUICore_TUIContactExtension_GroupInfoCardActionMenu_MinimalistExtensionID", object: shared)
        TUICore.registerExtension("TUICore_TUIChatExtension_NavigationMoreItem_MinimalistExtensionID", object: shared)
    }

    static let shared: TUIChatExtensionObserver_Minimalist = {
        let instance = TUIChatExtensionObserver_Minimalist()
        return instance
    }()

    // MARK: - TUIExtensionProtocol

    public func onGetExtension(_ extensionID: String, param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let param = param as? [String: Any] else { return [] }
        if extensionID == "TUICore_TUIContactExtension_FriendProfileActionMenu_MinimalistExtensionID" {
            return getFriendProfileActionMenuExtensionForMinimalistContact(param: param)
        } else if extensionID == "TUICore_TUIContactExtension_GroupInfoCardActionMenu_MinimalistExtensionID" {
            return getGroupInfoCardActionMenuActionMenuExtensionForMinimalistContact(param: param)
        } else {
            return nil
        }
    }

    func getFriendProfileActionMenuExtensionForMinimalistContact(param: [String: Any]) -> [TUIExtensionInfo] {
        let info = TUIExtensionInfo()
        info.weight = 300
        info.text = TUISwift.timCommonLocalizableString("TUIKitMessage")
        info.icon = TUISwift.tuiDynamicImage("", themeModule: TUIThemeModule.contact_Minimalist, defaultImage: UIImage.safeImage(TUISwift.tuiContactImagePath_Minimalist("contact_info_message")))
        info.onClicked = { actionParam in
            let userID = actionParam["TUICore_TUIContactExtension_FriendProfileActionMenu_UserID"] as? String ?? ""
            let pushVC = actionParam["TUICore_TUIContactExtension_FriendProfileActionMenu_PushVC"] as? UINavigationController
            let icon = actionParam["TUICore_TUIContactExtension_FriendProfileActionMenu_UserIcon"] as? UIImage
            let userName = actionParam["TUICore_TUIContactExtension_FriendProfileActionMenu_UserName"] as? String

            guard userID.count > 0 && pushVC != nil else { return }

            let conversationModel = TUIChatConversationModel()
            conversationModel.title = userName
            conversationModel.userID = userID
            conversationModel.conversationID = "c2c_\(userID)"
            conversationModel.avatarImage = icon
            let chatVC = TUIC2CChatViewController_Minimalist()
            chatVC.conversationData = conversationModel

            for vc in pushVC!.children {
                if vc.isKind(of: chatVC.classForCoder) {
                    pushVC!.popToViewController(vc, animated: true)
                    return
                }
            }

            pushVC!.pushViewController(chatVC, animated: true)
        }
        return [info]
    }

    func getGroupInfoCardActionMenuActionMenuExtensionForMinimalistContact(param: [String: Any]) -> [TUIExtensionInfo] {
        let info = TUIExtensionInfo()
        info.weight = 300
        info.text = TUISwift.timCommonLocalizableString("TUIKitMessage")
        info.icon = TUISwift.tuiDynamicImage("", themeModule: TUIThemeModule.contact_Minimalist, defaultImage: UIImage.safeImage(TUISwift.tuiContactImagePath_Minimalist("contact_info_message")))
        info.onClicked = { actionParam in
            guard let groupID = actionParam["TUICore_TUIContactExtension_GroupInfoCardActionMenu_GroupID"] as? String,
                  let pushVC = actionParam["TUICore_TUIContactExtension_GroupInfoCardActionMenu_PushVC"] as? UINavigationController
            else {
                return
            }

            let conversationModel = TUIChatConversationModel()
            conversationModel.groupID = groupID
            conversationModel.conversationID = "group_\(groupID)"
            let chatVC = TUIGroupChatViewController_Minimalist()
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
}
