//  TUIContactExtensionObserver_Minimalist.swift
//  TUIContact

import Foundation
import UIKit
import TIMCommon

public class TUIContactExtensionObserver_Minimalist: NSObject, TUIExtensionProtocol, TUINotificationProtocol {
    
    var tag: Int = 0
    var pushVC: UINavigationController?
    var groupId: String?
    var showContactSelectVC: UIViewController?
    var membersData: [TUIGroupMemberCellData_Minimalist] = []
    
    @objc public class func swiftLoad() {
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileMemberListExtension_MinimalistExtensionID, object: sharedInstance)
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileSettingsItemExtension_MinimalistExtensionID, object: sharedInstance)
        TUICore.registerExtension(TUICore_TUIChatExtension_GroupProfileBottomItemExtension_MinimalistExtensionID, object: sharedInstance)
    }
    
    static let sharedInstance: TUIContactExtensionObserver_Minimalist = {
        let instance = TUIContactExtensionObserver_Minimalist()
        return instance
    }()
    
    override init() {
        super.init()
        configNotify()
    }
    
    func configNotify() {
        TUICore.registerEvent(TUICore_TUIContactNotify, subKey: TUICore_TUIContactNotify_OnAddMemebersClickSubKey, object: self)
    }
    
    // MARK: - TUINotificationProtocol
    public func onNotifyEvent(_ key: String, subKey: String, object: Any?, param: [AnyHashable: Any]?) {
        if key == TUICore_TUIContactNotify && subKey == TUICore_TUIContactNotify_OnAddMemebersClickSubKey {
            didAddMemebers()
        }
    }
    
    // MARK: - TUIExtensionProtocol
    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        if extensionID == TUICore_TUIChatExtension_GroupProfileMemberListExtension_MinimalistExtensionID {
            guard let data = param?["data"] as? TUIGroupMemberCellData_Minimalist,
                  let groupID = param?["groupID"] as? String,
                  let pushVC = param?["pushVC"] as? UINavigationController,
                  let membersData = param?["membersData"] as? [TUIGroupMemberCellData_Minimalist] else {
                return false
            }
            
            self.groupId = groupID
            self.pushVC = pushVC
            self.membersData = membersData
            
            let cell = TUIGroupMemberTableViewCell_Minimalist(style: .default, reuseIdentifier: nil)
            parentView.addSubview(cell)
            parentView.isUserInteractionEnabled = true
            cell.snp.makeConstraints { make in
                make.edges.equalTo(parentView)
            }
            cell.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_menu_bg_color", defaultColor: "#FFFFFF")
            cell.fill(with: data)
            cell.tapAction = {
                self.didCurrentMemberAtCell(data)
            }
            return true
        }
        return false
    }
    
    public func onGetExtension(_ extensionID: String, param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        if extensionID.isEmpty {
            return nil
        }
        if extensionID == TUICore_TUIChatExtension_GroupProfileSettingsItemExtension_MinimalistExtensionID {
            return getGroupProfileSettingsItemExtensionForMinimalistChat(param)
        } else if extensionID == TUICore_TUIChatExtension_GroupProfileBottomItemExtension_MinimalistExtensionID {
            return getGroupProfileBottomItemExtensionForMinimalist(param)
        } else {
            return nil
        }
    }
    
    func getGroupProfileSettingsItemExtensionForMinimalistChat(_ param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let param = param as? [String: Any],
              let groupID = param["groupID"] as? String, !groupID.isEmpty,
              let pushVC = param["pushVC"] as? UINavigationController else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.icon = nil
        info.weight = 100
        info.text = TUISwift.timCommonLocalizableString("TUIKitGroupProfileManage")
        info.onClicked = { clickParam in
            let vc = TUIGroupManageController_Minimalist()
            vc.groupID = groupID
            pushVC.pushViewController(vc, animated: true)
        }
        return [info]
    }
    
    func getGroupProfileBottomItemExtensionForMinimalist(_ param: [AnyHashable: Any]?) -> [TUIExtensionInfo]? {
        guard let param = param as? [String: Any],
              let groupID = param["groupID"] as? String, !groupID.isEmpty,
              let updateGroupInfoCallback = param["updateGroupInfoCallback"] as? (() -> Void),
              let pushVC = param["pushVC"] as? UINavigationController else {
            return nil
        }
        
        let info = TUIExtensionInfo()
        info.icon = nil
        info.weight = 100
        info.text = TUISwift.timCommonLocalizableString("TUIKitGroupTransferOwner")
        info.onClicked = { clickParam in
            let vc = TUISelectGroupMemberViewController_Minimalist()
            vc.optionalStyle = .transferOwner
            vc.groupId = groupID
            vc.name = TUISwift.timCommonLocalizableString("TUIKitGroupTransferOwner")
            vc.selectedFinished = { modelList in
                guard let userModel = modelList.first else { return }
                let member = userModel.userId
                self.transferGroupOwner(groupID, member: member, succ: {
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
    
    func transferGroupOwner(_ groupID: String, member: String, succ: @escaping () -> Void, fail: @escaping (Int, String) -> Void) {
        V2TIMManager.sharedInstance().transferGroupOwner(groupID, member: member, succ: {
            succ()
        }, fail: { code, desc in
            fail(Int(code), desc ?? "")
        })
    }
    
    // MARK: Click
    func didAddMemebers() {
        var ids: [String] = []
        var displayNames: [String: String] = [:]
        for cd in membersData {
            if cd.identifier != V2TIMManager.sharedInstance().getLoginUser() {
                ids.append(cd.identifier)
                displayNames[cd.identifier] = cd.name ?? ""
            }
        }
        
        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { array in
            if self.tag == 1 {
                var list: [String] = []
                for data in array {
                    list.append(data.identifier)
                }
                self.pushVC?.popViewController(animated: true)
                self.addGroupId(self.groupId, members: list)
            } else if self.tag == 2 {
                var list: [String] = []
                for data in array {
                    list.append(data.identifier)
                }
                self.pushVC?.popViewController(animated: true)
                self.deleteGroupId(self.groupId, members: list)
            }
        }
        
        var param: [String: Any] = [:]
        param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] = TUISwift.timCommonLocalizableString("GroupAddFirend")
        param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey] = ids
        param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] = displayNames
        param[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] = selectContactCompletion
        
        if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory_Minimalist, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: param) as? UIViewController {
            pushVC?.pushViewController(vc, animated: true)
        }
        tag = 1
    }
    
    func didCurrentMemberAtCell(_ data: TUIGroupMemberCellData_Minimalist) {
        let mem = data
        var ids: [String] = []
        var displayNames: [String: String] = [:]
        for cd in membersData {
            if cd.identifier != V2TIMManager.sharedInstance().getLoginUser() {
                ids.append(cd.identifier)
                displayNames[cd.identifier] = cd.name ?? ""
            }
        }
        
        let userID = mem.identifier
        getUserOrFriendProfileVCWithUserID(userID, succ: { vc in
            self.pushVC?.pushViewController(vc, animated: true)
        }, fail: { code, desc in
            // Handle failure
        })
    }
    
    func getUserOrFriendProfileVCWithUserID(_ userID: String, succ: @escaping (UIViewController) -> Void, fail: @escaping (Int, String) -> Void) {
        let param: [String: Any] = [
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey: userID,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey: succ,
            TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey: fail
        ]
        TUICore.createObject(TUICore_TUIContactObjectFactory_Minimalist, key: TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod, param: param)
    }
    
    func addGroupId(_ groupId: String?, members: [String]) {
        guard let groupId = groupId else { return }
        V2TIMManager.sharedInstance().inviteUser(toGroup: groupId, userList: members, succ: { resultList in
            TUITool.makeToast(TUISwift.timCommonLocalizableString("add_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }
    
    func deleteGroupId(_ groupId: String?, members: [String]) {
        guard let groupId = groupId else { return }
        V2TIMManager.sharedInstance().kickGroupMember(groupId, memberList: members, reason: "", succ: { resultList in
            TUITool.makeToast(TUISwift.timCommonLocalizableString("delete_success"))
        }, fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
        })
    }
}
