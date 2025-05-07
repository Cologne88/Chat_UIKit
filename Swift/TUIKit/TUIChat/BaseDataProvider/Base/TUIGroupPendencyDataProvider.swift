import Foundation
import TIMCommon

class TUIGroupPendencyDataProvider: NSObject {
    var dataList: [TUIGroupPendencyCellData] = []
    private var origSeq: UInt64 = 0
    private var seq: UInt64 = 0
    private var timestamp: UInt64 = 0
    private var numPerPage: UInt64 = 100
    @objc dynamic var unReadCnt: Int = 0
    private var isLoading: Bool = false
    private var hasNextData: Bool = false
    var groupID: String = ""

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onPendencyChanged(_:)), name: NSNotification.Name(rawValue: TUIGroupPendencyCellData_onPendencyChanged), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onPendencyChanged(_ notification: Notification) {
        var unReadCnt = 0
        for data in dataList {
            if data.isRejected || data.isAccepted {
                continue
            }
            unReadCnt += 1
        }
        self.unReadCnt = unReadCnt
    }

    func loadData() {
        if isLoading { return }

        isLoading = true
        V2TIMManager.sharedInstance().getGroupApplicationList { [weak self] result in
            guard let self = self, let result = result else { return }

            var list: [TUIGroupPendencyCellData] = []
            if let applicationList = result.applicationList as? [V2TIMGroupApplication] {
                for item in applicationList {
                    if item.groupID == self.groupID && item.handleStatus == .GROUP_APPLICATION_HANDLE_STATUS_UNHANDLED {
                        let data = TUIGroupPendencyCellData(pendency: item)
                        list.append(data)
                    }
                }
                self.dataList = list
                self.unReadCnt = list.count
            }

            self.isLoading = false
            self.hasNextData = false
        } fail: { _, _ in
            // Handle error if needed
        }
    }

    func acceptData(_ data: TUIGroupPendencyCellData) {
        data.accept()
        unReadCnt -= 1
    }

    func removeData(_ data: TUIGroupPendencyCellData) {
        if let index = dataList.firstIndex(of: data) {
            dataList.remove(at: index)
        }
        data.reject()
        unReadCnt -= 1
    }
}
