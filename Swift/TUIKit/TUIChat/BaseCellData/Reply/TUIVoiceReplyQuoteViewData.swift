import TIMCommon
import UIKit

class TUIVoiceReplyQuoteViewData: TUITextReplyQuoteViewData {
    var icon: UIImage?

    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUIVoiceMessageCellData else {
            return nil
        }

        let myData = TUIVoiceReplyQuoteViewData()
        myData.text = "\(originCellData.duration)\""
        myData.icon = TUISwift.tuiChatCommonBundleImage("voice_reply")
        myData.originCellData = originCellData
        return myData
    }

    override func contentSize(maxWidth: CGFloat) -> CGSize {
        let marginWidth: CGFloat = 18
        let size = "0".size(withAttributes: [.font: UIFont.systemFont(ofSize: 10.0)])
        let rect = text.boundingRect(
            with: CGSize(width: maxWidth - marginWidth, height: size.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 10.0)],
            context: nil
        )
        return CGSize(width: rect.width + marginWidth, height: size.height)
    }
}
