import Foundation
import ImSDK_Plus

class TUIGroupConversationListViewDataProvider: NSObject {
    private(set) var dataDict: [String: [TUICommonContactCellData]] = [:]
    private(set) var groupList: [String] = []
    @objc private(set) dynamic var isLoadFinished: Bool = false
    private var isLoading: Bool = false

    func loadConversation() {
        guard !isLoading else { return }
        isLoading = true
        isLoadFinished = false

        var dataDict: [String: [TUICommonContactCellData]] = [:]
        var groupList: [String] = []
        var nonameList: [TUICommonContactCellData] = []

        V2TIMManager.sharedInstance().getJoinedGroupList { [weak self] infoList in
            guard let self = self, let infoList = infoList else { return }
            for group in infoList {
                let data = TUICommonContactCellData(groupInfo: group)
                if let groupKey = data.title?.firstPinYin().uppercased() {
                    if groupKey.isEmpty || !groupKey.first!.isLetter {
                        nonameList.append(data)
                        continue
                    }
                    var list = dataDict[groupKey] ?? []
                    list.append(data)
                    dataDict[groupKey] = list
                    if !groupList.contains(groupKey) {
                        groupList.append(groupKey)
                    }
                }
            }

            groupList.sort()
            if !nonameList.isEmpty {
                groupList.append("#")
                dataDict["#"] = nonameList
            }
            for key in dataDict.keys {
                dataDict[key]?.sort(by: { $0.compare(to: $1) == .orderedAscending })
            }

            self.groupList = groupList
            self.dataDict = dataDict
            self.isLoadFinished = true
            self.isLoading = false
        } fail: { _, _ in
            // Handle error if needed
        }
    }

    func removeData(_ data: TUICommonContactCellData) {
        var dictDict = dataDict
        for key in dataDict.keys {
            if var list = dataDict[key], let index = list.firstIndex(of: data) {
                list.remove(at: index)
                dictDict[key] = list
                break
            }
        }
        dataDict = dictDict
    }
}
