import UIKit

class TUIFileReplyQuoteView: TUIVoiceReplyQuoteView {
    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)
        guard let data = data as? TUIFileReplyQuoteViewData else {
            return
        }
        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byTruncatingMiddle
    }
}
