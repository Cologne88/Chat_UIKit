import TIMCommon
import TUICore

class TUILinkCell: TUIBubbleMessageCell {
    var myTextLabel: UILabel!
    var myLinkLabel: UILabel!
    var customData: TUILinkCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
        myTextLabel = UILabel()
        myTextLabel.numberOfLines = 0
        myTextLabel.font = UIFont.systemFont(ofSize: 15)
        myTextLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        myTextLabel.textColor = TUISwift.tuiChatDynamicColor("chat_link_message_title_color", defaultColor: "#000000")
        container.addSubview(myTextLabel)

        myLinkLabel = UILabel()
        myLinkLabel.text = TUISwift.timCommonLocalizableString("TUIKitMoreLinkDetails")
        myLinkLabel.font = UIFont.systemFont(ofSize: 15)
        myLinkLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        myLinkLabel.textColor = TUISwift.tuiChatDynamicColor("chat_link_message_subtitle_color", defaultColor: "#0000FF")
        container.addSubview(myLinkLabel)
    }

    override func fill(with data: TUIBubbleMessageCellData) {
        super.fill(with: data)
        if let data = data as? TUILinkCellData {
            customData = data
            myTextLabel.text = data.text

            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    // this is Apple's recommended place for adding/updating constraints
    override func updateConstraints() {
        super.updateConstraints()
        guard let text = myTextLabel.text else { return }
        let font = UIFont.systemFont(ofSize: 15)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let maxSize = CGSize(width: 245, height: Int.max)
        let rect = text.boundingRect(with: maxSize,
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     attributes: attributes,
                                     context: nil)
        myTextLabel.snp.remakeConstraints { make in
            make.top.equalTo(10)
            make.leading.equalTo(10)
            make.width.equalTo(245)
            make.height.equalTo(rect.size.height)
        }
        myLinkLabel.sizeToFit()
        myLinkLabel.snp.remakeConstraints { make in
            make.top.equalTo(myTextLabel.snp.bottom).offset(15)
            make.leading.equalTo(10)
            make.width.equalTo(myLinkLabel.frame.size.width)
            make.height.equalTo(myLinkLabel.frame.size.height)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - TUIMessageCellProtocol

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let linkCellData = data as? TUILinkCellData else {
            assertionFailure("data must be kind of TUILinkCellData")
            return .zero
        }

        let textMaxWidth = 245
        let font = UIFont.systemFont(ofSize: 15)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        var size = CGSize(width: textMaxWidth, height: Int.max)

        let rect = linkCellData.text.boundingRect(with: size,
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                  attributes: attributes,
                                                  context: nil)
        size = CGSize(width: textMaxWidth + 15, height: Int(rect.size.height) + 56)
        return size
    }
}
