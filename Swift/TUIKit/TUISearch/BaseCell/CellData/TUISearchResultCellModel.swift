import Foundation
import TUICore
import UIKit

class TUISearchResultCellModel: NSObject {
    var title: String?
    var details: String?
    var titleAttributeString: NSAttributedString?
    var detailsAttributeString: NSAttributedString?

    @objc dynamic var avatarUrl: String?
    var avatarType: TUIKitAvatarType = .TAvatarTypeRounded
    var avatarImage: UIImage?
    var groupID: String?
    var groupType: String?

    var hideSeparatorLine: Bool = false
    var context: Any?
}
