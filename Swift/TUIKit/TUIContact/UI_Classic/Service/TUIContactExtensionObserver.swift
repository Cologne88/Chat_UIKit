import Foundation
import TIMCommon
import TUICore
import UIKit

public class TUIContactExtensionObserver: NSObject, TUIExtensionProtocol {
    // MARK: - Properties

    private var tag: Int = 0
    private var pushVC: UINavigationController?
    private var groupId: String?
    private var showContactSelectVC: UIViewController?
    private var membersData: [TUIGroupMemberCellData] = []
    private var groupMembersCellData: TUIGroupMembersCellData?
    
    @objc public class func swiftLoad() {
        TUICore.registerExtension(TUICore_TUIChatExtension_NavigationMoreItem_ClassicExtensionID, object: self.shared)
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileMemberListExtension_ClassicExtensionID, object: self.shared)
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileSettingsItemExtension_ClassicExtensionID, object: self.shared)
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileBottomItemExtension_ClassicExtensionID, object: self.shared)
    }
    
    // MARK: - Singleton
    
    static let shared: TUIContactExtensionObserver = {
        let instance = TUIContactExtensionObserver()
        return instance
    }()
    
    // MARK: - TUIExtensionProtocol

    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        guard let param = param else { return false }
        
        if extensionID == TUICore_TUIChatExtension_GroupProfileMemberListExtension_ClassicExtensionID {
            guard let data = param["data"] as? TUIGroupMembersCellData else { return false }
            
            if let groupID = param["groupID"] as? String {
                self.groupId = groupID
            }
            if let pushVC = param["pushVC"] as? UINavigationController {
                self.pushVC = pushVC
            }
            if let membersData = param["membersData"] as? [TUIGroupMemberCellData] {
                self.membersData = membersData
            }
            if let groupMembersCellData = param["groupMembersCellData"] as? TUIGroupMembersCellData {
                self.groupMembersCellData = groupMembersCellData
            }
            
            let cell = TUIGroupMembersCell(style: .default, reuseIdentifier: nil)
            parentView.addSubview(cell)
            parentView.isUserInteractionEnabled = true
            cell.snp.makeConstraints { make in
                make.edges.equalTo(parentView)
            }
            cell.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_menu_bg_color", defaultColor: "#FFFFFF")
            cell.data = data
            cell.delegate = self
            return true
        }
        return false
    }
    
    public func onGetExtension(_ extensionID: String, param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        if extensionID.isEmpty {
            return nil
        }
        
        if extensionID == TUICore_TUIChatExtension_NavigationMoreItem_ClassicExtensionID {
            return self.getNavigationMoreItemExtensionForClassicChat(param: param)
        } else if extensionID == TUICore_TUIChatExtension_GroupProfileSettingsItemExtension_ClassicExtensionID {
            return self.getGroupProfileSettingsItemExtensionForClassicChat(param: param)
        } else if extensionID == TUICore_TUIChatExtension_GroupProfileBottomItemExtension_ClassicExtensionID {
            return self.getGroupProfileBottomItemExtensionForClassicChat(param: param)
        } else {
            return nil
        }
    }
    
    private func getNavigationMoreItemExtensionForClassicChat(param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let userID = param?[TUICore_TUIChatExtension_NavigationMoreItem_UserID] as? String, !userID.isEmpty else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.icon = TUISwift.tuiChatBundleThemeImage("chat_nav_more_menu_img", defaultImage: "chat_nav_more_menu")
        info.weight = 100
        info.onClicked = { param in
            guard let pushVC = param[TUICore_TUIChatExtension_NavigationMoreItem_PushVC] as? UINavigationController else { return }
            let param: [String: Any] = [
                TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey: userID,
                TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey: { (vc: UIViewController) in
                    pushVC.pushViewController(vc, animated: true)
                },
                TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey: { (_: Int, _: String) in }
            ]
            TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod, param: param)
        }
        return [info]
    }
    
    private func getGroupProfileSettingsItemExtensionForClassicChat(param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let groupID = param?["groupID"] as? String, !groupID.isEmpty,
              let pushVC = param?["pushVC"] as? UINavigationController
        else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.icon = nil
        info.weight = 100
        info.text = TUISwift.timCommonLocalizableString("TUIKitGroupProfileManage")
        info.onClicked = { _ in
            let vc = TUIGroupManageController()
            vc.groupID = groupID
            pushVC.pushViewController(vc, animated: true)
        }
        return [info]
    }
    
    private func getGroupProfileBottomItemExtensionForClassicChat(param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let groupID = param?["groupID"] as? String, !groupID.isEmpty,
              let updateGroupInfoCallback = param?["updateGroupInfoCallback"] as? () -> Void,
              let pushVC = param?["pushVC"] as? UINavigationController
        else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.icon = nil
        info.weight = 100
        info.text = TUISwift.timCommonLocalizableString("TUIKitGroupTransferOwner")
        info.onClicked = { _ in
            let vc = TUISelectGroupMemberViewController()
            vc.optionalStyle = .transferOwner
            vc.groupId = groupID
            vc.name = TUISwift.timCommonLocalizableString("TUIKitGroupTransferOwner")
            vc.selectedFinished = { (modelList: [TUIUserModel]) in
                guard let userModel = modelList.first else { return }
                let member = userModel.userId
                self.transferGroupOwner(groupID: groupID, member: member, succ: {
                    updateGroupInfoCallback()
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitGroupTransferOwnerSuccess"))
                }, fail: { code, desc in
                    TUITool.makeToastError(code, msg: desc)
                })
            }
            pushVC.pushViewController(vc, animated: true)
        }
        return [info]
    }
    
    private func transferGroupOwner(groupID: String, member: String, succ: @escaping () -> Void, fail: @escaping (Int, String) -> Void) {
        V2TIMManager.sharedInstance().transferGroupOwner(groupID, member: member, succ: {
            succ()
        }, fail: { code, desc in
            fail(Int(code), desc ?? "")
        })
    }
}

