import Foundation
import TIMCommon

class TUIMemberDescribeCellData: TUICommonCellData {
    var title: String?
    var icon: UIImage?
}

class TUIMemberCellData: TUICommonCellData {
    var title: String?
    var avatarUrl: URL?
    var detail: String?
    var userID: String

    init(userID: String, nickName: String? = nil, friendRemark: String? = nil, nameCard: String? = nil, avatarUrl: String, detail: String? = nil) {
        self.userID = userID
        self.avatarUrl = URL(string: avatarUrl)
        self.detail = detail
        self.title = [nameCard, friendRemark, nickName, userID].compactMap { $0?.isEmpty == false ? $0 : nil }.first ?? userID

        super.init()
    }
}
