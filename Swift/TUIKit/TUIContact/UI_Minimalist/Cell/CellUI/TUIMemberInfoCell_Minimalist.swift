// TUIMemberInfoCell_Minimalist.swift
// TUIContact

import UIKit
import TIMCommon
import TUICore

let kScale = UIScreen.main.bounds.size.width / 375.0

class TUIMemberInfoCell_Minimalist: UITableViewCell {
    var data: TUIMemberInfoCellData_Minimalist?
    
    var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18.0 * kScale)
        label.textColor = UIColor(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0, alpha: 1.0)
        return label
    }()
    
    func setData(_ data: TUIMemberInfoCellData_Minimalist) {
        self.data = data
        let defaultImage = TUISwift.defaultAvatarImage()
        avatarImageView.sd_setImage(with: URL(string: data.avatarUrl ?? ""), placeholderImage: data.avatar ?? defaultImage)
        nameLabel.text = data.name
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        var imgWidth: CGFloat = TUISwift.kScale390(20)
        if data?.style == .add {
            imgWidth = 20.0 * kScale
            avatarImageView.snp.remakeConstraints { make in
                make.width.height.equalTo(20.0 * kScale)
                make.leading.equalTo(TUISwift.kScale390(18))
                make.centerY.equalTo(contentView.snp.centerY)
            }
            nameLabel.font = UIFont.systemFont(ofSize: 16.0 * kScale)
            nameLabel.textColor = UIColor.tui_color(withHex: "#147AFF")
        } else {
            imgWidth = 34.0 * kScale
            avatarImageView.snp.remakeConstraints { make in
                make.width.height.equalTo(34.0 * kScale)
                make.leading.equalTo(TUISwift.kScale390(16))
                make.centerY.equalTo(contentView.snp.centerY)
            }
            nameLabel.font = UIFont.systemFont(ofSize: 16.0 * kScale)
            nameLabel.textColor = TUISwift.timCommonDynamicColor("form_value_text_color", defaultColor: "#000000")
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarImageView.layer.masksToBounds = true
            avatarImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        nameLabel.sizeToFit()
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(14)
            make.centerY.equalTo(contentView)
            make.size.equalTo(nameLabel.frame.size)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-2.0 * kScale)
        }
    }
}
