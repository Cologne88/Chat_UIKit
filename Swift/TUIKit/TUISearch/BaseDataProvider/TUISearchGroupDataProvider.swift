import Foundation
import TIMCommon

struct TUISearchGroupMatchField: OptionSet {
    let rawValue: Int

    static let groupID = TUISearchGroupMatchField(rawValue: 0x1 << 1)
    static let groupName = TUISearchGroupMatchField(rawValue: 0x1 << 2)
    static let member = TUISearchGroupMatchField(rawValue: 0x1 << 3)
}

struct TUISearchGroupMemberMatchField: OptionSet {
    let rawValue: Int

    static let userID = TUISearchGroupMemberMatchField(rawValue: 0x1 << 1)
    static let nickName = TUISearchGroupMemberMatchField(rawValue: 0x1 << 2)
    static let remark = TUISearchGroupMemberMatchField(rawValue: 0x1 << 3)
    static let nameCard = TUISearchGroupMemberMatchField(rawValue: 0x1 << 4)
}

typealias TUISearchGroupResultListSucc = ([TUISearchGroupResult]) -> Void
typealias TUISearchGroupResultListFail = (Int, String) -> Void

class TUISearchGroupParam {
    var keywordList: [String] = []
    var isSearchGroupID: Bool = false
    var isSearchGroupName: Bool = false
    var isSearchGroupMember: Bool = false
    var isSearchMemberUserID: Bool = false
    var isSearchMemberNickName: Bool = false
    var isSearchMemberRemark: Bool = false
    var isSearchMemberNameCard: Bool = false
}

class TUISearchGroupMemberMatchResult {
    fileprivate(set) var memberInfo: V2TIMGroupMemberFullInfo?
    fileprivate(set) var memberMatchField: TUISearchGroupMemberMatchField?
    fileprivate(set) var memberMatchValue: String?
}

class TUISearchGroupResult {
    fileprivate(set) var groupInfo: V2TIMGroupInfo?
    fileprivate(set) var matchField: TUISearchGroupMatchField?
    fileprivate(set) var matchValue: String?
    fileprivate(set) var matchMembers: [TUISearchGroupMemberMatchResult]?
    fileprivate var groupId: String?
    fileprivate var memberInfos: [V2TIMGroupMemberFullInfo]?
}

class TUISearchGroupDataProvider {
    static func searchGroups(_ searchParam: TUISearchGroupParam, succ: TUISearchGroupResultListSucc?, fail: TUISearchGroupResultListFail?) {
        guard !searchParam.keywordList.isEmpty, searchParam.keywordList.count <= 5 else {
            fail?(-1, "Invalid parameters, keyword count is zero or beyond the limit of five")
            return
        }

        let keywords = searchParam.keywordList.map { $0.lowercased() }

        var groupsOne: [TUISearchGroupResult]?
        var groupsTwo: [TUISearchGroupResult]?

        let group = DispatchGroup()

        group.enter()
        doSearchGroups(searchParam, keywords: keywords, succ: { resultSet in
            groupsOne = resultSet
            group.leave()
        }, fail: { _, _ in
            group.leave()
        })

        if searchParam.isSearchGroupMember {
            group.enter()
            doSearchMembers(searchParam, keywords: keywords, succ: { resultSet in
                groupsTwo = resultSet
                group.leave()
            }, fail: { _, _ in
                group.leave()
            })
        }

        group.notify(queue: .global()) {
            let resultSet = mergeGroupSets(groupsOne, withOthers: groupsTwo)
            DispatchQueue.main.async {
                succ?(resultSet)
            }
        }
    }

    private static func doSearchGroups(_ searchParam: TUISearchGroupParam, keywords: [String], succ: @escaping TUISearchGroupResultListSucc, fail: @escaping TUISearchGroupResultListFail) {
        let groupParam = V2TIMGroupSearchParam()
        groupParam.keywordList = keywords
        groupParam.isSearchGroupID = searchParam.isSearchGroupID
        groupParam.isSearchGroupName = searchParam.isSearchGroupName

        V2TIMManager.sharedInstance().searchGroups(searchParam: groupParam, succ: { groupList in
            guard let groupList = groupList else { return }
            var arrayM = [TUISearchGroupResult]()
            for groupInfo in groupList {
                let result = TUISearchGroupResult()
                result.groupId = groupInfo.groupID
                result.groupInfo = groupInfo
                result.matchMembers = nil
                if match(keywords, groupInfo.groupName ?? "") {
                    result.matchField = TUISearchGroupMatchField.groupName
                    result.matchValue = groupInfo.groupName
                    arrayM.append(result)
                    continue
                }
                if match(keywords, groupInfo.groupID ?? "") {
                    result.matchField = TUISearchGroupMatchField.groupID
                    result.matchValue = groupInfo.groupID
                    arrayM.append(result)
                    continue
                }
            }
            succ(arrayM)
        }, fail: { code, desc in
            fail(Int(code), desc ?? "")
        })
    }

