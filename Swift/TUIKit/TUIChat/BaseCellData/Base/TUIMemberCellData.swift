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

        if let nameCard = nameCard, !nameCard.isEmpty {
            self.title = nameCard
        } else if let friendRemark = friendRemark, !friendRemark.isEmpty {
            self.title = friendRemark
        } else if let nickName = nickName, !nickName.isEmpty {
            self.title = nickName
        } else {
            self.title = userID
        }

        super.init()
    }
}
