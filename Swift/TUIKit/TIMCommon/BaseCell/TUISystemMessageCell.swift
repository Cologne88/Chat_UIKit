import SnapKit
import UIKit

open class TUISystemMessageCell: TUIMessageCell {
    public private(set) var messageLabel: UILabel = .init()
    public private(set) var systemData: TUISystemMessageCellData?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupMessageLabel()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMessageLabel() {
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.backgroundColor = .clear
        messageLabel.layer.cornerRadius = 3
        messageLabel.layer.masksToBounds = true
        container.addSubview(messageLabel)
    }

    override open class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override open func updateConstraints() {
        super.updateConstraints()

        container.snp.remakeConstraints { make in
            make.center.equalTo(contentView)
            make.size.equalTo(contentView)
        }

        messageLabel.sizeToFit()
        if messageLabel.superview != nil {
            messageLabel.snp.remakeConstraints { make in
                make.center.equalTo(container)
                make.leading.trailing.equalTo(self.container);
            }
        }
    }

    override open func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUISystemMessageCellData else { return }
        systemData = data

        messageLabel.textColor = TUISystemMessageCellData.textColor ?? data.contentColor
        messageLabel.font = TUISystemMessageCellData.textFont ?? data.contentFont
        messageLabel.backgroundColor = TUISystemMessageCellData.textBackgroundColor ?? .clear
        messageLabel.attributedText = data.attributedString

        nameLabel.isHidden = true
        avatarView.isHidden = true
        retryView.isHidden = true
        indicator.stopAnimating()

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    // MARK: - TUIMessageCellProtocol

    override open class func getEstimatedHeight(_ data: TUIMessageCellData) -> CGFloat {
        return 42.0
    }

    override open class func getHeight(_ data: TUIMessageCellData, withWidth width: CGFloat) -> CGFloat {
        return getContentSize(data).height + TUISwift.kScale390(16)
    }

    override open class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let systemCellData = data as? TUISystemMessageCellData else { return .zero }

        var maxSystemSize = CGSize(width: TUISwift.screen_Width(), height: CGFloat(Int.max))
        var size = CGSizeZero
        if let font = systemCellData.contentFont {
            size = systemCellData.attributedString?.string.textSize(in: maxSystemSize, font: font) ?? CGSizeZero
        }
        return CGSize(width: size.width + 16, height: size.height + 10)
    }
}
