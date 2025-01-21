import TIMCommon
import UIKit

class TUIFindContactCell: UITableViewCell {
    let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 3 * UIScreen.main.bounds.size.width / 375.0
        imageView.layer.masksToBounds = true
        return imageView
    }()

    let mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "mainTitle"
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        label.font = UIFont.systemFont(ofSize: 18.0 * UIScreen.main.bounds.size.width / 375.0)
        return label
    }()

    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "subTitle"
        label.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        label.font = UIFont.systemFont(ofSize: 13.0 * UIScreen.main.bounds.size.width / 375.0)
        return label
    }()

    let descLabel: UILabel = {
        let label = UILabel()
        label.text = "descLabel"
        label.textColor = TUISwift.timCommonDynamicColor("form_desc_color", defaultColor: "#888888")
        label.font = UIFont.systemFont(ofSize: 13.0 * UIScreen.main.bounds.size.width / 375.0)
        return label
    }()

    var data: TUIFindContactCellModel? {
        didSet {
            guard let data = data else { return }
            mainTitleLabel.text = data.mainTitle
            subTitleLabel.text = data.subTitle
            descLabel.text = data.desc
            let placeHolder = (data.type == TUIFindContactType.c2c) ? TUISwift.defaultAvatarImage() : TUISwift.defaultGroupAvatarImage(byGroupType: data.groupInfo?.groupType)
            avatarView.sd_setImage(with: data.avatarUrl, placeholderImage: data.avatar ?? placeHolder)
            descLabel.isHidden = (data.type == TUIFindContactType.c2c)
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
        let imgWidth = TUISwift.kScale390(48)
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
            make.height.equalTo(20)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }
        subTitleLabel.sizeToFit()
        subTitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(2)
            make.leading.equalTo(mainTitleLabel.snp.leading)
            make.height.equalTo(subTitleLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }
        descLabel.sizeToFit()
        descLabel.snp.remakeConstraints { make in
            make.top.equalTo(subTitleLabel.snp.bottom).offset(2)
            make.leading.equalTo(mainTitleLabel.snp.leading)
            make.height.equalTo(subTitleLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(12))
        }
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
