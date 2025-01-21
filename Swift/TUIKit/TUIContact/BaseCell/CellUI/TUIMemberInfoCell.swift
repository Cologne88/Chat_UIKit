import TIMCommon
import UIKit

class TUIMemberTagView: UIView {
    let tagname: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor.tui_color(withHex: "#1890FF")
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale390(10))
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.tui_color(withHex: "#E7F3FC")
        layer.borderWidth = TUISwift.kScale390(1)
        layer.cornerRadius = TUISwift.kScale390(3)
        layer.borderColor = UIColor.tui_color(withHex: "#1890FF").cgColor
        addSubview(tagname)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tagname.sizeToFit()
        tagname.frame = CGRect(x: TUISwift.kScale390(8), y: 0, width: tagname.frame.size.width, height: frame.size.height)
    }
}

class TUIMemberInfoCell: UITableViewCell {
    let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale375(18.0))
        label.textColor = UIColor(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0, alpha: 1.0)
        return label
    }()

    let tagView = TUIMemberTagView()
    
    var data: TUIMemberInfoCellData? {
        didSet {
            guard let data = data else { return }
            let defaultImage = TUISwift.defaultAvatarImage()
            avatarImageView.sd_setImage(with: URL(string: data.avatarUrl ?? ""), placeholderImage: data.avatar ?? defaultImage)
            nameLabel.text = data.name
            tagView.isHidden = false
            
            if data.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue {
                tagView.tagname.text = TUISwift.timCommonLocalizableString("TUIKitMembersRoleSuper")
            } else if data.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue {
                tagView.tagname.text = TUISwift.timCommonLocalizableString("TUIKitMembersRoleAdmin")
            } else {
                tagView.tagname.text = ""
                tagView.isHidden = true
            }
            
            accessoryType = data.showAccessory ? .disclosureIndicator : .none
            
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(tagView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        if data?.style == TUIMemberInfoCellStyle.add {
            avatarImageView.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leading).offset(TUISwift.kScale375(18.0))
                make.centerY.equalTo(contentView)
                make.width.height.equalTo(TUISwift.kScale375(20.0))
            }
            nameLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale375(16.0))
            nameLabel.textColor = TUISwift.timCommonDynamicColor("form_value_text_color", defaultColor: "#000000")
        } else {
            avatarImageView.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leading).offset(TUISwift.kScale375(16.0))
                make.centerY.equalTo(contentView)
                make.width.height.equalTo(TUISwift.kScale375(34.0))
            }
            nameLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale375(16.0))
            nameLabel.textColor = TUISwift.timCommonDynamicColor("form_value_text_color", defaultColor: "#000000")
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.layer.cornerRadius = avatarImageView.frame.size.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        nameLabel.sizeToFit()
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(14)
            make.centerY.equalTo(contentView)
            make.size.equalTo(nameLabel.frame.size)
            if tagView.tagname.text?.count ?? 0 > 0 {
                make.trailing.lessThanOrEqualTo(tagView.snp.trailing).offset(TUISwift.kScale375(-2.0))
            } else {
                make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(TUISwift.kScale375(-2.0))
            }
        }
        
        tagView.tagname.sizeToFit()
        tagView.snp.remakeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(TUISwift.kScale390(10))
            make.width.equalTo(tagView.tagname.frame.size.width + TUISwift.kScale390(16))
            make.height.equalTo(TUISwift.kScale390(15))
            make.centerY.equalTo(contentView.snp.centerY)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(TUISwift.kScale375(-2.0))
        }
    }
}
