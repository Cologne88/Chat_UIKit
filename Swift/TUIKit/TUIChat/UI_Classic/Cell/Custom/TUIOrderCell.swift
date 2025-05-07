import TIMCommon
import UIKit

class TUIOrderCell: TUIBubbleMessageCell {
    var customData: TUIOrderCellData?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_text_message_receive_text_color", defaultColor: "#000000")
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = TUISwift.tuiChatDynamicColor("chat_custom_order_message_desc_color", defaultColor: "#999999")
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = TUISwift.tuiChatDynamicColor("chat_custom_order_message_price_color", defaultColor: "#FF7201")
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8.0
        imageView.layer.masksToBounds = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(priceLabel)
        container.addSubview(iconView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        if let data = data as? TUIOrderCellData {
            customData = data
            titleLabel.text = data.title
            descLabel.text = data.desc
            priceLabel.text = data.price
            if let imageUrl = data.imageUrl {
                iconView.image = UIImage.safeImage(imageUrl)
            } else {
                iconView.image = TUISwift.tuiChatBundleThemeImage("chat_custom_order_message_img", defaultImage: "message_custom_order")
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
        iconView.snp.remakeConstraints { make in
            make.top.equalTo(10)
            make.leading.equalTo(12)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(10)
            make.leading.equalTo(80)
            make.width.equalTo(150)
            make.height.equalTo(17)
        }
        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(30)
            make.leading.equalTo(80)
            make.width.equalTo(150)
            make.height.equalTo(17)
        }
        priceLabel.snp.remakeConstraints { make in
            make.top.equalTo(49)
            make.leading.equalTo(80)
            make.width.equalTo(150)
            make.height.equalTo(25)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        return CGSize(width: 245, height: 80)
    }
}
