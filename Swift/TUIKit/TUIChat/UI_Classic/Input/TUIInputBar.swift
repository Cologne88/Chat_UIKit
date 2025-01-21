import TIMCommon
import TUICore
import UIKit

private enum TUIRecordStatus: Int {
    case initial
    case record
    case delete
    case cancel
}

@objc protocol TUIInputBarDelegate: NSObjectProtocol {
    @objc optional func inputBarDidTouchFace(_ textView: TUIInputBar)
    @objc optional func inputBarDidTouchMore(_ textView: TUIInputBar)
    @objc optional func inputBarDidTouchVoice(_ textView: TUIInputBar)
    @objc optional func inputBarDidChangeInputHeight(_ textView: TUIInputBar, offset: CGFloat)
    @objc optional func inputBarDidSendText(_ textView: TUIInputBar, text: String)
    @objc optional func inputBarDidSendVoice(_ textView: TUIInputBar, path: String)
    @objc optional func inputBarDidInputAt(_ textView: TUIInputBar)
    @objc optional func inputBarDidDeleteAt(_ textView: TUIInputBar, text: String)
    @objc optional func inputBarDidTouchKeyboard(_ textView: TUIInputBar)
    @objc optional func inputBarDidDeleteBackward(_ textView: TUIInputBar)
    @objc optional func inputTextViewShouldBeginTyping(_ textView: UITextView)
    @objc optional func inputTextViewShouldEndTyping(_ textView: UITextView)
}

class TUIInputBar: UIView, UITextViewDelegate, TUIAudioRecorderDelegate, TUIResponderTextViewDelegate {
    var lineView: UIView
    var micButton: UIButton
    var cameraButton: UIButton
    var keyboardButton: UIButton
    var inputTextView: TUIResponderTextView
    var faceButton: UIButton
    var moreButton: UIButton
    var recordButton: UIButton
    var recordDeleteView: UIImageView
    var recordBackgroudView: UIView
    var recordTipsView: UIView
    var recordTipsLabel: UILabel
    var recordTimeLabel: UILabel
    var recordAnimateViews: [UIImageView]
    var recordAnimateCoverView: UIImageView
    var recordAnimateCoverViewFrame: CGRect?
    var inputBarTextChanged: ((UITextView) -> Void)?
    var recordStartTime: Date?
    var recordTimer: Timer?
    var isFocusOn: Bool = false
    var sendTypingStatusTimer: Timer?
    var allowSendTypingStatusByChangeWord: Bool = true
    var isFromReplyPage: Bool = false
    weak var delegate: TUIInputBarDelegate?

    lazy var recorder: TUIAudioRecorder = {
        let recorder = TUIAudioRecorder()
        recorder.delegate = self
        return recorder
    }()

    private var _recordView: TUIRecordView?
    var recordView: TUIRecordView? {
        get {
            if _recordView == nil {
                _recordView = TUIRecordView()
                _recordView?.frame = frame
            }
            return _recordView!
        }
        set {
            _recordView = newValue
        }
    }

    let normalFont: UIFont = .systemFont(ofSize: 16)
    let normalColor: UIColor = TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000")

    // MARK: - Init

