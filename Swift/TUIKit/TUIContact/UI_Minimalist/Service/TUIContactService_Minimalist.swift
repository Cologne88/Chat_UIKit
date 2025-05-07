//  TUIContactService_Minimalist.swift
//  TUIContact

import Foundation
import TIMCommon
import TUICore

public class TUIContactService_Minimalist: NSObject, TUIServiceProtocol {
    static let sharedInstance = TUIContactService_Minimalist()
    
    @objc public class func swiftLoad() {
        TUISwift.tuiRegisterThemeResourcePath(TUISwift.tuiBundlePath("TUIContactTheme_Minimalist", key: "TUIContactService"), themeModule: TUIThemeModule.contact_Minimalist)
        TUICore.registerService("TUICore_TUIContactService_Minimalist", object: sharedInstance)
    }

    func createGroup(groupType: String, createOption: V2TIMGroupAddOpt, contacts: [TUICommonContactSelectCellData], completion: @escaping (Bool, String?, String?) -> Void) {
        guard let loginUser = V2TIMManager.sharedInstance().getLoginUser() else {
            completion(false, nil, nil)
            return
        }
        
        V2TIMManager.sharedInstance().getUsersInfo([loginUser]) { infoList in
            guard let infoList = infoList else { return }
            var showName = loginUser
            if let firstInfo = infoList.first, let nickName = firstInfo.nickName, !nickName.isEmpty {
                showName = nickName
            }
            
            var groupName = showName
            var members: [V2TIMCreateGroupMemberInfo] = []
            for item in contacts {
                let member = V2TIMCreateGroupMemberInfo()
                member.userID = item.identifier
                member.role = UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_MEMBER.rawValue)
                groupName += "、\(item.title)"
                members.append(member)
            }
            
            if groupName.count > 10 {
                groupName = String(groupName.prefix(10))
            }
            
            let info = V2TIMGroupInfo()
            info.groupName = groupName
            info.groupType = groupType
            if info.groupType != "Work" {
                info.groupAddOpt = createOption
            }
            
            V2TIMManager.sharedInstance().createGroup(info: info, memberList: members) { groupID in
                var content = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessage")
                if info.groupType == "Community" {
                    content = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessage")
                }
                
                let dic: [String: Any] = [
                    "version": GroupCreate_Version,
                    "businessID": "group_create",
                    "opUser": showName,
                    "content": content,
                    "cmd": info.groupType == "Community" ? 1 : 0
                ]
                
                if let data = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted) {
                    if let msg = V2TIMManager.sharedInstance().createCustomMessage(data: data) {
                        V2TIMManager.sharedInstance().sendMessage(message: msg, receiver: nil, groupID: groupID, priority: .PRIORITY_DEFAULT, onlineUserOnly: false, offlinePushInfo: nil, progress: nil, succ: nil, fail: nil)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            completion(true, groupID, groupName)
                        }
                    }
                }
            } fail: { code, _ in
                completion(false, nil, nil)
                if code == ERR_SDK_INTERFACE_NOT_SUPPORT.rawValue {
                    TUITool.postUnsupportNotification(ofService: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunity"), serviceDesc: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunityDesc"), debugOnly: true)
                }
            }
        } fail: { _, _ in
            completion(false, nil, nil)
        }
    }

    // MARK: - TUIServiceProtocol

    func onCall(method: String, param: [String: Any]) -> Any? {
        let returnObject: Any? = nil
        if method == "TUICore_TUIContactService_CreateGroupMethod" {
            if let groupType = param["TUICore_TUIContactService_CreateGroupMethod_GroupTypeKey"] as? String,
               let option = param["TUICore_TUIContactService_CreateGroupMethod_OptionKey"] as? NSNumber,
               let contacts = param["TUICore_TUIContactService_CreateGroupMethod_ContactsKey"] as? [TUICommonContactSelectCellData],
               let completion = param["TUICore_TUIContactService_CreateGroupMethod_CompletionKey"] as? (Bool, String?, String?) -> Void
            {
                createGroup(groupType: groupType, createOption: V2TIMGroupAddOpt(rawValue: option.intValue) ?? .GROUP_ADD_ANY, contacts: contacts, completion: completion)
            }
        }
        return returnObject
    }
}
