import Foundation
import ImSDK_Plus
import TIMCommon
import UIKit

class TUIReplyMessageCellData: TUIBubbleMessageCellData {
    var originMsgID: String?
    var msgAbstract: String?
    var sender: String?
    var faceURL: String?
    var originMsgType: V2TIMElemType = .ELEM_TYPE_NONE
    @objc dynamic var originMessage: V2TIMMessage?
    var originCellData: TUIMessageCellData?
    var quoteData: TUIReplyQuoteViewData?
    var showRevokedOriginMessage: Bool = false
    var content: String = ""
    var attributeString: NSAttributedString {
        return NSAttributedString(string: content)
    }

    var quoteSize: CGSize = .zero
    var senderSize: CGSize = .zero
    var quotePlaceholderSize: CGSize = .zero
    var replyContentSize: CGSize = .zero
    var onFinish: TUIReplyAsyncLoadFinish?
    var messageRootID: String? = ""
    var textColor: UIColor = .black
    var selectContent: String? = ""
    var emojiLocations: [[NSValue: NSAttributedString]] = []

    override init(direction: TMsgDirection) {
        super.init(direction: direction)
        if direction == .MsgDirectionIncoming {
            self.cellLayout = TUIMessageCellLayout.incommingTextMessage()
        } else {
            self.cellLayout = TUIMessageCellLayout.outgoingTextMessage()
        }
        self.emojiLocations = []
    }

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard message.cloudCustomData != nil else {
            return TUIReplyMessageCellData(direction: .MsgDirectionIncoming)
        }

        var replyData = TUIReplyMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        message.doThingsInContainsCloudCustom(of: .messageReply, callback: { isContains, obj in
            if isContains, let reply = obj as? [String: Any] {
                replyData.reuseId = TReplyMessageCell_ReuseId
                replyData.originMsgID = reply["messageID"] as? String
                replyData.msgAbstract = reply["messageAbstract"] as? String
                replyData.sender = reply["messageSender"] as? String
                replyData.originMsgType = V2TIMElemType(rawValue: reply["messageType"] as? Int ?? 0) ?? .ELEM_TYPE_NONE
                replyData.content = message.textElem?.text ?? ""
                replyData.messageRootID = reply["messageRootID"] as? String ?? ""
            }
        })

        return replyData
    }

    func quotePlaceholderSizeWithType(type: V2TIMElemType, data: TUIReplyQuoteViewData?) -> CGSize {
        guard let data = data else {
            return CGSize(width: 20, height: 20)
        }
        return data.contentSize(maxWidth: CGFloat(TReplyQuoteView_Max_Width) - 12)
    }

    func getQuoteData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        var quoteData: TUIReplyQuoteViewData? = nil
        if let classType = originCellData?.getReplyQuoteViewDataClass() {
            let hasRiskContent = originCellData?.innerMessage.hasRiskContent ?? false
            if hasRiskContent && TIMConfig.isClassicEntrance() {
                let myData = TUITextReplyQuoteViewData()
                myData.text = TUIReplyPreviewData.displayAbstract(type: originMsgType, abstract: msgAbstract ?? "", withFileName: false, isRisk: hasRiskContent)
                quoteData = myData
            } else if let classType = classType as? TUIReplyQuoteViewData.Type {
                quoteData = classType.getReplyQuoteViewData(originCellData: originCellData)
            }
        }
        if quoteData == nil {
            let myData = TUITextReplyQuoteViewData()
            myData.text = TUIReplyPreviewData.displayAbstract(type: originMsgType, abstract: msgAbstract ?? "", withFileName: false, isRisk: false)
            quoteData = myData
        }

        quoteData?.originCellData = originCellData
        quoteData?.onFinish = { [weak self] in
            self?.onFinish?()
        }
        return quoteData
    }
}

class TUIReferenceMessageCellData: TUIReplyMessageCellData {
    var textSize: CGSize = .zero
    var textOrigin: CGPoint = .zero

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard let cloudCustomData = message.cloudCustomData else {
            return TUIReferenceMessageCellData(direction: .MsgDirectionIncoming)
        }

        var replyData: TUIReplyMessageCellData = TUIReferenceMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        message.doThingsInContainsCloudCustom(of: .messageReference) { isContains, obj in
            if isContains, let reply = obj as? [String: Any] {
                replyData.reuseId = TUIReferenceMessageCell_ReuseId
                replyData.originMsgID = reply["messageID"] as? String
                replyData.msgAbstract = reply["messageAbstract"] as? String
                replyData.sender = reply["messageSender"] as? String
                replyData.originMsgType = V2TIMElemType(rawValue: reply["messageType"] as? Int ?? 0) ?? .ELEM_TYPE_NONE
                replyData.content = message.textElem?.text ?? ""
            }
        }

        return replyData
    }
}
