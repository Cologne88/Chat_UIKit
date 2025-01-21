import Foundation
import TIMCommon
import UIKit

class TUIReplyQuoteViewData {
    var onFinish: TUIReplyQuoteAsyncLoadFinish?
    var originCellData: TUIMessageCellData?
    var supportForReply: Bool = false
    var showRevokedOriginMessage: Bool = false

    class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        return nil
    }

    func contentSize(maxWidth: CGFloat) -> CGSize {
        return .zero
    }
}
