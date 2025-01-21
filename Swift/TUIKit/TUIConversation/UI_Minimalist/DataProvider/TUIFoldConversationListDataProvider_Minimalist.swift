import TIMCommon
import TUICore
import UIKit

class TUIFoldConversationListDataProvider_Minimalist: TUIFoldConversationListBaseDataProvider {
    override func getConversationCellClass() -> AnyClass {
        return TUIConversationCellData_Minimalist.self
    }
    
    override func getDisplayStringFromService(_ msg: V2TIMMessage) -> String {
        let param: [String: Any] = [TUICore_TUIChatService_GetDisplayStringMethod_MsgKey: msg]
        return TUICore.callService(TUICore_TUIChatService_Minimalist, method: TUICore_TUIChatService_GetDisplayStringMethod, param: param) as? String ?? ""
    }
    
    override func getLastDisplayString(_ conversation: V2TIMConversation) -> NSMutableAttributedString {
        /**
         * If has group-at message, the group-at information will be displayed first
         */
        let atStr = getGroupAtTipString(conversation)
        let attributeString = NSMutableAttributedString(string: atStr)
        let attributeDict: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.d_systemRed()]
        attributeString.setAttributes(attributeDict, range: NSRange(location: 0, length: attributeString.length))
        
        /**
         * If there is a draft box, the draft box information will be displayed first
         */
        if let _ = conversation.draftText {
            let draft = NSAttributedString(string: TUISwift.timCommonLocalizableString("TUIKitMessageTypeDraftFormat"), attributes: [.foregroundColor: TUISwift.rgb(250, green: 81, blue: 81)])
            attributeString.append(draft)
            
            if let draftContentStr = getDraftContent(conversation) {
                let draftContent = NSAttributedString(string: draftContentStr.getLocalizableStringWithFaceContent(), attributes: [.foregroundColor: UIColor.d_systemGray()])
                attributeString.append(draftContent)
            }
        } else {
            /**
             * No drafts, show conversation lastMsg information
             */
            var lastMsgStr = ""
            
            /**
             * Attempt to get externally customized display information
             */
            if let delegate = delegate, delegate.responds(to: #selector(TUIConversationListDataProviderDelegate.getConversationDisplayString(_:))) {
                lastMsgStr = delegate.getConversationDisplayString!(conversation) ?? ""
            }
            
            /**
             * If there is no external customization, get the lastMsg display information through the message module
             */
            if lastMsgStr.isEmpty , let lastMessage = conversation.lastMessage {
                lastMsgStr = self.getDisplayStringFromService(lastMessage)
            }
            
            /**
             * If there is no lastMsg display information and no draft information, return nil directly
             */
            if lastMsgStr.isEmpty {
                return NSMutableAttributedString()
            }
            attributeString.append(NSAttributedString(string: lastMsgStr))
        }
        
        /**
         * If do-not-disturb is set, the message do-not-disturb state is displayed
         * The default state of the meeting type group is V2TIM_RECEIVE_NOT_NOTIFY_MESSAGE, and the UI does not process it.
         */
        if isConversationNotDisturb(conversation) && conversation.unreadCount > 0 {
            let unreadString = NSAttributedString(string: String(format: "[%d %@] ", conversation.unreadCount, TUISwift.timCommonLocalizableString("TUIKitMessageTypeLastMsgCountFormat")))
            attributeString.insert(unreadString, at: 0)
        }
        
        return attributeString
    }
}
