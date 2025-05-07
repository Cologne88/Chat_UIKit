//  TUICommonContactSelectCell_Minimalist.swift
//  TUIContact

import TIMCommon

class TUICommonContactSelectCellData_Minimalist: TUICommonContactSelectCellData {
    // No additional properties or methods
}

class TUICommonContactSelectCell_Minimalist: TUICommonTableViewCell {
    let selectButton: UIButton
    let avatarView: UIImageView
    let titleLabel: UILabel

    private(set) var selectData: TUICommonContactSelectCellData_Minimalist?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        selectButton = UIButton(type: .custom)
        avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
        titleLabel = UILabel(frame: .zero)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(selectButton)
        selectButton.setImage(UIImage.safeImage(TUISwift.timCommonImagePath("icon_select_normal")), for: .normal)
        selectButton.setImage(UIImage.safeImage(TUISwift.timCommonImagePath("icon_select_pressed")), for: .highlighted)
        selectButton.setImage(UIImage.safeImage(TUISwift.timCommonImagePath("icon_select_selected")), for: .selected)
        selectButton.setImage(UIImage.safeImage(TUISwift.timCommonImagePath("icon_select_selected_disable")), for: .disabled)
        selectButton.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        contentView.addSubview(avatarView)
        avatarView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        contentView.addSubview(titleLabel)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        let imgWidth = TUISwift.kScale390(34)

        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView.snp.centerY)
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
            make.centerY.equalTo(avatarView.snp.centerY)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.greaterThanOrEqualTo(contentView.snp.trailing)
        }

        selectButton.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView.snp.centerY)
            make.trailing.equalTo(contentView.snp.trailing).offset(-TUISwift.kScale390(20))
            make.width.height.equalTo(20)
        }

        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func fill(with selectData: TUICommonCellData) {
        guard let selectData = selectData as? TUICommonContactSelectCellData_Minimalist else { return }

        super.fill(with: selectData)
        self.selectData = selectData
        titleLabel.text = selectData.title
        if let nsurl = selectData.avatarUrl as NSURL?, let avatarUrl = nsurl as URL? {
            avatarView.sd_setImage(with: avatarUrl, placeholderImage: TUISwift.defaultAvatarImage())
        } else {
            if let avatarImage = selectData.avatarImage as UIImage? {
                avatarView.image = avatarImage
            } else {
                avatarView.image = TUISwift.defaultAvatarImage()
            }
        }
        selectButton.isSelected = selectData.isSelected
        selectButton.isEnabled = selectData.isEnabled

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
}
