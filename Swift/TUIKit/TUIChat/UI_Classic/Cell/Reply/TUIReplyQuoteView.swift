import UIKit

public class TUIReplyQuoteView: UIView {
    public var data: TUIReplyQuoteViewData?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func fill(with data: TUIReplyQuoteViewData) {
        self.data = data
    }

    public func reset() {}
}
