import UIKit

class TUIReplyQuoteView_Minimalist: UIView {
    var data: TUIReplyQuoteViewData?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fill(with data: TUIReplyQuoteViewData) {
        self.data = data
    }

    func reset() {}
}