    private static func doSearchMembers(_ searchParam: TUISearchGroupParam, keywords: [String], succ: @escaping TUISearchGroupResultListSucc, fail: @escaping TUISearchGroupResultListFail) {
        let memberParam = V2TIMGroupMemberSearchParam()
        memberParam.keywordList = keywords
        memberParam.groupIDList = nil
        memberParam.isSearchMemberUserID = searchParam.isSearchMemberUserID
        memberParam.isSearchMemberNickName = searchParam.isSearchMemberNickName
        memberParam.isSearchMemberNameCard = searchParam.isSearchMemberNameCard
        memberParam.isSearchMemberRemark = searchParam.isSearchMemberRemark

        V2TIMManager.sharedInstance().searchGroupMembers(searchParam: memberParam, succ: { memberList in
            guard let memberList = memberList else { return }

            var resultSet = [TUISearchGroupResult]()
            var groupIds = [String]()
            for (groupId, obj) in memberList {
                groupIds.append(groupId)
                let result = TUISearchGroupResult()
                result.groupId = groupId
                result.matchField = TUISearchGroupMatchField.member
                result.matchValue = nil
                result.memberInfos = obj
                resultSet.append(result)
            }

            var groupInfoMap = [String: V2TIMGroupInfo]()
            let group = DispatchGroup()

            group.enter()
            V2TIMManager.sharedInstance().getGroupsInfo(groupIds, succ: { groupResultList in
                for groupInfoResult in groupResultList ?? [] {
                    if groupInfoResult.resultCode == 0 {
                        if let groupID = groupInfoResult.info?.groupID {
                            groupInfoMap[groupID] = groupInfoResult.info
                        }
                    }
                }
                group.leave()
            }, fail: { _, _ in
                group.leave()
            })

            group.enter()
            for result in resultSet {
                let members = result.memberInfos ?? []
                var arrayM = [TUISearchGroupMemberMatchResult]()
                for memberInfo in members {
                    let result = TUISearchGroupMemberMatchResult()
                    if match(keywords, memberInfo.nameCard ?? "") {
                        result.memberMatchField = TUISearchGroupMemberMatchField.nameCard
                        result.memberMatchValue = memberInfo.nameCard
                        arrayM.append(result)
                        continue
                    }

                    if match(keywords, memberInfo.friendRemark ?? "") {
                        result.memberMatchField = TUISearchGroupMemberMatchField.remark
                        result.memberMatchValue = memberInfo.friendRemark
                        arrayM.append(result)
                        continue
                    }

                    if match(keywords, memberInfo.nickName ?? "") {
                        result.memberMatchField = TUISearchGroupMemberMatchField.nickName
                        result.memberMatchValue = memberInfo.nickName
                        arrayM.append(result)
                        continue
                    }

                    if match(keywords, memberInfo.userID ?? "") {
                        result.memberMatchField = TUISearchGroupMemberMatchField.userID
                        result.memberMatchValue = memberInfo.userID
                        arrayM.append(result)
                        continue
                    }
                }
                result.matchMembers = arrayM
            }
            group.leave()

            group.notify(queue: .global()) {
                var arrayM = [TUISearchGroupResult]()
                let validGroupIds = groupInfoMap.keys
                for result in resultSet {
                    if let groupID = result.groupId, validGroupIds.contains(groupID) {
                        result.groupInfo = groupInfoMap[groupID]
                        arrayM.append(result)
                    }
                }
                succ(arrayM)
            }
        }, fail: { code, desc in
            fail(Int(code), desc ?? "")
        })
    }

    private static func mergeGroupSets(_ groupsOne: [TUISearchGroupResult]?, withOthers groupsTwo: [TUISearchGroupResult]?) -> [TUISearchGroupResult] {
        var arrayM = [TUISearchGroupResult]()
        var map = [String: Int]()

        groupsOne?.forEach { result in
            arrayM.append(result)
            if let groupId = result.groupId {
                map[groupId] = 1
            }
        }

        groupsTwo?.forEach { result in
            if let groupId = result.groupId, map[groupId] == nil {
                arrayM.append(result)
            }
        }

        arrayM.sort { $0.groupInfo?.lastMessageTime ?? 0 > $1.groupInfo?.lastMessageTime ?? 0 }
        return arrayM
    }

    private static func match(_ keywords: [String], _ text: String) -> Bool {
        for keyword in keywords {
            if text.lowercased().tui_contains(keyword) {
                return true
            }
        }
        return false
    }
}
