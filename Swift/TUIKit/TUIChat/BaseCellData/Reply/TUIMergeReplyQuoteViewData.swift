import TIMCommon
import UIKit

class TUIMergeReplyQuoteViewData: TUIReplyQuoteViewData {
    var title: String = ""
    var abstract: String = ""

    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUIMergeMessageCellData else {
            return nil
        }

        let myData = TUIMergeReplyQuoteViewData()
        myData.title = originCellData.title ?? ""
        let abstract = originCellData.abstractAttributedString()
        myData.abstract = abstract.string
        myData.originCellData = originCellData
        return myData
    }

    override func contentSize(maxWidth: CGFloat) -> CGSize {
        let singleHeight = UIFont.systemFont(ofSize: 10.0).lineHeight
        let titleAttributeString = title.getFormatEmojiString(with: UIFont.systemFont(ofSize: 10.0), emojiLocations: nil)
        let titleRect = titleAttributeString.boundingRect(
            with: CGSize(width: maxWidth, height: singleHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let width = titleRect.width
        let height = titleRect.height
        return CGSize(width: min(width, maxWidth), height: height)
    }
}
