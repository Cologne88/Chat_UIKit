import Foundation
import UIKit

public typealias TUIInputMoreCallback = (_ param: [AnyHashable: Any]) -> Void
public class TUIInputMoreCellData: NSObject {
    public var image: UIImage?
    public var title: String?
    public var onClicked: TUIInputMoreCallback?
    public var priority: Int = 0
}
