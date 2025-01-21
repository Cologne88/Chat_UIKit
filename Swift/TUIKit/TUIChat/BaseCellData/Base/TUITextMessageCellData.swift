import TIMCommon
import TUICore
import UIKit

class TUITextMessageCellData: TUIBubbleMessageCellData {
    var isAudioCall: Bool = false
    var isVideoCall: Bool = false
    var isCaller: Bool = false
    var showUnreadPoint: Bool = false

    var emojiLocations: [[NSValue: NSAttributedString]] = []
    var textSize: CGSize = .zero
    var textOrigin: CGPoint = .zero

    private var attributedString: NSMutableAttributedString?
    private var size: CGSize = .zero
    private var containerWidth: CGFloat = 0.0

    var content: String = "" {
        didSet {
            if oldValue != content {
                attributedString = nil
            }
        }
    }

    override init(direction: TMsgDirection) {
        super.init(direction: direction)
        if direction == .MsgDirectionIncoming {
            self.cellLayout = TUIMessageCellLayout.incommingTextMessage()
        } else {
            self.cellLayout = TUIMessageCellLayout.outgoingTextMessage()
        }
    }

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        let textData = TUITextMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        if let textElem = message.textElem {
            textData.content = textElem.text.safeValue
        }
        textData.reuseId = TTextMessageCell_ReuseId
        textData.status = .Msg_Status_Init
        return textData
    }

    override class func getDisplayString(_ message: V2TIMMessage) -> String {
        if let textElem = message.textElem, let text = textElem.text {
            return text.getLocalizableStringWithFaceContent()
        }
        return ""
    }

    override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUITextReplyQuoteViewData")
    }

    override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUITextReplyQuoteView")
    }

    func getContentAttributedString(textFont: UIFont) -> NSAttributedString {
        if attributedString == nil {
            emojiLocations = []
            attributedString = content.getFormatEmojiString(with: textFont, emojiLocations: emojiLocations as? NSMutableArray)
            if isAudioCall || isVideoCall {
                let attachment = NSTextAttachment()
                var image: UIImage?
                if isAudioCall {
                    image = TUISwift.tuiChatCommonBundleImage("audio_call")
                }
                if isVideoCall {
                    image = isCaller ? TUISwift.tuiChatCommonBundleImage("video_call_self") : TUISwift.tuiChatCommonBundleImage("video_call")
                }
                attachment.image = image
                attachment.bounds = CGRect(x: 0, y: -(textFont.lineHeight - textFont.pointSize) / 2, width: 16, height: 16)
                let imageString = NSAttributedString(attachment: attachment)
                let spaceString = NSAttributedString(string: "  ", attributes: [.font: textFont])
                if isCaller {
                    attributedString?.append(spaceString)
                    attributedString?.append(imageString)
                } else {
                    attributedString?.insert(spaceString, at: 0)
                    attributedString?.insert(imageString, at: 0)
                }
            }
        }
        return attributedString ?? NSAttributedString()
    }

    func getContentAttributedStringSize(attributeString: NSAttributedString, maxTextSize: CGSize) -> CGSize {
        let rect = attributeString.boundingRect(with: maxTextSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let width = ceil(rect.size.width)
        let height = ceil(rect.size.height)
        return CGSize(width: width, height: height)
    }
}
