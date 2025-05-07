import SnapKit
import TIMCommon
import UIKit

public class TUIWarningView: UIView, TUIAttributedLabelDelegate {
    private let tipsIcon: UIImageView
    private var tipsLabel: TUIAttributedLabel?
    public var buttonAction: (() -> Void)?
    private var gotButton: UIButton?
    public var gotButtonAction: (() -> Void)?
    
    public init(frame: CGRect, tips: String, buttonTitle: String, buttonAction: (() -> Void)?, gotButtonTitle: String, gotButtonAction: (() -> Void)?) {
        self.buttonAction = buttonAction
        self.gotButtonAction = gotButtonAction
        self.tipsIcon = UIImageView(frame: .zero)
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.tui_color(withHex: "FFE8D5", alpha: 1)
        
        addSubview(tipsIcon)
        tipsIcon.image = UIImage.safeImage(TUISwift.timCommonImagePath("icon_secure_info_img"))
        
        if !tips.isEmpty {
            let label = TUIAttributedLabel(frame: .zero)
            label.numberOfLines = 0
            label.isUserInteractionEnabled = true
            label.delegate = self
            label.textAlignment = TUISwift.isRTL() ? .right : .left
            addSubview(label)
            self.tipsLabel = label

            let paragraphStyle = type(of: self).customParagraphStyle()
            let contentString = tips + buttonTitle
            let mutableAttributedString = NSMutableAttributedString(string: contentString)
            let wholeRange = NSRange(location: 0, length: contentString.utf16.count)
            mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: wholeRange)
            mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.tui_color(withHex: "A02800"), range: wholeRange)
            mutableAttributedString.addAttribute(.strokeColor, value: UIColor.tui_color(withHex: "A02800"), range: wholeRange)
            mutableAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: wholeRange)
            mutableAttributedString.addAttribute(.strokeWidth, value: 0, range: wholeRange)
            label.attributedText = mutableAttributedString

            label.linkAttributes = [
                kCTForegroundColorAttributeName as NSAttributedString.Key: UIColor.systemBlue,
                kCTUnderlineStyleAttributeName as NSAttributedString.Key: NSNumber(booleanLiteral: false)
            ]

            if let range = contentString.range(of: buttonTitle) {
                let nsRange = NSRange(range, in: contentString)
                if let url = URL(string: "click") {
                    label.addLink(to: url, withRange: nsRange)
                }
            }

            let maxWidth = frame.size.width - 92
            let rect = mutableAttributedString.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                                                            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            let margin: CGFloat = TUISwift.isRTL() ? 5 : 0
            var newFrame = frame
            newFrame.size.height = ceil(rect.height) + 32 + margin
            self.frame = newFrame
        }
        
        if !gotButtonTitle.isEmpty {
            let button = UIButton(type: .custom)
            button.setImage(UIImage.safeImage(TUISwift.timCommonImagePath("icon_secure_cancel_img")), for: .normal)
            addSubview(button)
            button.addTarget(self, action: #selector(onGotButtonClicked(_:)), for: .touchUpInside)
            self.gotButton = button
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onButtonClicked(_ sender: UIButton) {
        buttonAction?()
    }
    
    @objc func onGotButtonClicked(_ sender: UIButton) {
        gotButtonAction?()
    }
    
    class func customParagraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        if #available(iOS 9.0, *) {
            paragraphStyle.allowsDefaultTighteningForTruncation = true
        }
        if TUISwift.isRTL() {
            paragraphStyle.lineBreakMode = .byCharWrapping
            paragraphStyle.alignment = .right
            paragraphStyle.minimumLineHeight = 18
            paragraphStyle.lineSpacing = 11
        } else {
            paragraphStyle.lineBreakMode = .byCharWrapping
            paragraphStyle.alignment = .left
            paragraphStyle.minimumLineHeight = 11
            paragraphStyle.lineSpacing = 4
        }
        return paragraphStyle
    }
    
    override public class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    // Apple's recommended place for updating constraints
    override public func updateConstraints() {
        super.updateConstraints()
        
        // [self.tipsIcon mas_remakeConstraints:^(MASConstraintMaker *make) {...}]
        tipsIcon.snp.remakeConstraints { make in
            make.top.equalTo(16)
            make.leading.equalTo(20)
            make.width.height.equalTo(16)
        }
        
        if let label = tipsLabel {
            label.snp.remakeConstraints { make in
                make.top.equalTo(16)
                make.leading.equalTo(tipsIcon.snp.trailing).offset(10)
                make.trailing.equalTo(self.snp.trailing).offset(-46)
                make.bottom.equalTo(-16)
            }
        }
        
        if let button = gotButton {
            button.snp.remakeConstraints { make in
                make.top.equalTo(16)
                make.trailing.equalTo(-20)
                make.width.height.equalTo(16)
            }
        }
    }
    
    // MARK: - TUIAttributedLabelDelegate

    public func attributedLabel(_ label: TUIAttributedLabel, didSelectLink link: URL) {
        buttonAction?()
    }
}
