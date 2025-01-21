import Foundation

class TUIGroupNoticeCellData: NSObject {
    var name: String = ""
    var desc: String = ""
    weak var target: AnyObject?
    var selector: Selector?
}
