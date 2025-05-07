import SnapKit
import UIKit

open class TUIGroupButtonCell_Minimalist: TUICommonTableViewCell {
    var button: UIButton = .init(type: .custom)
    var buttonData: TUIGroupButtonCellData_Minimalist?
    private var line: UIView = .init()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        changeColorWhenTouched = true
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        contentView.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        contentView.addSubview(button)
        
        separatorInset = UIEdgeInsets(top: 0, left: TUISwift.screen_Width(), bottom: 0, right: 0)
        selectionStyle = .none
        changeColorWhenTouched = true
        
        line.backgroundColor = .white
        contentView.addSubview(line)
    }
    
    open override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUIGroupButtonCellData_Minimalist else { return }
        buttonData = data
        button.setTitle(data.title, for: .normal)
        button.contentHorizontalAlignment = TUISwift.isRTL() ? .right : .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        switch data.style {
        case .green:
            button.setTitleColor(TUISwift.timCommonDynamicColor("form_green_button_text_color", defaultColor: "#FFFFFF"), for: .normal)
            button.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
            button.setBackgroundImage(imageWithColor(TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")), for: .highlighted)
        case .white:
            button.setTitleColor(TUISwift.timCommonDynamicColor("form_white_button_text_color", defaultColor: "#000000"), for: .normal)
            button.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
        case .redText:
            button.setTitleColor(TUISwift.timCommonDynamicColor("form_redtext_button_text_color", defaultColor: "#FF0000"), for: .normal)
            button.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
        case .blue:
            if data.isInfoPageLeftButton {
                button.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#0365F9"), for: .normal)
                button.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
            } else {
                button.titleLabel?.textColor = UIColor.tui_color(withHex: "147AFF")
                button.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
                button.contentHorizontalAlignment = .center
                button.layer.cornerRadius = TUISwift.kScale390(10)
                button.layer.masksToBounds = true
                backgroundColor = .clear
                contentView.backgroundColor = .clear
            }
            
            if let textColor = data.textColor {
                button.setTitleColor(textColor, for: .normal)
            }
            
            line.isHidden = data.hideSeparatorLine
            
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
        
    override open class var requiresConstraintBasedLayout: Bool {
        return true
    }
        
    override open func updateConstraints() {
        super.updateConstraints()
        button.snp.remakeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(TUISwift.kScale390(20))
            make.trailing.equalTo(contentView.snp.trailing).offset(-TUISwift.kScale390(20))
            make.top.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
            
        line.snp.remakeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(20)
            make.trailing.equalTo(contentView.snp.trailing)
            make.height.equalTo(0.2)
            make.bottom.equalTo(contentView)
        }
    }
        
    @objc func onClick(_ sender: UIButton) {
        if let selector = buttonData?.cbuttonSelector, let vc = mm_viewController, vc.responds(to: selector) {
            vc.perform(selector, with: self)
        }
    }
        
    override open func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview != contentView {
            subview.removeFromSuperview()
        }
    }
        
    private func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}
