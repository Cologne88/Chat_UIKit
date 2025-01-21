// TUIGroupMemberTableViewCell_Minimalist.swift
// TUIContact

import TIMCommon
import TUICore

class TUIGroupMemberTableViewCell_Minimalist: TUICommonTableViewCell {
    let avatarView: UIImageView
    let titleLabel: UILabel
    let detailLabel: UILabel
    let separtorView: UIView
    var tapAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
        titleLabel = UILabel(frame: .zero)
        detailLabel = UILabel(frame: .zero)
        separtorView = UIView()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#FFFFFF")
        contentView.addSubview(avatarView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("", defaultColor: "#000000")
        contentView.addSubview(titleLabel)
        
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = TUISwift.timCommonDynamicColor("", defaultColor: "#666666")
        contentView.addSubview(detailLabel)
        
        separtorView.backgroundColor = UIColor.white
        contentView.addSubview(separtorView)
        
        selectionStyle = .none
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        tapAction?()
    }
    
    override func fill(with contactData: TUICommonCellData) {
        guard let contactData = contactData as? TUIGroupMemberCellData_Minimalist else { return }

        super.fill(with: contactData)
        
        titleLabel.text = contactData.name
        
        avatarView.sd_setImage(with: URL(string: contactData.avatarUrl ?? ""), placeholderImage: contactData.avatarImage ?? TUISwift.defaultAvatarImage())
        
        detailLabel.text = contactData.detailName
        
        if contactData.showAccessory {
            accessoryType = .disclosureIndicator
            isUserInteractionEnabled = true
        } else {
            accessoryType = .none
            isUserInteractionEnabled = false
        }
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let imgWidth = TUISwift.kScale390(40)
        
        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(TUISwift.kScale390(16))
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(1)
        }
        
        detailLabel.sizeToFit()
        detailLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.height.equalTo(detailLabel.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-TUISwift.kScale390(16))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
