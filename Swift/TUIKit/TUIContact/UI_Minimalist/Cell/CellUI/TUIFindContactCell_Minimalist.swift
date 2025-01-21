// TUIFindContactCell_Minimalist.swift
// TUIContact

import TIMCommon
import TUICore
import UIKit

class TUIFindContactCell_Minimalist: UITableViewCell {
    var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = TUISwift.kScale375(3)
        imageView.layer.masksToBounds = true
        return imageView
    }()

    var mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "mainTitle"
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        label.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(16))
        return label
    }()

    var subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "subTitle"
        label.textColor = UIColor.tui_color(withHex: "#104EF5")
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        return label
    }()

    var descLabel: UILabel = {
        let label = UILabel()
        label.text = "descLabel"
        label.textColor = TUISwift.timCommonDynamicColor("form_desc_color", defaultColor: "#888888")
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        return label
    }()

    var data: TUIFindContactCellModel_Minimalist? {
        didSet {
            guard let data = data else { return }
            mainTitleLabel.text = data.mainTitle
            subTitleLabel.attributedText = Self.attributeString(withText: "ID:\(data.subTitle ?? "")", key: data.subTitle ?? "")
            descLabel.text = data.desc
            let placeHolder = (data.type == .C2C_Minimalist) ? TUISwift.defaultAvatarImage() : TUISwift.defaultGroupAvatarImage(byGroupType: data.groupInfo?.groupType)
            avatarView.sd_setImage(with: data.avatarUrl, placeholderImage: data.avatar ?? placeHolder)
            descLabel.isHidden = (data.type == .C2C_Minimalist)
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(avatarView)
        contentView.addSubview(mainTitleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(descLabel)
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        let imgWidth = TUISwift.kScale390(43)
        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.top.equalTo(TUISwift.kScale390(10))
            make.leading.equalTo(TUISwift.kScale390(16))
        }
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        mainTitleLabel.sizeToFit()
        mainTitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(avatarView.snp.top)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(mainTitleLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }

        subTitleLabel.sizeToFit()
        subTitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(TUISwift.kScale390(4))
            make.leading.equalTo(mainTitleLabel.snp.leading)
            make.height.equalTo(subTitleLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }

        descLabel.sizeToFit()
        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(TUISwift.kScale390(4))
            make.leading.equalTo(mainTitleLabel.snp.leading)
            make.height.equalTo(subTitleLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    static func attributeString(withText text: String, key: String) -> NSAttributedString? {
        guard !text.isEmpty else { return nil }
        guard let keyRange = text.range(of: key, options: .caseInsensitive) else {
            return NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }

        let attributedString = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        attributedString.addAttribute(.foregroundColor, value: TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF"), range: NSRange(keyRange, in: text))
        return attributedString
    }
}
