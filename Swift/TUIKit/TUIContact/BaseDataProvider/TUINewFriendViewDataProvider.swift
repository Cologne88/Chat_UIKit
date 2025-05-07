import Foundation
import ImSDK_Plus

class TUINewFriendViewDataProvider: NSObject {
    @objc dynamic var dataList: [TUICommonPendencyCellData] = []

    var hasNextData: Bool = false
    var isLoading: Bool = false

    private var origSeq: UInt64 = 0
    private var seq: UInt64 = 0
    private var timestamp: UInt64 = 0
    private var numPerPage: UInt64 = 5

    override init() {
        super.init()
    }

    func loadData() {
        guard !isLoading else { return }
        isLoading = true
        V2TIMManager.sharedInstance().getFriendApplicationList { [weak self] result in
            guard let self = self, let applicationList = result?.applicationList else { return }
            var list: [TUICommonPendencyCellData] = []
            for item in applicationList {
                if let item = item as? V2TIMFriendApplication, item.type == .FRIEND_APPLICATION_COME_IN {
                    let data = TUICommonPendencyCellData(application: item)
                    data.hideSource = true
                    list.append(data)
                }
            }
            self.dataList = list
            self.isLoading = false
            self.hasNextData = true
        } fail: { _, _ in }
    }

    func removeData(_ data: TUICommonPendencyCellData) {
        dataList.removeAll { $0 == data }
        V2TIMManager.sharedInstance().deleteFriendApplication(application: data.application, succ: nil, fail: nil)
    }

    func agreeData(_ data: TUICommonPendencyCellData) {
        V2TIMManager.sharedInstance().acceptFriendApplication(application: data.application, acceptType: .FRIEND_ACCEPT_AGREE_AND_ADD, succ: nil, fail: nil)
        data.isAccepted = true
    }

    func rejectData(_ data: TUICommonPendencyCellData) {
        V2TIMManager.sharedInstance().refuseFriendApplication(application: data.application, succ: nil, fail: nil)
        data.isRejected = true
    }
}
