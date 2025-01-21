import TIMCommon
import UIKit

class TUIFileReplyQuoteViewData: TUIVoiceReplyQuoteViewData {
    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUIFileMessageCellData else {
            return nil
        }

        let myData = TUIFileReplyQuoteViewData()
        myData.text = originCellData.fileName ?? ""
        myData.icon = TUISwift.tuiChatCommonBundleImage("msg_file")
        myData.originCellData = originCellData
        return myData
    }
}
