import Foundation
import TIMCommon
import UIKit

public class TUIReplyQuoteViewData {
    var onFinish: TUIReplyQuoteAsyncLoadFinish?
    var originCellData: TUIMessageCellData?
    var supportForReply: Bool = false
    var showRevokedOriginMessage: Bool = false

    public class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        return nil
    }

    public func contentSize(maxWidth: CGFloat) -> CGSize {
        return .zero
    }
}
