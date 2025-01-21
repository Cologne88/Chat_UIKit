import TIMCommon
import UIKit

class TUICommonPendencyCell: TUICommonTableViewCell {
    let avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
    let titleLabel = UILabel()
    let addSourceLabel = UILabel()
    let addWordingLabel = UILabel()
    let agreeButton = UIButton(type: .system)
    let rejectButton = UIButton(type: .system)
    var stackView: UIStackView!
    
    var pendencyData: TUICommonPendencyCellData?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(avatarView)
        
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        contentView.addSubview(titleLabel)
        
        addSourceLabel.textColor = UIColor.d_systemGray()
        addSourceLabel.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(addSourceLabel)
        
        addWordingLabel.textColor = UIColor.d_systemGray()
        addWordingLabel.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(addWordingLabel)
        
        agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        agreeButton.addTarget(self, action: #selector(agreeClick), for: .touchUpInside)
        
        rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        rejectButton.addTarget(self, action: #selector(rejectClick), for: .touchUpInside)
        
        stackView = UIStackView(arrangedSubviews: [agreeButton, rejectButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.sizeToFit()
        accessoryView = stackView
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func fill(with pendencyData: TUICommonCellData) {
        guard let pendencyData = pendencyData as? TUICommonPendencyCellData else { return }

        super.fill(with: pendencyData)
        self.pendencyData = pendencyData
        titleLabel.text = pendencyData.title
        addSourceLabel.text = pendencyData.addSource
        addWordingLabel.text = pendencyData.addWording
        avatarView.image = TUISwift.defaultAvatarImage()
        if let avatarUrl = pendencyData.avatarUrl {
            avatarView.sd_setImage(with: avatarUrl)
        }
        
        if pendencyData.isAccepted {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agreed"), for: .normal)
            agreeButton.isEnabled = false
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
            agreeButton.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        } else {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agree"), for: .normal)
            agreeButton.isEnabled = true
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.layer.borderWidth = 1
            agreeButton.setTitleColor(.white, for: .normal)
            agreeButton.backgroundColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
        }
        
        if pendencyData.isRejected {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Disclined"), for: .normal)
            rejectButton.isEnabled = false
            rejectButton.layer.borderColor = UIColor.clear.cgColor
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        } else {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Discline"), for: .normal)
            rejectButton.isEnabled = true
            rejectButton.layer.borderColor = TUISwift.tuiDemoDynamicColor("separator_color", defaultColor: "#DBDBDB").cgColor
            rejectButton.layer.borderWidth = 0.2
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF"), for: .normal)
        }
        
        if pendencyData.isRejected && !pendencyData.isAccepted {
            agreeButton.isHidden = true
            rejectButton.isHidden = false
        } else if pendencyData.isAccepted && !pendencyData.isRejected {
            agreeButton.isHidden = false
            rejectButton.isHidden = true
        } else {
            agreeButton.isHidden = false
            rejectButton.isHidden = false
        }
        
        addSourceLabel.isHidden = pendencyData.hideSource
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        let headSize = CGSize(width: 70, height: 70)
        
        avatarView.snp.remakeConstraints { make in
            make.size.equalTo(headSize)
            make.leading.equalTo(12)
            make.centerY.equalTo(contentView)
        }
        
        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(14)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.width.equalTo(120)
        }
        
        addSourceLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel.snp.leading)
            make.height.equalTo(15)
            make.width.equalTo(120)
        }
        
        addWordingLabel.snp.remakeConstraints { make in
            make.top.equalTo(addSourceLabel.snp.bottom).offset(6)
            make.leading.equalTo(titleLabel.snp.leading)
            make.height.equalTo(15)
            make.width.equalTo(120)
        }
        
        agreeButton.sizeToFit()
        stackView.bounds = CGRect(x: 0, y: 0, width: 3 * agreeButton.frame.width + 10, height: agreeButton.frame.height)
        
        super.updateConstraints()
    }
    
    @objc func agreeClick() {
        if let selector = pendencyData?.cbuttonSelector, let vc = mm_viewController, vc.responds(to: selector) {
            vc.perform(selector, with: self)
        }
    }
    
    @objc func rejectClick() {
        if let selector = pendencyData?.cRejectButtonSelector, let vc = mm_viewController, vc.responds(to: selector) {
            vc.perform(selector, with: self)
        }
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == agreeButton || touch.view == rejectButton {
            return false
        }
        return true
    }
}
