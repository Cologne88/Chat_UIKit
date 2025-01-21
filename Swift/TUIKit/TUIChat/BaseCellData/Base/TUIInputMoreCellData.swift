import Foundation
import UIKit

typealias TUIInputMoreCallback = (_ param: [AnyHashable: Any]) -> Void
class TUIInputMoreCellData: NSObject {
    var image: UIImage?
    var title: String?
    var onClicked: TUIInputMoreCallback?
    var priority: Int = 0
}
