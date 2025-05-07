import Foundation
import TIMCommon
import TUICore

public class TUIContactObjectFactory: NSObject, TUIObjectProtocol {
    static let sharedInstance = TUIContactObjectFactory()
    
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory("TUICore_TUIContactObjectFactory", objectFactory: TUIContactObjectFactory.sharedInstance)
    }
    
    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        switch method {
        case "TUICore_TUIContactObjectFactory_GetContactControllerMethod":
            return createContactController()
        case "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod":
            let title = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey"] as? String
            let sourceIds = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_SourceIdsKey"] as? [String]
            let disableIds = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey"] as? [String]
            let displayNames = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey"] as? [String: String]
            let maxSelectCount = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_MaxSelectCount"] as? Int
            let completion = param?["TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey"] as? ([TUICommonContactSelectCellData]) -> Void
            return createContactSelectController(sourceIds: sourceIds, disableIds: disableIds, title: title, displayNames: displayNames, maxSelectCount: maxSelectCount, completion: completion)
        case "TUICore_TUIContactObjectFactory_GetFriendProfileControllerMethod":
            guard let friendInfo = param?["TUICore_TUIContactObjectFactory_GetFriendProfileControllerMethod_FriendProfileKey"] as? V2TIMFriendInfo else {
                return nil
            }
            return createFriendProfileController(friendInfo: friendInfo)
        case "TUICore_TUIContactObjectFactory_UserProfileController_Classic":
            guard let userInfo = param?["TUICore_TUIContactObjectFactory_UserProfileController_UserProfile"] as? V2TIMUserFullInfo,
                  let cellData = param?["TUICore_TUIContactObjectFactory_UserProfileController_PendencyData"] as? TUICommonCellData,
                  let actionTypeRaw = param?["TUICore_TUIContactObjectFactory_UserProfileController_ActionType"] as? UInt,
                  let actionType = ProfileControllerAction(rawValue: actionTypeRaw)
            else {
                return nil
            }
            return createUserProfileController(user: userInfo, pendencyData: cellData, actionType: actionType)
        case "TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod":
            let title = param?["TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_TitleKey"] as? String
            let groupName = param?["TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupNameKey"] as? String
            let groupType = param?["TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupTypeKey"] as? String
            let contactList = param?["TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_ContactListKey"] as? [TUICommonContactSelectCellData]
            let completion = param?["TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_CompletionKey"] as? (Bool, V2TIMGroupInfo?) -> Void
            return createGroupCreateController(title: title, groupName: groupName, groupType: groupType, contactList: contactList, completion: completion)
        case "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod":
            // This logic ensures compatibility since the parameter might be a block/closure.
            if let userID = param?["TUICore_TUIContactService_etUserOrFriendProfileVCMethod_UserIDKey"] as? String {
                var succBlock: SuccBlock?
                if let closure = param?["TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey"] as? (UIViewController) -> Void {
                    succBlock = closure
                } else if let block: SuccBlock = getBlock(from: param, key: "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey") {
                    succBlock = block
                }
                
                var failBlock: FailBlock?
                if let closure = param?["TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey"] as? (Int32, String?) -> Void {
                    failBlock = closure
                } else if let block: FailBlock = getBlock(from: param, key: "TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey") {
                    failBlock = block
                }
                
                createUserOrFriendProfileVCWithUserID(userID: userID, succBlock: succBlock, failBlock: failBlock)
            }
            return nil
        case "TUICore_TUIContactObjectFactory_GetGroupMemberVCMethod":
            guard let groupId = param?["groupID"] as? String,
                  let groupInfo = param?["groupInfo"] as? V2TIMGroupInfo
            else {
                return nil
            }
            let membersController = TUIGroupMemberController()
            membersController.groupId = groupId
            membersController.groupInfo = groupInfo
            return membersController
        case "TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod":
            guard let groupInfo = param?["TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod_GroupInfoKey"] as? V2TIMGroupInfo else {
                return nil
            }
            return createGroupRequestViewController(groupInfo: groupInfo)
        case "TUICore_TUIContactObjectFactory_GetGroupInfoVC_Classic":
            guard let groupID = param?["TUICore_TUIContactObjectFactory_GetGroupInfoVC_GroupID"] as? String else {
                return nil
            }
            return createGroupInfoController(groupID: groupID)
        case "TUICore_TUIContactObjectFactory_SelectGroupMemberVC_Classic":
            let groupID = param?["TUICore_TUIContactObjectFactory_SelectGroupMemberVC_GroupID"] as? String
            let title = param?["TUICore_TUIContactObjectFactory_SelectGroupMemberVC_Name"] as? String
            let optionalStyleNum = param?["TUICore_TUIContactObjectFactory_SelectGroupMemberVC_OptionalStyle"] as? NSNumber
            let selectedUserIDList = param?["TUICore_TUIContactObjectFactory_SelectGroupMemberVC_SelectedUserIDList"] as? [String]
            return createSelectGroupMemberViewController(groupID: groupID, name: title, optionalStyle: TUISelectMemberOptionalStyle(rawValue: optionalStyleNum?.intValue ?? 0), selectedUserIDList: selectedUserIDList, userData: "")
        default:
            return nil
        }
    }
    
    private func createContactController() -> UIViewController {
        return TUIContactController()
    }
    
    private func createContactSelectController(sourceIds: [String]?, disableIds: [String]?, title: String?, displayNames: [String: String]?, maxSelectCount: Int?, completion: (([TUICommonContactSelectCellData]) -> Void)?) -> UIViewController {
        let vc = TUIContactSelectController()
        vc.title = title
        vc.displayNames = displayNames
        vc.maxSelectCount = maxSelectCount ?? 0
        if let sourceIds = sourceIds, !sourceIds.isEmpty {
            vc.sourceIds = sourceIds
        } else if let disableIds = disableIds, !disableIds.isEmpty {
            vc.viewModel?.disableFilter = { data in
                disableIds.contains(data.identifier)
            }
        }
        vc.finishBlock = { selectArray in
            completion?(selectArray)
        }
        return vc
    }
    
    private func createFriendProfileController(friendInfo: V2TIMFriendInfo) -> UIViewController {
        let vc = TUIFriendProfileController()
        vc.friendProfile = friendInfo
        return vc
    }
    
    private func createUserProfileController(user: V2TIMUserFullInfo, actionType: ProfileControllerAction) -> UIViewController {
        let vc = TUIUserProfileController()
        vc.userFullInfo = user
        vc.actionType = actionType
        return vc
    }
    
    private func createUserProfileController(user: V2TIMUserFullInfo?, pendencyData: TUICommonCellData?, actionType: ProfileControllerAction) -> UIViewController {
        let vc = TUIUserProfileController(style: .grouped)
        vc.userFullInfo = user
        vc.actionType = actionType
        if actionType == .PCA_GROUP_CONFIRM, let data = pendencyData as? TUIGroupPendencyCellData {
            vc.groupPendency = data
        } else if actionType == .PCA_PENDENDY_CONFIRM, let data = pendencyData as? TUICommonPendencyCellData {
            vc.pendency = data
        }
        return vc
    }
    
    private func createGroupCreateController(title: String?, groupName: String?, groupType: String?, contactList: [TUICommonContactSelectCellData]?, completion: ((Bool, V2TIMGroupInfo) -> Void)?) -> UIViewController {
        let vc = TUIGroupCreateController()
        vc.title = title
        
        let createGroupInfo = V2TIMGroupInfo()
        createGroupInfo.groupID = ""
        createGroupInfo.groupName = groupName ?? ""
        createGroupInfo.groupType = groupType
        vc.createGroupInfo = createGroupInfo
        vc.createContactArray = contactList
        
        vc.submitCallback = { isSuccess, info in
            guard let info = info else { return }
            completion?(isSuccess, info)
        }
        return vc
    }
    
    private func createUserOrFriendProfileVCWithUserID(userID: String, succBlock: ((UIViewController) -> Void)?, failBlock: V2TIMFail?) {
        guard !userID.isEmpty else {
            failBlock?(-1, "invalid parameter, userID is nil")
            return
        }
        
        V2TIMManager.sharedInstance().getFriendsInfo([userID], succ: { resultList in
            guard let resultList = resultList, let friend = resultList.first else {
                failBlock?(-1, "invalid parameter, friend info is nil")
                return
            }
            if (friend.relation.rawValue & V2TIMFriendRelationType.FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST.rawValue) != 0 {
                let friendInfo: V2TIMFriendInfo? = friend.friendInfo
                if let friendInfo = friendInfo {
                    let vc = self.createFriendProfileController(friendInfo: friendInfo)
                    succBlock?(vc)
                }
            } else {
                V2TIMManager.sharedInstance().getUsersInfo([userID], succ: { infoList in
                    guard let infoList = infoList, let user = infoList.first else {
                        failBlock?(-1, "invalid parameter, user info is nil")
                        return
                    }
                    var actionType = ProfileControllerAction(rawValue: 1)
                    if user.userID == V2TIMManager.sharedInstance().getLoginUser() {
                        actionType = ProfileControllerAction(rawValue: 0)
                    }
                    let vc = self.createUserProfileController(user: user, actionType: actionType!)
                    succBlock?(vc)
                }) { _, _ in
                    // to do
                }
            }
        }) { _, _ in
            // to do
        }
    }
    
    private func createGroupRequestViewController(groupInfo: V2TIMGroupInfo) -> UIViewController {
        let vc = TUIGroupRequestViewController()
        vc.groupInfo = groupInfo
        return vc
    }
    
    private func createGroupInfoController(groupID: String) -> UIViewController? {
        // Implementation needed
        return nil
    }
    
    private func createSelectGroupMemberViewController(groupID: String?, name: String?, optionalStyle: TUISelectMemberOptionalStyle?, selectedUserIDList: [String]?, userData: String?) -> UIViewController {
        let vc = TUISelectGroupMemberViewController()
        vc.groupId = groupID
        vc.name = name
        vc.optionalStyle = optionalStyle ?? .none
        vc.selectedUserIDList = selectedUserIDList
        vc.userData = userData
        return vc
    }
}
