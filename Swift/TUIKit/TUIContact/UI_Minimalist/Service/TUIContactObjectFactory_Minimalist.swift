//  TUIContactObjectFactory_Minimalist.swift
//  TUIContact

import Foundation
import TIMCommon
import TUICore

public class TUIContactObjectFactory_Minimalist: NSObject, TUIObjectProtocol {
    static let sharedInstance = TUIContactObjectFactory_Minimalist()
    
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory(TUICore_TUIContactObjectFactory_Minimalist, objectFactory: TUIContactObjectFactory_Minimalist.sharedInstance)
    }
    
    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        switch method {
        case TUICore_TUIContactObjectFactory_GetContactControllerMethod:
            return createContactController()
        case TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod:
            let title = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_TitleKey] as? String
            let sourceIds = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_SourceIdsKey] as? [String]
            let disableIds = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey] as? [String]
            let displayNames = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisplayNamesKey] as? [String: String]
            let maxSelectCount = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_MaxSelectCount] as? Int ?? 0
            let completion = param?[TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey] as? ([TUICommonContactSelectCellData]) -> Void
            return createContactSelectController(sourceIds: sourceIds, disableIds: disableIds, title: title, displayNames: displayNames, maxSelectCount: maxSelectCount, completion: completion)
        case TUICore_TUIContactObjectFactory_GetFriendProfileControllerMethod:
            let friendInfo = param?[TUICore_TUIContactObjectFactory_GetFriendProfileControllerMethod_FriendProfileKey] as? V2TIMFriendInfo
            return createFriendProfileController(friendInfo: friendInfo)
        case TUICore_TUIContactObjectFactory_UserProfileController_Minimalist:
            guard let userInfo = param?[TUICore_TUIContactObjectFactory_UserProfileController_UserProfile] as? V2TIMUserFullInfo,
                  let cellData = param?[TUICore_TUIContactObjectFactory_UserProfileController_PendencyData] as? TUICommonCellData,
                  let actionTypeRaw = param?[TUICore_TUIContactObjectFactory_UserProfileController_ActionType] as? UInt,
                  let actionType = ProfileControllerAction_Minimalist(rawValue: UInt(actionTypeRaw))
            else {
                return nil
            }
            return createUserProfileController(user: userInfo, pendencyData: cellData, actionType: actionType)
        case TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod:
            let title = param?[TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_TitleKey] as? String
            let groupName = param?[TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupNameKey] as? String
            let groupType = param?[TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_GroupTypeKey] as? String
            let contactList = param?[TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_ContactListKey] as? [TUICommonContactSelectCellData]
            let completion = param?[TUICore_TUIContactObjectFactory_GetGroupCreateControllerMethod_CompletionKey] as? (Bool, V2TIMGroupInfo?, UIImage?) -> Void
            return createGroupCreateController(title: title, groupName: groupName, groupType: groupType, contactList: contactList, completion: completion)
        case TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod:
            if let userID = param?[TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_UserIDKey] as? String {
                let succ = param?[TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_SuccKey] as? (UIViewController) -> Void
                let fail = param?[TUICore_TUIContactObjectFactory_GetUserOrFriendProfileVCMethod_FailKey] as? V2TIMFail
                return createUserOrFriendProfileVCWithUserID(userID: userID, succBlock: succ, failBlock: fail)
            }
            return nil
        case TUICore_TUIContactObjectFactory_GetGroupMemberVCMethod:
            let groupId = param?["groupID"] as? String
            let groupInfo = param?["groupInfo"] as? V2TIMGroupInfo
            let membersController = TUIGroupMemberController_Minimalist()
            membersController.groupId = groupId
            membersController.groupInfo = groupInfo
            return membersController
        case TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod:
            let groupInfo = param?[TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod_GroupInfoKey] as? V2TIMGroupInfo
            return createGroupRequestViewController(groupInfo: groupInfo)
        case TUICore_TUIContactObjectFactory_SelectGroupMemberVC_Minimalist:
            let groupID = param?[TUICore_TUIContactObjectFactory_SelectGroupMemberVC_GroupID] as? String
            let title = param?[TUICore_TUIContactObjectFactory_SelectGroupMemberVC_Name] as? String
            let optionalStyleNum = param?[TUICore_TUIContactObjectFactory_SelectGroupMemberVC_OptionalStyle] as? Int ?? 0
            let selectedUserIDList = param?[TUICore_TUIContactObjectFactory_SelectGroupMemberVC_SelectedUserIDList] as? [String]
            return createSelectGroupMemberViewController(groupID: groupID, name: title, optionalStyle: TUISelectMemberOptionalStyle(rawValue: optionalStyleNum) ?? .none, selectedUserIDList: selectedUserIDList, userData: "")
        default:
            return nil
        }
    }
    
    private func createContactController() -> UIViewController {
        return TUIContactController_Minimalist()
    }
    
    private func createContactSelectController(sourceIds: [String]?, disableIds: [String]?, title: String?, displayNames: [String: String]?, maxSelectCount: Int, completion: (([TUICommonContactSelectCellData]) -> Void)?) -> UIViewController {
        let vc = TUIContactSelectController_Minimalist()
        vc.title = title
        vc.displayNames = displayNames
        vc.maxSelectCount = maxSelectCount
        if let sourceIds = sourceIds, !sourceIds.isEmpty {
            vc.sourceIds = sourceIds
        } else if let disableIds = disableIds, !disableIds.isEmpty {
            vc.viewModel.disableFilter = { data in
                disableIds.contains(data.identifier)
            }
        }
        vc.finishBlock = { selectArray in
            completion?(selectArray)
        }
        return vc
    }
    
    private func createFriendProfileController(friendInfo: V2TIMFriendInfo?) -> UIViewController {
        let vc = TUIFriendProfileController_Minimalist()
        vc.friendProfile = friendInfo
        return vc
    }
    
    private func createUserProfileController(user: V2TIMUserFullInfo, actionType: ProfileControllerAction_Minimalist) -> TUIUserProfileController_Minimalist {
        let vc = TUIUserProfileController_Minimalist(style: .grouped)
        vc.userFullInfo = user
        vc.actionType = actionType
        return vc
    }
    
    private func createUserProfileController(user: V2TIMUserFullInfo?, pendencyData: TUICommonCellData?, actionType: ProfileControllerAction_Minimalist) -> UIViewController {
        let vc = TUIUserProfileController_Minimalist(style: .grouped)
        vc.userFullInfo = user
        vc.actionType = actionType
        if actionType == .PCA_GROUP_CONFIRM_MINI, let data = pendencyData as? TUIGroupPendencyCellData {
            vc.groupPendency = data
        } else if actionType == .PCA_PENDENDY_CONFIRM_MINI, let data = pendencyData as? TUICommonPendencyCellData_Minimalist {
            vc.pendency = data
        }
        return vc
    }
    
    private func createGroupCreateController(title: String?, groupName: String?, groupType: String?, contactList: [TUICommonContactSelectCellData]?, completion: ((Bool, V2TIMGroupInfo, UIImage) -> Void)?) -> UIViewController {
        let vc = TUIGroupCreateController_Minimalist()
        vc.title = title ?? ""
        
        let createGroupInfo = V2TIMGroupInfo()
        createGroupInfo.groupID = ""
        createGroupInfo.groupName = groupName
        createGroupInfo.groupType = groupType
        vc.createGroupInfo = createGroupInfo
        vc.createContactArray = contactList ?? []
        
        vc.submitCallback = { isSuccess, info, submitShowImage in
            completion?(isSuccess, info ?? V2TIMGroupInfo(), submitShowImage ?? UIImage())
        }
        
        return vc
    }
    
    private func createUserOrFriendProfileVCWithUserID(userID: String?, succBlock: ((UIViewController) -> Void)?, failBlock: V2TIMFail?) {
        guard let userID = userID, !userID.isEmpty else {
            failBlock?(-1, "invalid parameter, userID is nil")
            return
        }
        
        V2TIMManager.sharedInstance().getFriendsInfo([userID], succ: { resultList in
            guard let resultList = resultList else { return }
            guard let friend = resultList.first else {
                failBlock?(-1, "invalid parameter, friend info is nil")
                return
            }
            if (friend.relation.rawValue & V2TIMFriendRelationType.FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST.rawValue) != 0,
               let friendInfo = friend.friendInfo
            {
                let vc = self.createFriendProfileController(friendInfo: friendInfo)
                succBlock?(vc)
            } else {
                V2TIMManager.sharedInstance().getUsersInfo([userID], succ: { infoList in
                    guard let infoList = infoList else { return }
                    guard let user = infoList.first else {
                        failBlock?(-1, "invalid parameter, user info is nil")
                        return
                    }
                    let actionType: ProfileControllerAction_Minimalist = (user.userID == V2TIMManager.sharedInstance().getLoginUser() ? .PCA_NONE_MINI : .PCA_ADD_FRIEND_MINI)
                    let vc = self.createUserProfileController(user: user, actionType: actionType)
                    succBlock?(vc)
                }, fail: failBlock)
            }
        }, fail: failBlock)
    }
    
    private func createGroupRequestViewController(groupInfo: V2TIMGroupInfo?) -> UIViewController {
        let vc = TUIGroupRequestViewController_Minimalist()
        vc.groupInfo = groupInfo
        return vc
    }

    private func createSelectGroupMemberViewController(groupID: String, name: String, optionalStyle: TUISelectMemberOptionalStyle) -> UIViewController {
        return createSelectGroupMemberViewController(groupID: groupID, name: name, optionalStyle: optionalStyle, selectedUserIDList: [])
    }

    private func createSelectGroupMemberViewController(groupID: String, name: String, optionalStyle: TUISelectMemberOptionalStyle, selectedUserIDList: [Any]) -> UIViewController {
        return createSelectGroupMemberViewController(groupID: groupID, name: name, optionalStyle: optionalStyle, selectedUserIDList: [], userData: "")
    }
    
    private func createSelectGroupMemberViewController(groupID: String?, name: String?, optionalStyle: TUISelectMemberOptionalStyle, selectedUserIDList: [String]?, userData: String) -> UIViewController {
        let vc = TUISelectGroupMemberViewController_Minimalist()
        vc.groupId = groupID
        vc.name = name
        vc.optionalStyle = optionalStyle
        vc.selectedUserIDList = selectedUserIDList ?? []
        vc.userData = userData
        return vc
    }
}
