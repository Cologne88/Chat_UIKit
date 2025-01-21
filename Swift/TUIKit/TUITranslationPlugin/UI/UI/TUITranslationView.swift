import SnapKit
import TIMCommon
import TUIChat
import TUICore
import UIKit

class TUITranslationView: UIView {
    private var text: String?
    private var tips: String?
    private var bgColor: UIColor?
    
    private let tipsIcon = UIImageView()
    private let tipsLabel = UILabel()
    private let loadingView = UIImageView()
    private let textView = TUITextView()
    private let retryView = UIImageView()
    
    private var cellData: TUIMessageCellData!
    
    convenience init(data: TUIMessageCellData) {
        self.init(frame: CGRect.zero)
        self.cellData = data
        
        let shouldShow = TUITranslationDataProvider.shouldShowTranslation(data.innerMessage)
        if shouldShow {
            refresh(with: data)
        } else {
            if !cellData.bottomContainerSize.equalTo(.zero) {
                notifyTranslationChanged()
            }
            self.isHidden = true
            stopLoading()
            cellData?.bottomContainerSize = .zero
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGesture()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func refresh(with cellData: TUIMessageCellData) {
        text = TUITranslationDataProvider.getTranslationText(cellData.innerMessage)
        let status = TUITranslationDataProvider.getTranslationStatus(cellData.innerMessage)
        
        let size = calcSize(of: status)
        if !cellData.bottomContainerSize.equalTo(size) {
            notifyTranslationChanged()
        }
        cellData.bottomContainerSize = size
        mm_top()(0)?.mm_left()(0)?.mm_width()(size.width)?.mm_height()(size.height)
//        snp.makeConstraints { make in
//            make.top.left.equalTo(0)
//            make.width.equalTo(size.width)
//            make.height.equalTo(size.height)
//        }
        if status == .loading {
            startLoading()
        } else if status == .shown || status == .securityStrike {
            stopLoading()
            updateTranslationView(by: text, translationViewStatus: status)
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    private func calcSize(of status: TUITranslationViewStatus) -> CGSize {
        let minTextWidth: CGFloat = 164
        let maxTextWidth = TUISwift.screen_Width() * 0.68
        let actualTextWidth: CGFloat = 80 - 20
        let tipsHeight: CGFloat = 20
        let tipsBottomMargin: CGFloat = 10
        let oneLineTextHeight: CGFloat = 22
        let commonMargins: CGFloat = 10 * 2
        
        if status == .loading {
            return CGSize(width: 80, height: oneLineTextHeight + commonMargins)
        }
        
        let attrStr = text?.getAdvancedFormatEmojiString(with: UIFont.systemFont(ofSize: 16), textColor: .gray, emojiLocations: nil) ?? NSAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        
        var textRect = attrStr.boundingRect(with: CGSize(width: actualTextWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        if textRect.height < 30 {
            return CGSize(width: max(textRect.width, minTextWidth) + commonMargins, height: max(textRect.height, oneLineTextHeight) + commonMargins + tipsHeight + tipsBottomMargin)
        }
        
        textRect = attrStr.boundingRect(with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let result = CGSize(width: max(textRect.width, minTextWidth) + commonMargins, height: max(textRect.height, oneLineTextHeight) + commonMargins + tipsHeight + tipsBottomMargin)
        return CGSize(width: ceil(result.width), height: ceil(result.height))
    }
    
    private func setupViews() {
        backgroundColor = bgColor ?? TUISwift.tuiTranslationDynamicColor("translation_view_bg_color", defaultColor: "#F2F7FF")
        layer.cornerRadius = 10.0
        
        loadingView.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        loadingView.image = TUISwift.tuiTranslationBundleThemeImage("translation_view_icon_loading_img", defaultImage: "translation_loading")
        loadingView.isHidden = true
        addSubview(loadingView)
        
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textAlignment = TUISwift.isRTL() ? .right : .left
        textView.disableHighlightLink()
        addSubview(textView)
        textView.isHidden = true
        textView.isUserInteractionEnabled = false
        
        tipsIcon.frame = CGRect(x: 0, y: 0, width: 13, height: 13)
        tipsIcon.image = TUISwift.tuiTranslationBundleThemeImage("translation_view_icon_tips_img", defaultImage: "translation_tips")
        tipsIcon.alpha = 0.4
        addSubview(tipsIcon)
        tipsIcon.isHidden = true
        
        tipsLabel.font = UIFont.systemFont(ofSize: 12)
        tipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitTranslateDefaultTips")
        tipsLabel.textColor = TUISwift.tuiTranslationDynamicColor("translation_view_tips_color", defaultColor: "#000000")
        tipsLabel.alpha = 0.4
        tipsLabel.numberOfLines = 0
        tipsLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        addSubview(tipsLabel)
        tipsLabel.isHidden = true
        
        retryView.image = UIImage(named: TUISwift.tuiChatImagePath("msg_error"))
        retryView.isHidden = true
        addSubview(retryView)
    }
    
    private func setupGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed(_:)))
        addGestureRecognizer(longPress)
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        if text?.isEmpty ?? true {
            loadingView.snp.remakeConstraints { make in
                make.height.width.equalTo(15)
                make.leading.equalTo(10)
                make.centerY.equalToSuperview()
            }
        } else {
            retryView.snp.remakeConstraints { make in
                if cellData?.direction == .MsgDirectionOutgoing {
                    make.leading.equalToSuperview().offset(-27)
                } else {
                    make.trailing.equalToSuperview().offset(27)
                }
                make.centerY.equalToSuperview()
                make.width.height.equalTo(20)
            }
            textView.snp.remakeConstraints { make in
                make.height.equalTo(self.frame.height - 10 - 40 + 2)
                make.leading.equalTo(10)
                make.trailing.equalTo(-10)
                make.top.equalTo(10)
            }
            tipsIcon.snp.remakeConstraints { make in
                make.top.equalTo(textView.snp.bottom).offset(14)
                make.leading.equalTo(10)
                make.height.width.equalTo(13)
            }
            tipsLabel.sizeToFit()
            tipsLabel.snp.remakeConstraints { make in
                make.centerY.equalTo(tipsIcon.snp.centerY)
                make.leading.equalTo(tipsIcon.snp.trailing).offset(4)
                make.trailing.equalTo(textView.snp.trailing)
            }
        }
    }
    
    private func updateTranslationView(by text: String?, translationViewStatus status: TUITranslationViewStatus) {
        let isTranslated = !(text?.isEmpty ?? true)
        var textColor = TUISwift.tuiTranslationDynamicColor("translation_view_text_color", defaultColor: "#000000")
        var bgColor = TUISwift.tuiTranslationDynamicColor("translation_view_bg_color", defaultColor: "#F2F7FF")
        if status == .securityStrike {
            bgColor = UIColor.tui_color(withHex: "#FA5151", alpha: 0.16)
            textColor = TUISwift.tuiTranslationDynamicColor("", defaultColor: "#DA2222")
        }
        self.bgColor = bgColor
        backgroundColor = bgColor
        
        if isTranslated {
            let originAttributedText = text?.getAdvancedFormatEmojiString(with: UIFont.systemFont(ofSize: 16), textColor: textColor!, emojiLocations: nil) ?? NSAttributedString()
            textView.attributedText = TUISwift.isRTL() ? rtlAttributeString(originAttributedText, .right) : originAttributedText
        }
        textView.isHidden = !isTranslated
        tipsIcon.isHidden = !isTranslated
        tipsLabel.isHidden = !isTranslated
        retryView.isHidden = !(status == .securityStrike)
    }
    
    func startLoading() {
        if !loadingView.isHidden {
            return
        }
        
        loadingView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.toValue = Double.pi * 2.0
            rotate.duration = 1
            rotate.repeatCount = .greatestFiniteMagnitude
            self.loadingView.layer.add(rotate, forKey: "rotationAnimation")
        }
    }
    
    func stopLoading() {
        if loadingView.isHidden {
            return
        }
        loadingView.isHidden = true
        loadingView.layer.removeAllAnimations()
    }
    
    @objc private func onLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, let cellData = cellData else {
            return
        }
        
        let popMenu = TUIChatPopMenu()
        let status = TUITranslationDataProvider.getTranslationStatus(cellData.innerMessage)
        let hasRiskContent = (status == .securityStrike)
        
        let copy = TUIChatPopMenuAction(title: TUISwift.timCommonLocalizableString("Copy"), image: TUISwift.tuiTranslationBundleThemeImage("translation_view_pop_menu_copy_img", defaultImage: "icon_copy"), weight: 1) { [weak self] in
            self?.onCopy(self?.text)
        }
        popMenu.addAction(copy)
        
        let forward = TUIChatPopMenuAction(title: TUISwift.timCommonLocalizableString("Forward"), image: TUISwift.tuiTranslationBundleThemeImage("translation_view_pop_menu_forward_img", defaultImage: "icon_forward"), weight: 2) { [weak self] in
            self?.onForward(self?.text)
        }
        if !hasRiskContent {
            popMenu.addAction(forward)
        }
        
        let hide = TUIChatPopMenuAction(title: TUISwift.timCommonLocalizableString("Hide"), image: TUISwift.tuiTranslationBundleThemeImage("translation_view_pop_menu_hide_img", defaultImage: "icon_hide"), weight: 3) { [weak self] in
            self?.onHide(self)
        }
        popMenu.addAction(hide)
        
        if let keyWindow = TUITool.applicationKeywindow() {
            let frame = keyWindow.convert(self.frame, from: superview)
            popMenu.setArrawPosition(CGPoint(x: frame.origin.x + frame.size.width * 0.5, y: frame.origin.y + 66), adjustHeight: 0)
            popMenu.showInView(keyWindow)
        }
    }
    
    private func onCopy(_ text: String?) {
        guard let text = text, !text.isEmpty else {
            return
        }
        UIPasteboard.general.string = text
        TUITool.makeToast(TUISwift.timCommonLocalizableString("Copied"))
    }
    
    private func onForward(_ text: String?) {
        notifyTranslationForward(text)
    }
    
    private func onHide(_ sender: Any?) {
        cellData?.bottomContainerSize = .zero
        if let innerMessage = cellData?.innerMessage {
            TUITranslationDataProvider.saveTranslationResult(innerMessage, text: "", status: .hidden)
        }
        removeFromSuperview()
        notifyTranslationViewHidden()
    }
    
    // MARK: - Notify

    private func notifyTranslationViewShown() {
        notifyTranslationChanged()
    }
    
    private func notifyTranslationViewHidden() {
        notifyTranslationChanged()
    }
    
    private func notifyTranslationForward(_ text: String?) {
        let param: [String: Any] = [TUICore_TUIPluginNotify_WillForwardTextSubKey_Text: text ?? ""]
        TUICore.notifyEvent(TUICore_TUIPluginNotify, subKey: TUICore_TUIPluginNotify_WillForwardTextSubKey, object: nil, param: param)
    }
    
    private func notifyTranslationChanged() {
        let param: [String: Any] = [TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data: cellData as Any, TUICore_TUIPluginNotify_DidChangePluginViewSubKey_VC: self]
        TUICore.notifyEvent(TUICore_TUIPluginNotify, subKey: TUICore_TUIPluginNotify_DidChangePluginViewSubKey, object: nil, param: param)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.setNeedsUpdateConstraints()
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
}
