import UIKit

enum TUIMemberInfoCellStyle: Int {
    case normal = 0
    case add = 1
}

class TUIMemberInfoCellData: NSObject {
    var identifier: String?
    var avatar: UIImage?
    var avatarUrl: String?
    var name: String?
    var style: TUIMemberInfoCellStyle
    var role: Int = 0
    var showAccessory: Bool = false

    init(identifier: String?, avatar: UIImage? = nil, avatarUrl: String? = nil, name: String? = nil, style: TUIMemberInfoCellStyle = .normal, role: Int = 0, showAccessory: Bool = false) {
        self.identifier = identifier
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.name = name
        self.style = style
        self.role = role
        self.showAccessory = showAccessory
    }
}
