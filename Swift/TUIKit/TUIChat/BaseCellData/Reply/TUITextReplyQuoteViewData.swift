import TIMCommon
import UIKit

class TUITextReplyQuoteViewData: TUIReplyQuoteViewData {
    var text: String = ""

    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUITextMessageCellData else {
            return nil
        }

        let myData = TUITextReplyQuoteViewData()
        myData.text = originCellData.content
        myData.originCellData = originCellData
        return myData
    }

    override func contentSize(maxWidth: CGFloat) -> CGSize {
        let attributeString: NSAttributedString
        let showRevokeStr = (originCellData?.innerMessage.status == .MSG_STATUS_LOCAL_REVOKED) && !showRevokedOriginMessage

        if showRevokeStr {
            let revokeStr = supportForReply ? TUISwift.timCommonLocalizableString("TUIKitRepliesOriginMessageRevoke") : TUISwift.timCommonLocalizableString("TUIKitReferenceOriginMessageRevoke")
            attributeString = revokeStr?.getFormatEmojiString(with: UIFont.systemFont(ofSize: 10.0), emojiLocations: nil) ?? NSAttributedString()
        } else {
            attributeString = text.getFormatEmojiString(with: UIFont.systemFont(ofSize: 10.0), emojiLocations: nil)
        }

        let size = "0".size(withAttributes: [.font: UIFont.systemFont(ofSize: 10.0)])
        let rect = attributeString.boundingRect(
            with: CGSize(width: maxWidth, height: size.height * 2),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        var height = rect.height < size.height * 2 ? rect.height : size.height * 2
        if showRevokeStr && supportForReply {
            height = size.height * 2
        }
        return CGSize(width: rect.width, height: height)
    }
}
