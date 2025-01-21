import TUICore
import UIKit

class TUIMergeReplyQuoteView: TUIReplyQuoteView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "title"
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = UIColor.d_systemGray()
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)

        guard let myData = data as? TUIMergeReplyQuoteViewData else {
            return
        }

        titleLabel.text = myData.title

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self.titleLabel.font.lineHeight)
        }
    }

    override func reset() {
        super.reset()
        titleLabel.text = ""
    }
}
