import TIMCommon
import TUICore
import UIKit

class TUITextReplyQuoteView_Minimalist: TUIReplyQuoteView_Minimalist {
    let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_reply_message_sender_text_color", defaultColor: "#888888")
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textLabel)
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        textLabel.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)
        guard let myData = data as? TUITextReplyQuoteViewData else { return }
        let showRevokeStr = myData.originCellData?.innerMessage?.status == .MSG_STATUS_LOCAL_REVOKED && !data.showRevokedOriginMessage
        var locations: [[NSValue: NSAttributedString]]? = nil
        if showRevokeStr {
            let revokeStr = data.supportForReply ? TUISwift.timCommonLocalizableString("TUIKitRepliesOriginMessageRevoke") : TUISwift.timCommonLocalizableString("TUIKitReferenceOriginMessageRevoke")
            textLabel.attributedText = revokeStr.getFormatEmojiString(withFont: textLabel.font, emojiLocations: &locations)
        } else {
            textLabel.attributedText = myData.text.getFormatEmojiString(withFont: textLabel.font, emojiLocations: &locations)
        }

        if TUISwift.isRTL() {
            textLabel.textAlignment = .right
        } else {
            textLabel.textAlignment = .left
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override func reset() {
        textLabel.text = ""
    }
}
