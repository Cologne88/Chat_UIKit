import Foundation
import ImSDK_Plus

class TUIGroupMemberDataProvider: NSObject {
    var groupInfo: V2TIMGroupInfo?
    var isNoMoreData: Bool = false
    private let groupID: String
    private var index: UInt64 = 0

    init(groupID: String) {
        self.groupID = groupID
    }

    func loadDatas(completion: @escaping (Bool, String, [TUIMemberInfoCellData]) -> Void) {
        V2TIMManager.sharedInstance().getGroupMemberList(groupID, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_ALL.rawValue), nextSeq: index, succ: { [weak self] nextSeq, memberList in
            guard let self, let memberList = memberList else { return }
            self.index = nextSeq
            self.isNoMoreData = (nextSeq == 0)
            var arrayM: [TUIMemberInfoCellData] = []
            var ids: [String] = []
            var map: [String: TUIMemberInfoCellData] = [:]

            for member in memberList {
                let user = TUIMemberInfoCellData(identifier: member.userID)
                user.role = Int(member.role)
                if let nameCard = member.nameCard, !nameCard.isEmpty {
                    user.name = nameCard
                } else if let friendRemark = member.friendRemark, !friendRemark.isEmpty {
                    user.name = friendRemark
                } else if let nickName = member.nickName, !nickName.isEmpty {
                    user.name = nickName
                } else {
                    user.name = member.userID
                }
                arrayM.append(user)
                if let identifier = user.identifier {
                    ids.append(identifier)
                    map[identifier] = user
                }
            }

            V2TIMManager.sharedInstance().getUsersInfo(ids, succ: { infoList in
                guard let infoList = infoList else { return }
                let userIDs = map.keys
                for info in infoList {
                    if userIDs.contains(info.userID.safeValue) {
                        map[info.userID.safeValue]?.avatarUrl = info.faceURL.safeValue
                    }
                }
                completion(true, "", arrayM)
            }, fail: { _, desc in
                completion(false, desc ?? "", [])
            })
        }, fail: { _, msg in
            completion(false, msg ?? "", [])
        })
    }
}
