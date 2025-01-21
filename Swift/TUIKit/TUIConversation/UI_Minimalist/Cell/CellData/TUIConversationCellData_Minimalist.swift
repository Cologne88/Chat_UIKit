import Foundation
import TIMCommon

class TUIConversationCellData_Minimalist: TUIConversationCellData {
    required init() {
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(64.0)
    }
}
