//  TUINewFriendViewDataProvider_Minimalist.swift
//  TUIContact

import Foundation
import ImSDK_Plus

class TUINewFriendViewDataProvider_Minimalist: NSObject {
    @objc dynamic var dataList: [TUICommonPendencyCellData_Minimalist] = []

    /**
     *  Has data not shown.
     *  YES：There are unshown requests；NO：All requests are loaded.
     */
    var hasNextData: Bool = false

    var isLoading: Bool = false

    override init() {
        super.init()
        self.dataList = []
    }

    func loadData() {
        guard !isLoading else { return }
        isLoading = true
       V2TIMManager.sharedInstance().getFriendApplicationList { [weak self] result in
            guard let self = self, let result = result else { return }
            if let applicationList = result.applicationList as? [V2TIMFriendApplication] {
                var list: [TUICommonPendencyCellData_Minimalist] = []
                for item in applicationList {
                    let application: V2TIMFriendApplication = item
                    if application.type == .FRIEND_APPLICATION_COME_IN {
                        let data = TUICommonPendencyCellData_Minimalist(application: item)
                        data.hideSource = true
                        list.append(data)
                    }
                }
                self.dataList = list
            }
            self.isLoading = false
            self.hasNextData = true
        } fail: { _, _ in }
    }

    func removeData(_ data: TUICommonPendencyCellData_Minimalist) {
        dataList.removeAll { $0 == data }
       V2TIMManager.sharedInstance().deleteFriendApplication(application: data.application, succ: nil, fail: nil)
    }

    func agreeData(_ data: TUICommonPendencyCellData_Minimalist) {
       V2TIMManager.sharedInstance().acceptFriendApplication(application: data.application, acceptType: .FRIEND_ACCEPT_AGREE_AND_ADD, succ: nil, fail: nil)
        data.isAccepted = true
    }

    func rejectData(_ data: TUICommonPendencyCellData_Minimalist) {
       V2TIMManager.sharedInstance().refuseFriendApplication(application: data.application, succ: nil, fail: nil)
        data.isRejected = true
    }
}
