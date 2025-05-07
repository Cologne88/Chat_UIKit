import TIMCommon
import UIKit

class TUIEvaluationCell_Minimalist: TUIBubbleMessageCell_Minimalist {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = TUISwift.tuiChatDynamicColor("chat_text_message_receive_text_color", defaultColor: "#000000")
        return label
    }()

    private let commentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.textColor = TUISwift.tuiChatDynamicColor("chat_custom_evaluation_message_desc_color", defaultColor: "#000000")
        return label
    }()

    private var starImageArray: [UIImageView] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        container.addSubview(titleLabel)

        for _ in 0 ..< 5 {
            let imageView = UIImageView()
            imageView.image = TUISwift.tuiChatBundleThemeImage("chat_custom_evaluation_message_img", defaultImage: "message_custom_evaluation")
            container.addSubview(imageView)
            starImageArray.append(imageView)
        }

        container.addSubview(commentLabel)
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        if let data = data as? TUIEvaluationCellData {
            titleLabel.text = data.desc
            commentLabel.text = data.comment

            for (index, starView) in starImageArray.enumerated() {
                starView.isHidden = index >= data.score
            }

            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(10)
            make.leading.equalTo(10)
            make.width.equalTo(225)
            make.height.equalTo(18)
        }

        var leftView: UIImageView?
        for starView in starImageArray {
            if leftView == nil {
                starView.snp.remakeConstraints { make in
                    make.leading.equalTo(10)
                    make.top.equalTo(titleLabel.snp.bottom).offset(6)
                    make.width.equalTo(30)
                    make.height.equalTo(30)
                }
            } else {
                starView.snp.remakeConstraints { make in
                    make.leading.equalTo(leftView!)
                    make.top.equalTo(titleLabel.snp.bottom).offset(6)
                    make.width.equalTo(30)
                    make.height.equalTo(30)
                }
            }
            leftView = starView
        }

        guard let starView = starImageArray.first else { return }
        commentLabel.isHidden = commentLabel.text?.isEmpty ?? true
        if let commentText = commentLabel.text, !commentText.isEmpty {
            let font = UIFont.systemFont(ofSize: 15)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let maxSize = CGSize(width: 225, height: Int.max)
            if let commentLabelText = commentLabel.text {
                let rect = commentLabelText.boundingRect(with: maxSize,
                                                         options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                         attributes: attributes,
                                                         context: nil)
                let size = CGSize(width: 225, height: ceil(rect.size.height))
                commentLabel.snp.remakeConstraints { make in
                    make.top.equalTo(starView.snp.bottom).offset(6)
                    make.leading.equalTo(10)
                    make.width.equalTo(size.width)
                    make.height.equalTo(size.height)
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - TUIMessageCellProtocol

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let evaluationCellData = data as? TUIEvaluationCellData else {
            assertionFailure("data must be kind of TUIEvaluationCellData")
            return CGSize.zero
        }
        let font = UIFont.systemFont(ofSize: 15)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        var size = CGSize(width: 215, height: Int.max)
        let comment = evaluationCellData.comment
        let rect = comment.boundingRect(with: size,
                                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                                        attributes: attributes,
                                        context: nil)
        size = CGSize(width: 245, height: ceil(rect.size.height))
        size.height += evaluationCellData.comment.count > 0 ? 88 : 50
        return size
    }
}