// MARK: - TUIGroupMembersCellDelegate

extension TUIContactExtensionObserver: TUIGroupMembersCellDelegate {
    func groupMembersCell(_ cell: TUIGroupMembersCell, didSelectItemAtIndex index: Int) {
        guard let mem = groupMembersCellData?.members[index] else { return }
        var ids: [String] = []
        var displayNames: [String: String] = [:]
        
        for cd in self.membersData {
            if cd.identifier != V2TIMManager.sharedInstance().getLoginUser() {
                ids.append(cd.identifier)
                displayNames[cd.identifier] = cd.name
            }
        }
        
        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { array in
            if self.tag == 1 {
                let list = array.map { $0.identifier }
                self.pushVC?.popViewController(animated: true)
                self.addGroupId(groupId: self.groupId, members: list)
            } else if self.tag == 2 {
                let list = array.map { $0.identifier }
                self.pushVC?.popViewController(animated: true)
                self.deleteGroupId(groupId: self.groupId, members: list)
            }
        }
        
        self.tag = (mem as AnyObject).tag
        if self.tag == 1 {
            var param: [String: Any] = [:]
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] = TUISwift.timCommonLocalizableString("GroupAddFriend")
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey] = ids
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] = selectContactCompletion
            if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: param) as? UIViewController {
                self.showContactSelectVC = vc
                self.pushVC?.pushViewController(self.showContactSelectVC!, animated: true)
            }
        } else if self.tag == 2 {
            var param: [String: Any] = [:]
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] = TUISwift.timCommonLocalizableString("GroupDeleteFriend")
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_SourceIdsKey] = ids
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames
            param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] = selectContactCompletion
            if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: param) as? UIViewController {
                self.showContactSelectVC = vc
                self.pushVC?.pushViewController(self.showContactSelectVC!, animated: true)
            }
        } else {
            if let member = mem as? TUIGroupMemberCellData {
                self.didCurrentMemberAtCellData(mem: member)
            }
        }
    }
    
    private func didCurrentMemberAtCellData(mem: TUIGroupMemberCellData) {
        let userID = mem.identifier
        self.getUserOrFriendProfileVCWithUserID(userID: userID, succBlock: { vc in
            self.pushVC?.pushViewController(vc, animated: true)
        }, failBlock: { _, _ in })
    }
    
    private func getUserOrFriendProfileVCWithUserID(userID: String, succBlock: @escaping (UIViewController) -> Void, failBlock: @escaping (Int, String) -> Void) {
        let param: [String: Any] = [
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey: userID,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey: succBlock,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey: failBlock
        ]
        TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod, param: param)
    }
    
    private func addGroupId(groupId: String?, members: [String]) {
        guard let groupId = groupId else { return }
        V2TIMManager.sharedInstance().inviteUser(toGroup: groupId, userList: members, succ: { _ in
            TUITool.makeToast(TUISwift.timCommonLocalizableString("add_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }
    
    private func deleteGroupId(groupId: String?, members: [String]) {
        guard let groupId = groupId else { return }
        V2TIMManager.sharedInstance().kickGroupMember(groupId, memberList: members, reason: "", succ: { _ in
            TUITool.makeToast(TUISwift.timCommonLocalizableString("delete_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }
}
