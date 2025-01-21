import TIMCommon
import TUICore
import UIKit

class TUICommonContactCell: TUICommonTableViewCell {
    let avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
    let titleLabel = UILabel()
    let onlineStatusIcon = UIImageView()
    var contactData: TUICommonContactCellData?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        
        contentView.addSubview(onlineStatusIcon)
        
        selectionStyle = .none
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        
        guard let contactData = data as? TUICommonContactCellData else { return }
        self.contactData = contactData
        
        titleLabel.text = contactData.title
        avatarView.sd_setImage(with: contactData.avatarUrl, placeholderImage: contactData.avatarImage ?? TUISwift.defaultAvatarImage())
        
        TUISwift.racObserveTUIConfig_displayOnlineStatusIcon(self) { [weak self] _ in
            guard let self = self else { return }
            if contactData.onlineStatus == .online && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = false
                self.onlineStatusIcon.image = TUISwift.timCommonDynamicImage("icon_online_status", defaultImage: UIImage(named: TUISwift.timCommonImagePath("icon_online_status")))
            } else if contactData.onlineStatus == .offline && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = false
                self.onlineStatusIcon.image = TUISwift.timCommonDynamicImage("icon_offline_status", defaultImage: UIImage(named: TUISwift.timCommonImagePath("icon_offline_status")))
            } else {
                self.onlineStatusIcon.isHidden = true
                self.onlineStatusIcon.image = nil
            }
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
        
        onlineStatusIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale375(15))
            make.trailing.equalTo(avatarView.snp.trailing).offset(TUISwift.kScale375(5))
            make.bottom.equalTo(avatarView.snp.bottom)
        }
        onlineStatusIcon.layer.cornerRadius = 0.5 * TUISwift.kScale375(15)
    }
}
