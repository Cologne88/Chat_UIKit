import Foundation
import ImSDK_Plus

class TUIBlackListViewDataProvider: NSObject {
    private(set) var blackListData: [TUICommonContactCellData] = []
    @objc private(set) dynamic var isLoadFinished: Bool = false
    private var isLoading: Bool = false

    func loadBlackList() {
        guard !isLoading else { return }
        isLoading = true
        isLoadFinished = false

        V2TIMManager.sharedInstance().getBlackList { [weak self] infoList in
            guard let self = self else { return }
            guard let infoList = infoList else { return }
            var list: [TUICommonContactCellData] = []
            for fd in infoList {
                let data = TUICommonContactCellData(friend: fd)
                list.append(data)
            }
            self.blackListData = list
            self.isLoadFinished = true
            self.isLoading = false
        } fail: { [weak self] _, _ in
            self?.isLoading = false
        }
    }
}
