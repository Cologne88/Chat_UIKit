import TIMCommon
import TUICore
import UIKit

class TUITextReplyQuoteView: TUIReplyQuoteView {
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
        
        let showRevokeStr = myData.originCellData?.innerMessage.status == .MSG_STATUS_LOCAL_REVOKED && !data.showRevokedOriginMessage
        if showRevokeStr {
            let revokeStr = data.supportForReply ? TUISwift.timCommonLocalizableString("TUIKitRepliesOriginMessageRevoke") : TUISwift.timCommonLocalizableString("TUIKitReferenceOriginMessageRevoke")
            textLabel.attributedText = revokeStr!.getFormatEmojiString(with: textLabel.font, emojiLocations: nil)
        } else {
            textLabel.attributedText = myData.text.getFormatEmojiString(with: textLabel.font, emojiLocations: nil)
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override func reset() {
        textLabel.text = ""
    }
}
