import TIMCommon
import UIKit

class TUIContactActionCellData: TUICommonCellData {
    var title: String?
    var icon: UIImage?
    @objc dynamic var readNum: Int = 0

    var onClicked: (([AnyHashable: Any]?) -> Void)?

    override init() {
        super.init()
    }

    init(title: String?, icon: UIImage?, readNum: Int, onClicked: (([AnyHashable: Any]?) -> Void)?) {
        self.title = title
        self.icon = icon
        self.readNum = readNum
        self.onClicked = onClicked
    }
}
