import SnapKit
import TIMCommon
import UIKit

class TUISearchResultHeaderFooterView: UITableViewHeaderFooterView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let accessoryView = UIImageView()
    private let separatorView = UIView()
    
    var isFooter: Bool = false {
        didSet {
            iconView.isHidden = !isFooter
            accessoryView.isHidden = !isFooter
            let footerColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
            titleLabel.textColor = isFooter ? footerColor : .darkGray
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
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
        
        titleLabel.text = ""
        titleLabel.font = UIFont.systemFont(ofSize: 12.0)
        titleLabel.rtlAlignment = TUITextRTLAlignment.leading
        contentView.addSubview(titleLabel)
        
        accessoryView.image = UIImage.safeImage(TUISwift.tuiSearchImagePath("right")).rtlImageFlippedForRightToLeftLayoutDirection()
        contentView.addSubview(accessoryView)
        
        separatorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        contentView.addSubview(separatorView)
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
                make.height.width.equalTo(20)
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
                make.leading.equalTo(iconView).offset(10)
                make.centerY.equalTo(contentView)
                make.width.equalTo(titleLabel.frame.size.width)
                make.height.equalTo(titleLabel.font.lineHeight)
            }
            
            accessoryView.snp.remakeConstraints { make in
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
                make.bottom.equalTo(contentView)
                make.width.equalTo(contentView)
                make.height.equalTo(1)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leading).offset(10)
                make.centerY.equalTo(contentView)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.equalTo(titleLabel.font.lineHeight)
            }
            
            separatorView.snp.remakeConstraints { make in
                make.leading.equalTo(10)
                make.bottom.equalTo(contentView).offset(-1)
                make.width.equalTo(contentView)
                make.height.equalTo(1)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setFrame(_ frame: CGRect) {
        var newFrame = frame
        if isFooter {
            newFrame.size.height -= 10
        }
        super.frame = newFrame
    }
}
