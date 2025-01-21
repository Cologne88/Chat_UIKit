//  TUIGroupConversationListViewDataProvider_Minimalist.swift
//  TUIContact

import Foundation
import ImSDK_Plus

/**
 * 【Module name】Group List View Model (TUIGroupConversationListViewModel)
 * 【Function description】It is responsible for pulling the group information of the user and loading the obtained data.
 *  The view model pulls the group information of the user through the interface provided by the IM SDK. The group information is classified and stored
 * according to the first latter of the name.
 */
class TUIGroupConversationListViewDataProvider_Minimalist: NSObject {
    var dataDict: [String: [TUICommonContactCellData_Minimalist]] = [:]
    var groupList: [String] = []
    @objc dynamic var isLoadFinished: Bool = false
    private var isLoading: Bool = false

    func loadConversation() {
        guard !isLoading else { return }
        isLoading = true
        isLoadFinished = false

        var dataDict: [String: [TUICommonContactCellData_Minimalist]] = [:]
        var groupList: [String] = []
        var nonameList: [TUICommonContactCellData_Minimalist] = []

        V2TIMManager.sharedInstance().getJoinedGroupList { [weak self] infoList in
            guard let self = self else { return }
            guard let infoList = infoList else { return }
            for group in infoList {
                let data = TUICommonContactCellData_Minimalist(groupInfo: group)
                let groupKey = data.title.safeValue.firstPinYin().uppercased()
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
        } fail: { [weak self] _, _ in
            // Handle error if needed
            guard let self = self else { return }
            self.isLoading = false
        }
    }

    func removeData(_ data: TUICommonContactCellData_Minimalist) {
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
