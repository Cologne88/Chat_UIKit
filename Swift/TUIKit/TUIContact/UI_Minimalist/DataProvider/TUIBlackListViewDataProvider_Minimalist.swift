//  TUIBlackListViewDataProvider_Minimalist.swift
//  TUIContact

import Foundation
import ImSDK_Plus

/**
 * 【Module name】 TUIBlackListViewModel
 * 【Function description】It is responsible for pulling the user's blocklist information and displaying it on the page.
 *  The view model is also responsible for loading the pulled information to facilitate data processing in the client.
 */
class TUIBlackListViewDataProvider_Minimalist: NSObject {

    /**
     *  Bocklist data
     *  The blocklist stores the detailed information of the blocked users.
     *  Include details such as user avatar (URL and image), user ID, user nickname, etc. Used to display detailed information when you click to a detailed meeting.
     */
    private(set) var blackListData: [TUICommonContactCellData_Minimalist] = []

    @objc dynamic var isLoadFinished: Bool = false
    private var isLoading: Bool = false

    func loadBlackList() {
        guard !isLoading else { return }
        isLoading = true
        isLoadFinished = false

        V2TIMManager.sharedInstance().getBlackList { [weak self] infoList in
            guard let self = self else { return }
            guard let infoList = infoList else { return }
            var list: [TUICommonContactCellData_Minimalist] = []
            for fd in infoList {
                let data = TUICommonContactCellData_Minimalist(friend: fd)
                list.append(data)
            }
            self.blackListData = list
            self.isLoadFinished = true
            self.isLoading = false
        } fail: { [weak self] code, msg in
            self?.isLoading = false
        }
    }
}
