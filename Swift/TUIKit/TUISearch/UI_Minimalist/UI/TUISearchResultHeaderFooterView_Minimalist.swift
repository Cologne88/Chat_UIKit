import SnapKit
import TIMCommon
import UIKit

class TUISearchResultHeaderFooterView_Minimalist: UITableViewHeaderFooterView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let moreBtn = UIButton(type: .custom)
    
    var isFooter: Bool = false {
        didSet {
            iconView.isHidden = !isFooter
            let footerColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
            titleLabel.textColor = isFooter ? footerColor : .darkGray
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    var showMoreBtn: Bool = false {
        didSet {
            moreBtn.isHidden = !showMoreBtn
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    var onTap: (() -> Void)?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        
        iconView.image = UIImage.safeImage(TUISwift.tuiSearchImagePath("search"))
        contentView.addSubview(iconView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        contentView.addSubview(titleLabel)
        
        moreBtn.setTitle(TUISwift.timCommonLocalizableString("More"), for: .normal)
        moreBtn.setTitleColor(.systemBlue, for: .normal)
        moreBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(12))
        moreBtn.isUserInteractionEnabled = false
        contentView.addSubview(moreBtn)
    }
    
    @objc private func tap() {
        onTap?()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        if isFooter {
            iconView.snp.remakeConstraints { make in
                make.centerY.equalTo(contentView)
                make.size.equalTo(20)
                if TUISwift.isRTL() {
                    make.right.equalTo(contentView).offset(-10)
                } else {
                    make.left.equalTo(contentView).offset(10)
                }
            }
            
            titleLabel.sizeToFit()
            titleLabel.snp.remakeConstraints { make in
                if TUISwift.isRTL() {
                    make.right.equalTo(iconView.snp.left).offset(-10)
                } else {
                    make.left.equalTo(iconView.snp.right).offset(10)
                }
                make.centerY.equalTo(contentView)
                make.width.equalTo(titleLabel.frame.width)
                make.height.equalTo(titleLabel.font.lineHeight)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                if TUISwift.isRTL() {
                    make.left.equalTo(moreBtn.snp.right).offset(TUISwift.kScale390(16))
                    make.right.equalTo(contentView).offset(-TUISwift.kScale390(16))
                } else {
                    make.left.equalTo(contentView).offset(TUISwift.kScale390(16))
                    make.right.equalTo(moreBtn.snp.left).offset(-TUISwift.kScale390(16))
                }
                make.centerY.equalTo(contentView)
                make.height.equalTo(titleLabel.font.lineHeight)
            }
            
            moreBtn.sizeToFit()
            moreBtn.snp.remakeConstraints { make in
                if TUISwift.isRTL() {
                    make.left.equalTo(contentView).offset(TUISwift.kScale390(10))
                } else {
                    make.right.equalTo(contentView).offset(-TUISwift.kScale390(10))
                }
                make.centerY.equalTo(contentView)
                make.size.equalTo(moreBtn.frame.size)
            }
        }
    }
}

class TUISearchChatHistoryResultHeaderView_Minimalist: UITableViewHeaderFooterView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let rowAccessoryView = UIImageView()
    private let separatorView = UIView()
    
    var title: String? {
        didSet {
            titleLabel.text = title
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    var onTap: (() -> Void)?
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        
        iconView.image = UIImage.safeImage(TUISwift.tuiSearchImagePath("search"))
        contentView.addSubview(iconView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        contentView.addSubview(titleLabel)
        
        rowAccessoryView.image = UIImage.safeImage(TUISwift.tuiSearchImagePath("right")).imageFlippedForRightToLeftLayoutDirection()
        contentView.addSubview(rowAccessoryView)
        
        separatorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        contentView.addSubview(separatorView)
    }
    
    @objc private func tap() {
        onTap?()
    }
    
    func configPlaceHolderImage(_ img: UIImage, imgUrl: String, text: String) {
        iconView.sd_setImage(with: URL(string: imgUrl), placeholderImage: img)
        titleLabel.text = text
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
        iconView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.size.equalTo(imgWidth)
            if TUISwift.isRTL() {
                make.right.equalTo(contentView).offset(-TUISwift.kScale390(16))
            } else {
                make.left.equalTo(contentView).offset(TUISwift.kScale390(16))
            }
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            iconView.layer.masksToBounds = true
            iconView.layer.cornerRadius = imgWidth / 2.0
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            iconView.layer.masksToBounds = true
            iconView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            if TUISwift.isRTL() {
                make.right.equalTo(iconView.snp.left).offset(-TUISwift.kScale390(8))
            } else {
                make.left.equalTo(iconView.snp.right).offset(TUISwift.kScale390(8))
            }
            make.centerY.equalTo(contentView)
            make.width.equalTo(titleLabel.frame.width)
            make.height.equalTo(titleLabel.frame.height)
        }
        
        rowAccessoryView.snp.remakeConstraints { make in
            make.size.equalTo(10)
            make.centerY.equalTo(contentView)
            if TUISwift.isRTL() {
                make.left.equalTo(contentView).offset(10)
            } else {
                make.right.equalTo(contentView).offset(-10)
            }
        }
        
        separatorView.snp.remakeConstraints { make in
            make.leading.equalTo(10)
            make.bottom.equalTo(contentView).offset(-1)
            make.width.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
}