    override init(frame: CGRect) {
        lineView = UIView()
        moreButton = UIButton()
        inputTextView = TUIResponderTextView()
        keyboardButton = UIButton()
        faceButton = UIButton()
        micButton = UIButton()
        cameraButton = UIButton()
        recordDeleteView = UIImageView()
        recordBackgroudView = UIView()
        recordTimeLabel = UILabel()
        recordAnimateViews = [UIImageView]()
        recordAnimateCoverView = UIImageView()
        recordTipsView = UIView()
        recordTipsLabel = UILabel()
        micButton = UIButton()
        recordButton = UIButton()

        super.init(frame: frame)

        setupViews()
        defaultLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: Notification.Name(TUIDidApplyingThemeChangedNotfication), object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        sendTypingStatusTimer?.invalidate()
        sendTypingStatusTimer = nil
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Views and layout

    func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")

        lineView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#FFFFFF")
        addSubview(lineView)

        micButton.addTarget(self, action: #selector(onMicButtonClicked(_:)), for: .touchUpInside)
        micButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewInputVoice_img", defaultImage: "ToolViewInputVoice"), for: .normal)
        micButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewInputVoiceHL_img", defaultImage: "ToolViewInputVoiceHL"), for: .highlighted)
        addSubview(micButton)

        faceButton.addTarget(self, action: #selector(onFaceEmojiButtonClicked(_:)), for: .touchUpInside)
        faceButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewEmotion_img", defaultImage: "ToolViewEmotion"), for: .normal)
        faceButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewEmotionHL_img", defaultImage: "ToolViewEmotionHL"), for: .highlighted)
        addSubview(faceButton)

        keyboardButton.addTarget(self, action: #selector(onKeyboardButtonClicked(_:)), for: .touchUpInside)
        keyboardButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewKeyboard_img", defaultImage: "ToolViewKeyboard"), for: .normal)
        keyboardButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewKeyboardHL_img", defaultImage: "ToolViewKeyboardHL"), for: .highlighted)
        keyboardButton.isHidden = true
        addSubview(keyboardButton)

        moreButton.addTarget(self, action: #selector(onMoreButtonClicked(_:)), for: .touchUpInside)
        moreButton.setImage(getImageFromCache("TypeSelectorBtnHL_Black"), for: .normal)
        moreButton.setImage(getImageFromCache("TypeSelectorBtnHL_Black"), for: .highlighted)
        addSubview(moreButton)

        recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        recordButton.addTarget(self, action: #selector(onRecordButtonTouchDown(_:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(onRecordButtonTouchUpInside(_:)), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(onRecordButtonTouchCancel(_:)), for: [.touchUpOutside, .touchCancel])
        recordButton.addTarget(self, action: #selector(onRecordButtonTouchDragExit(_:)), for: .touchDragExit)
        recordButton.addTarget(self, action: #selector(onRecordButtonTouchDragEnter(_:)), for: .touchDragEnter)
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputHoldToTalk"), for: .normal)
        recordButton.setTitleColor(TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000"), for: .normal)
        recordButton.isHidden = true
        addSubview(recordButton)

        inputTextView.delegate = self
        inputTextView.font = normalFont
        inputTextView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_bg_color", defaultColor: "#FFFFFF")
        inputTextView.textColor = TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000")
        inputTextView.textAlignment = TUISwift.isRTL() ? .right : .left
        inputTextView.returnKeyType = .send
        addSubview(inputTextView)

        applyBorderTheme()
    }

    func applyBorderTheme() {
        recordButton.layer.masksToBounds = true
        recordButton.layer.cornerRadius = 4.0
        recordButton.layer.borderWidth = 1.0
        recordButton.layer.borderColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB").cgColor

        inputTextView.layer.masksToBounds = true
        inputTextView.layer.cornerRadius = 4.0
        inputTextView.layer.borderWidth = 0.5
        inputTextView.layer.borderColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB").cgColor
    }

    func defaultLayout() {
        lineView.snp.remakeConstraints { make in
            make.top.equalTo(0)
            make.leading.width.equalToSuperview()
            make.height.equalTo(TLine_Heigh)
        }

        let buttonSize = TUISwift.tTextView_Button_Size()

        micButton.snp.remakeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(buttonSize)
        }

        keyboardButton.snp.remakeConstraints { make in
            make.edges.equalTo(micButton)
        }

        moreButton.snp.remakeConstraints { make in
            make.trailing.equalToSuperview()
            make.size.equalTo(buttonSize)
            make.centerY.equalToSuperview()
        }

        faceButton.snp.remakeConstraints { make in
            make.trailing.equalTo(moreButton.snp.leading).offset(-TUISwift.tTextView_Margin())
            make.size.equalTo(buttonSize)
            make.centerY.equalToSuperview()
        }

        recordButton.snp.remakeConstraints { make in
            make.leading.equalTo(micButton.snp.trailing).offset(10)
            make.trailing.equalTo(faceButton.snp.leading).offset(-10)
            make.height.equalTo(TUISwift.tTextView_TextView_Height_Min())
            make.centerY.equalToSuperview()
        }

        inputTextView.snp.remakeConstraints { make in
            if isFromReplyPage {
                make.leading.equalToSuperview().offset(10)
            } else {
                make.leading.equalTo(micButton.snp.trailing).offset(10)
            }
            make.trailing.equalTo(faceButton.snp.leading).offset(-10)
            make.height.equalTo(TUISwift.tTextView_TextView_Height_Min())
            make.centerY.equalToSuperview()
        }
    }

    func layoutButton(height: CGFloat) {
        var frame = self.frame
        let offset = height - frame.size.height
        frame.size.height = height
        self.frame = frame

        let buttonSize = TUISwift.tTextView_Button_Size()
        let bottomMargin = (TUISwift.tTextView_Height() - buttonSize.height) * 0.5
        let originY = frame.height - buttonSize.height - bottomMargin

        faceButton.frame.origin.y = originY
        moreButton.frame.origin.y = originY
        micButton.frame.origin.y = originY

        keyboardButton.snp.remakeConstraints { make in
            make.edges.equalTo(faceButton)
        }

        delegate?.inputBarDidChangeInputHeight?(self, offset: offset)
    }

    func getImageFromCache(_ path: String) -> UIImage {
        return TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath(path))
    }

    func getStickerFromCache(_ path: String) -> UIImage {
        return TUIImageCache.sharedInstance().getFaceFromCache(path)
    }

    // MARK: - Evevnt

    @objc func onThemeChanged() {
        applyBorderTheme()
    }

    @objc func onMicButtonClicked(_ sender: UIButton) {
        recordButton.isHidden = false
        inputTextView.isHidden = true
        micButton.isHidden = true
        keyboardButton.isHidden = false
        faceButton.isHidden = false
        inputTextView.resignFirstResponder()
        layoutButton(height: TUISwift.tTextView_Height())
        delegate?.inputBarDidTouchVoice?(self)
        keyboardButton.snp.remakeConstraints { make in
            make.edges.equalTo(micButton)
        }
    }

    @objc func onKeyboardButtonClicked(_ sender: UIButton) {
        micButton.isHidden = false
        keyboardButton.isHidden = true
        recordButton.isHidden = true
        inputTextView.isHidden = false
        faceButton.isHidden = false
        layoutButton(height: inputTextView.frame.size.height + 2 * TUISwift.tTextView_Margin())
        delegate?.inputBarDidTouchKeyboard?(self)
    }

    @objc func onFaceEmojiButtonClicked(_ sender: UIButton) {
        micButton.isHidden = false
        faceButton.isHidden = true
        keyboardButton.isHidden = false
        recordButton.isHidden = true
        inputTextView.isHidden = false
        delegate?.inputBarDidTouchFace?(self)
        keyboardButton.snp.remakeConstraints { make in
            make.edges.equalTo(faceButton)
        }
    }

    @objc func onMoreButtonClicked(_ sender: UIButton) {
        delegate?.inputBarDidTouchMore?(self)
    }

    @objc func onRecordButtonTouchDown(_ sender: UIButton) {
        recorder.record()
    }

    @objc func onRecordButtonTouchUpInside(_ sender: UIButton) {
        recordButton.backgroundColor = .clear
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputHoldToTalk"), for: .normal)

        let interval = Date().timeIntervalSince(recordStartTime ?? Date())
        if interval < 1 {
            recordView?.setStatus(.tooShort)
            recorder.cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.recordView?.removeFromSuperview()
                self.recordView = nil
            }
        } else if interval > min(59, TUIChatConfig.shared.maxAudioRecordDuration) {
            recordView?.setStatus(.tooLong)
            recorder.cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.recordView?.removeFromSuperview()
                self.recordView = nil
            }
        } else {
            DispatchQueue.main.async {
                self.recordView?.removeFromSuperview()
                self.recordView = nil
                DispatchQueue.main.async {
                    self.recorder.stop()
                    self.delegate?.inputBarDidSendVoice?(self, path: self.recorder.recordedFilePath)
                }
            }
        }
    }

    @objc func onRecordButtonTouchCancel(_ sender: UIButton) {
        recordView?.removeFromSuperview()
        recordView = nil
        recordButton.backgroundColor = .clear
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputHoldToTalk"), for: .normal)
        recorder.cancel()
    }

    @objc func onRecordButtonTouchDragExit(_ sender: UIButton) {
        recordView?.setStatus(.cancel)
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputReleaseToCancel"), for: .normal)
    }

    @objc func onRecordButtonTouchDragEnter(_ sender: UIButton) {
        recordView?.setStatus(.recording)
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputReleaseToSend"), for: .normal)
    }

    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardButton.isHidden = true
        micButton.isHidden = false
        faceButton.isHidden = false

        isFocusOn = true
        allowSendTypingStatusByChangeWord = true

        sendTypingStatusTimer = Timer.tui_scheduledTimer(withTimeInterval: 4, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.allowSendTypingStatusByChangeWord = true
        })

        if isFocusOn && textView.textStorage.tui_getPlainString().count > 0 {
            delegate?.inputTextViewShouldBeginTyping?(textView)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        isFocusOn = false
        delegate?.inputTextViewShouldEndTyping?(textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        if allowSendTypingStatusByChangeWord && isFocusOn && textView.textStorage.tui_getPlainString().count > 0 {
            delegate?.inputTextViewShouldBeginTyping?(textView)
        }

        if isFocusOn && textView.textStorage.tui_getPlainString().count == 0 {
            delegate?.inputTextViewShouldEndTyping?(textView)
        }
        if let inputBarTextChanged = inputBarTextChanged {
            inputBarTextChanged(inputTextView)
        }
        let size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: CGFloat(TTextView_TextView_Height_Max)))
        let oldHeight = inputTextView.frame.height
        var newHeight = size.height

        if newHeight > Double(TTextView_TextView_Height_Max) {
            newHeight = Double(TTextView_TextView_Height_Max)
        }
        if newHeight < TUISwift.tTextView_TextView_Height_Min() {
            newHeight = TUISwift.tTextView_TextView_Height_Min()
        }
        if oldHeight == newHeight {
            return
        }

        UIView.animate(withDuration: 0.3) {
            self.inputTextView.snp.remakeConstraints { make in
                make.leading.equalTo(self.micButton.snp.trailing).offset(10)
                make.trailing.equalTo(self.faceButton.snp.leading).offset(-10)
                make.height.equalTo(newHeight)
                make.centerY.equalTo(self)
            }
            self.layoutButton(height: newHeight + CGFloat(2 * TTextView_Margin))
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.tui_contains("[") && text.tui_contains("]") {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                textView.textStorage.deleteCharacters(in: selectedRange)
            }

            let textChange = text.getAdvancedFormatEmojiString(with: normalFont, textColor: normalColor, emojiLocations: nil)
            textView.textStorage.insert(textChange, at: textView.textStorage.length)
            DispatchQueue.main.async {
                self.inputTextView.selectedRange = NSRange(location: self.inputTextView.textStorage.length + 1, length: 0)
            }
            return false
        }

        if text == "\n" {
            if let delegate = delegate, delegate.responds(to: #selector(TUIInputBarDelegate.inputBarDidSendText(_:text:))) {
                let sp = textView.textStorage.tui_getPlainString().trimmingCharacters(in: .whitespaces)
                if sp.count == 0 {
                    let ac = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitInputBlankMessageTitle"), message: nil, preferredStyle: .alert)
                    ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Confirm"), style: .default, handler: nil))
                    mm_viewController.present(ac, animated: true, completion: nil)
                } else {
                    delegate.inputBarDidSendText!(self, text: textView.textStorage.tui_getPlainString())
                    clearInput()
                }
            }
            return false
        } else if text == "" {
            if textView.textStorage.length > range.location {
                // Delete the @ message like @xxx at one time
                let lastAttributedStr = textView.textStorage.attributedSubstring(from: NSRange(location: range.location, length: 1))
                let lastStr = lastAttributedStr.tui_getPlainString()
                if lastStr.count > 0, lastStr.first == " " {
                    var location = range.location
                    var length = range.length

                    // @ ASCII
                    let at = 64
                    // space ASCII
                    let space = 32

                    while location != 0 {
                        location -= 1
                        length += 1
                        // Convert characters to ascii code, copy to int, avoid out of bounds
                        if let firstChar = textView.textStorage.attributedSubstring(from: NSRange(location: location, length: 1)).tui_getPlainString().first {
                            if let firstCharAscii = firstChar.asciiValue {
                                if firstCharAscii == at {
                                    let atText = textView.textStorage.attributedSubstring(from: NSRange(location: location, length: length)).tui_getPlainString()
                                    let textFont = normalFont
                                    let spaceString = NSAttributedString(string: "", attributes: [NSAttributedString.Key.font: textFont])
                                    textView.textStorage.replaceCharacters(in: NSRange(location: location, length: length), with: spaceString)
                                    delegate?.inputBarDidDeleteAt?(self, text: atText)
                                    return false
                                } else if firstCharAscii == space {
                                    // Avoid "@nickname Hello, nice to meet you (space) "" Press del after a space to over-delete to @
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        // Monitor the input of @ character, including full-width/half-width
        else if text == "@" || text == "＠" {
            delegate?.inputBarDidInputAt?(self)
            return false
        }
        return true
    }

    // MARK: - TUIResponderTextViewDelegate

    func onDeleteBackward(_ textView: TUIResponderTextView) {
        delegate?.inputBarDidDeleteBackward?(self)
    }

    // MARK: - Other

    func clearInput() {
        inputTextView.textStorage.deleteCharacters(in: NSRange(location: 0, length: inputTextView.textStorage.length))
        textViewDidChange(inputTextView)
    }

    func getInput() -> String {
        return inputTextView.textStorage.tui_getPlainString()
    }

    func addEmoji(_ emoji: TUIFaceCellData) {
        // Create emoji attachment
        let emojiTextAttachment = TUIEmojiTextAttachment()
        emojiTextAttachment.faceCellData = emoji

        // Set tag and image
        emojiTextAttachment.emojiTag = emoji.name
        emojiTextAttachment.image = getStickerFromCache(emoji.path)

        // Set emoji size
        emojiTextAttachment.emojiSize = TUISwift.timDefaultEmojiSize()
        let str = NSAttributedString(attachment: emojiTextAttachment)

        let selectedRange = inputTextView.selectedRange
        if selectedRange.length > 0 {
            inputTextView.textStorage.deleteCharacters(in: selectedRange)
        }
        // Insert emoji image
        inputTextView.textStorage.insert(str, at: inputTextView.selectedRange.location)

        inputTextView.selectedRange = NSRange(location: inputTextView.selectedRange.location + 1, length: 0)
        resetTextStyle()

        if inputTextView.contentSize.height > TUISwift.tTextView_TextView_Height_Max() {
            let offset = inputTextView.contentSize.height - inputTextView.frame.size.height
            inputTextView.scrollRectToVisible(CGRect(x: 0, y: offset, width: inputTextView.frame.size.width, height: inputTextView.frame.size.height), animated: true)
        }
        textViewDidChange(inputTextView)
    }

    func resetTextStyle() {
        // After changing text selection, should reset style.
        let wholeRange = NSRange(location: 0, length: inputTextView.textStorage.length)
        inputTextView.textStorage.removeAttribute(.font, range: wholeRange)
        inputTextView.textStorage.removeAttribute(.foregroundColor, range: wholeRange)
        inputTextView.textStorage.addAttribute(.foregroundColor, value: normalColor, range: wholeRange)
        inputTextView.textStorage.addAttribute(.font, value: normalFont, range: wholeRange)
        inputTextView.font = normalFont
        inputTextView.textAlignment = TUISwift.isRTL() ? .right : .left

        inputTextView.textColor = normalColor
        inputTextView.font = normalFont
    }

    func backDelete() {
        if inputTextView.textStorage.length > 0 {
            inputTextView.textStorage.deleteCharacters(in: NSRange(location: inputTextView.textStorage.length - 1, length: 1))
            textViewDidChange(inputTextView)
        }
    }

    func updateTextViewFrame() {
        textViewDidChange(UITextView())
    }

    func changeToKeyboard() {
        onKeyboardButtonClicked(keyboardButton)
    }

    func addDraftToInputBar(_ draft: NSAttributedString) {
        addWordsToInputBar(draft)
    }

    func addWordsToInputBar(_ words: NSAttributedString) {
        let selectedRange = inputTextView.selectedRange
        if selectedRange.length > 0 {
            inputTextView.textStorage.deleteCharacters(in: selectedRange)
        }
        // Insert words
        inputTextView.textStorage.insert(words, at: inputTextView.selectedRange.location)
        inputTextView.selectedRange = NSRange(location: inputTextView.textStorage.length + 1, length: 0)
        resetTextStyle()
        updateTextViewFrame()
    }

    // MARK: - TUIAudioRecorderDelegate

    func didCheckPermission(_ recorder: TUIAudioRecorder, _ isGranted: Bool, _ isFirstTime: Bool) {
        if isFirstTime {
            if !isGranted {
                showRequestMicAuthorizationAlert()
            }
            return
        }
        updateViewsToRecordingStatus()
    }

    func updateViewsToRecordingStatus() {
        guard let window = window, let recordView = recordView else { return }

        window.addSubview(recordView)
        recordView.snp.remakeConstraints { make in
            make.center.equalTo(window)
            make.width.height.equalTo(window)
        }

        recordStartTime = Date()
        recordView.setStatus(.recording)
        recordButton.backgroundColor = .lightGray
        recordButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitInputReleaseToSend"), for: .normal)
        showHapticFeedback()
    }

    func showRequestMicAuthorizationAlert() {
        let ac = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitInputNoMicTitle"),
                                   message: TUISwift.timCommonLocalizableString("TUIKitInputNoMicTips"),
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitInputNoMicOperateLater"),
                                   style: .cancel,
                                   handler: nil))
        ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitInputNoMicOperateEnable"),
                                   style: .default,
                                   handler: { _ in
                                       let app = UIApplication.shared
                                       if let settingsURL = URL(string: UIApplication.openSettingsURLString), app.canOpenURL(settingsURL) {
                                           app.open(settingsURL)
                                       }
                                   }))
        DispatchQueue.main.async {
            self.mm_viewController.present(ac, animated: true, completion: nil)
        }
    }

    func showHapticFeedback() {
        if #available(iOS 10.0, *) {
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            }
        } else {
            // Fallback on earlier versions
        }
    }

    func didRecordTimeChanged(_ recorder: TUIAudioRecorder, _ time: TimeInterval) {
        let uiMaxDuration = min(59, TUIChatConfig.shared.maxAudioRecordDuration)
        let realMaxDuration = uiMaxDuration + 0.7
        let seconds = Int(uiMaxDuration - time)
        recordView?.timeLabel.text = "\(seconds + 1)\""

        if time >= (uiMaxDuration - 4) && time <= uiMaxDuration {
            let seconds = Int(uiMaxDuration - time)
            /**
             * The long type is cast here to eliminate compiler warnings.
             * Here +1 is to round up and optimize the time logic.
             */
            recordView?.title.text = String(format: TUISwift.timCommonLocalizableString("TUIKitInputWillFinishRecordInSeconds"), seconds + 1)
        } else if time > realMaxDuration {
            recorder.stop()
            let path = recorder.recordedFilePath
            recordView?.setStatus(.tooLong)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.recordView?.removeFromSuperview()
                self?.recordView = nil
            }

            delegate?.inputBarDidSendVoice?(self, path: path)
        }
    }
}
