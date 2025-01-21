import TIMCommon

class TUIMemberCell: TUICommonTableViewCell {
    private var cellData: TUIMemberCellData?

    private let avatarView: UIImageView = {
        let imageView = UIImageView(image: defaultAvatarImage)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel(frame: CGRectMake(0, 0, 100, 20))
        label.rtlAlignment = .trailing
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")

        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        detailLabel.mm__centerY()(avatarView.mm_centerY)

        selectionStyle = .none
        changeColorWhenTouched = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with cellData: TUICommonCellData) {
        super.fill(with: cellData)
        guard let cellData = cellData as? TUIMemberCellData else {
            assertionFailure("data must be kind of TUIMemberCell_Minimalist")
            return
        }

        titleLabel.text = cellData.title
        avatarView.sd_setImage(with: cellData.avatarUrl, placeholderImage: defaultAvatarImage)
        detailLabel.isHidden = cellData.detail?.count == 0
        detailLabel.text = cellData.detail

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        let imgWidth = TUISwift.kScale390(34)

        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(TUISwift.kScale390(12))
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.lessThanOrEqualTo(detailLabel.snp.leading).offset(-5)
        }

        detailLabel.sizeToFit()
        detailLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.height.equalTo(20)
            make.trailing.equalTo(contentView).offset(-3)
            make.width.equalTo(detailLabel.frame.size.width)
        }
    }
}
