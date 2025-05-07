import TIMCommon
import TUICore
import UIKit

class TUIFoldConversationListDataProvider: TUIFoldConversationListBaseDataProvider {
    override func getConversationCellClass() -> AnyClass {
        return TUIConversationCellData.self
    }

    override func getDisplayStringFromService(_ msg: V2TIMMessage) -> String {
        let param: [String: Any] = ["msg": msg]
        return TUICore.callService("TUICore_TUIChatService", method: "TUICore_TUIChatService_GetDisplayStringMethod", param: param) as? String ?? ""
    }

    override func getLastDisplayString(_ conv: V2TIMConversation) -> NSMutableAttributedString {
        // If has group-at message, the group-at information will be displayed first
        let atStr = getGroupAtTipString(conv)
        let attributeString = NSMutableAttributedString(string: atStr)
        let attributeDict: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.d_systemRed()]
        attributeString.setAttributes(attributeDict, range: NSRange(location: 0, length: attributeString.length))

        // If there is a draft box, the draft box information will be displayed first
        if let draftText = conv.draftText, !draftText.isEmpty {
            let draft = NSAttributedString(string: TUISwift.timCommonLocalizableString("TUIKitMessageTypeDraftFormat"), attributes: [.foregroundColor: TUISwift.rgb(250, g: 81, b: 81)])
            attributeString.append(draft)

            if let draftContentStr = getDraftContent(conv) {
                var emojiLocations: [[NSValue : NSAttributedString]]? = [[NSValue: NSAttributedString]]()
                let draftContent = draftContentStr.getAdvancedFormatEmojiString(withFont: UIFont.systemFont(ofSize: 16.0), textColor: TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000"), emojiLocations: &emojiLocations);
                attributeString.append(draftContent)
            }
        } else {
            // No drafts, show conversation lastMsg information
            var lastMsgStr = ""

            // Attempt to get externally customized display information
            lastMsgStr = delegate?.getConversationDisplayString(conv) ?? ""

            // If there is no external customization, get the lastMsg display information through the message module
            if lastMsgStr.isEmpty && conv.lastMessage != nil {
                let param: [String: Any] = ["msg": conv.lastMessage!]
                lastMsgStr = TUICore.callService("TUICore_TUIChatService", method: "TUICore_TUIChatService_GetDisplayStringMethod", param: param) as? String ?? ""
            }

            // If there is no lastMsg display information and no draft information, return nil directly
            if lastMsgStr.isEmpty {
                return NSMutableAttributedString()
            }
            attributeString.append(NSAttributedString(string: lastMsgStr))
        }

        // If do-not-disturb is set, the message do-not-disturb state is displayed
        if isConversationNotDisturb(conv) && conv.unreadCount > 0 {
            let unreadString = NSAttributedString(string: String(format: "[%d %@] ", conv.unreadCount, TUISwift.timCommonLocalizableString("TUIKitMessageTypeLastMsgCountFormat")))
            attributeString.insert(unreadString, at: 0)
        }

        // If the status of the lastMsg of the conversation is sending or failed, display the sending status of the message (the draft box does not need to display the sending status)
        if (conv.draftText == nil || conv.draftText!.isEmpty) && (conv.lastMessage?.status == .MSG_STATUS_SENDING || conv.lastMessage?.status == .MSG_STATUS_SEND_FAIL) {
            let textFont = UIFont.systemFont(ofSize: 14)
            let spaceString = NSAttributedString(string: " ", attributes: [.font: textFont])
            let attchment = NSTextAttachment()
            let image: UIImage?
            if conv.lastMessage?.status == .MSG_STATUS_SENDING {
                image = TUISwift.tuiConversationCommonBundleImage("msg_sending_for_conv")
            } else {
                image = TUISwift.tuiConversationCommonBundleImage("msg_error_for_conv")
            }
            attchment.image = image
            attchment.bounds = CGRect(x: 0, y: -(textFont.lineHeight - textFont.pointSize) / 2, width: textFont.pointSize, height: textFont.pointSize)
            let imageString = NSAttributedString(attachment: attchment)
            attributeString.insert(spaceString, at: 0)
            attributeString.insert(imageString, at: 0)
        }
        return attributeString
    }
}
