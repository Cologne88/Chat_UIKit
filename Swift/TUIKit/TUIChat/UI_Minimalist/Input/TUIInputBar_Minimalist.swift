import TIMCommon
import TUICore
import UIKit

private enum TUIRecordStatus: Int {
    case initial
    case record
    case delete
    case cancel
}

protocol TUIInputBarDelegate_Minimalist: AnyObject {
    func inputBarDidTouchFace(_ textView: TUIInputBar_Minimalist)
    func inputBarDidTouchMore(_ textView: TUIInputBar_Minimalist)
    func inputBarDidTouchCamera(_ textView: TUIInputBar_Minimalist)
    func inputBarDidChangeInputHeight(_ textView: TUIInputBar_Minimalist, offset: CGFloat)
    func inputBarDidSendText(_ textView: TUIInputBar_Minimalist, text: String)
    func inputBarDidSendVoice(_ textView: TUIInputBar_Minimalist, path: String)
    func inputBarDidInputAt(_ textView: TUIInputBar_Minimalist)
    func inputBarDidDeleteAt(_ textView: TUIInputBar_Minimalist, text: String)
    func inputBarDidTouchKeyboard(_ textView: TUIInputBar_Minimalist)
    func inputBarDidDeleteBackward(_ textView: TUIInputBar_Minimalist)
    func inputTextViewShouldBeginTyping(_ textView: UITextView)
    func inputTextViewShouldEndTyping(_ textView: UITextView)
}

extension TUIInputBarDelegate_Minimalist {
    func inputBarDidTouchFace(_ textView: TUIInputBar_Minimalist) {}
    func inputBarDidTouchMore(_ textView: TUIInputBar_Minimalist) {}
    func inputBarDidTouchCamera(_ textView: TUIInputBar_Minimalist) {}
    func inputBarDidChangeInputHeight(_ textView: TUIInputBar_Minimalist, offset: CGFloat) {}
    func inputBarDidSendText(_ textView: TUIInputBar_Minimalist, text: String) {}
    func inputBarDidSendVoice(_ textView: TUIInputBar_Minimalist, path: String) {}
    func inputBarDidInputAt(_ textView: TUIInputBar_Minimalist) {}
    func inputBarDidDeleteAt(_ textView: TUIInputBar_Minimalist, text: String) {}
    func inputBarDidTouchKeyboard(_ textView: TUIInputBar_Minimalist) {}
    func inputBarDidDeleteBackward(_ textView: TUIInputBar_Minimalist) {}
    func inputTextViewShouldBeginTyping(_ textView: UITextView) {}
    func inputTextViewShouldEndTyping(_ textView: UITextView) {}
}

class TUIInputBar_Minimalist: UIView, UITextViewDelegate, TUIAudioRecorderDelegate, TUIResponderTextViewDelegate_Minimalist {
    var lineView: UIView
    var micButton: UIButton
    var cameraButton: UIButton
    var keyboardButton: UIButton
    var inputTextView: TUIResponderTextView_Minimalist
    var faceButton: UIButton
    var moreButton: UIButton
    var recordView: UIView
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
    weak var delegate: TUIInputBarDelegate_Minimalist?

    lazy var recorder: TUIAudioRecorder = {
        let recorder = TUIAudioRecorder()
        recorder.delegate = self
        return recorder
    }()

    let normalFont: UIFont = .systemFont(ofSize: 16)
    let normalColor: UIColor = TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000")

    // MARK: - Init

    override init(frame: CGRect) {
        lineView = UIView()
        moreButton = UIButton()
        inputTextView = TUIResponderTextView_Minimalist()
        keyboardButton = UIButton()
        faceButton = UIButton()
        micButton = UIButton()
        cameraButton = UIButton()
        recordView = UIView()
        recordDeleteView = UIImageView()
        recordBackgroudView = UIView()
        recordTimeLabel = UILabel()
        recordAnimateViews = [UIImageView]()
        recordAnimateCoverView = UIImageView()
        recordTipsView = UIView()
        recordTipsLabel = UILabel()

        super.init(frame: frame)

        setupViews()
        defaultLayout()

        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: Notification.Name("TUIDidApplyingThemeChangedNotfication"), object: nil)
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
        backgroundColor = TUISwift.rgba(255, g: 255, b: 255, a: 1)

        lineView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#FFFFFF")

        moreButton.addTarget(self, action: #selector(clickMoreBtn(_:)), for: .touchUpInside)
        moreButton.setImage(getImageFromCache("TypeSelectorBtnHL_Black"), for: .normal)
        moreButton.setImage(getImageFromCache("TypeSelectorBtnHL_Black"), for: .highlighted)
        addSubview(moreButton)

        inputTextView.delegate = self
        inputTextView.font = normalFont
        inputTextView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_bg_color", defaultColor: "#FFFFFF")
        inputTextView.textColor = TUISwift.tuiChatDynamicColor("chat_input_text_color", defaultColor: "#000000")
        inputTextView.textContainerInset = rtlEdgeInsetsWithInsets(UIEdgeInsets(top: TUISwift.kScale390(9), left: TUISwift.kScale390(16), bottom: TUISwift.kScale390(9), right: TUISwift.kScale390(30)))
        inputTextView.textAlignment = TUISwift.isRTL() ? .right : .left
        inputTextView.returnKeyType = .send
        addSubview(inputTextView)

        keyboardButton.addTarget(self, action: #selector(clickKeyboardBtn(_:)), for: .touchUpInside)
        keyboardButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewKeyboard_img", defaultImage: "ToolViewKeyboard"), for: .normal)
        keyboardButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_ToolViewKeyboardHL_img", defaultImage: "ToolViewKeyboardHL"), for: .highlighted)
        keyboardButton.isHidden = true
        addSubview(keyboardButton)

        faceButton.addTarget(self, action: #selector(clickFaceBtn(_:)), for: .touchUpInside)
        faceButton.setImage(getImageFromCache("ToolViewEmotion"), for: .normal)
        faceButton.setImage(getImageFromCache("ToolViewEmotion"), for: .highlighted)
        addSubview(faceButton)

        micButton.addTarget(self, action: #selector(recordBtnDown(_:)), for: .touchDown)
        micButton.addTarget(self, action: #selector(recordBtnUp(_:)), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(recordBtnCancel(_:)), for: [.touchUpOutside, .touchCancel])
        micButton.addTarget(self, action: #selector(recordBtnDragExit(_:)), for: .touchDragExit)
        micButton.addTarget(self, action: #selector(recordBtnDragEnter(_:)), for: .touchDragEnter)
        micButton.setImage(getImageFromCache("ToolViewInputVoice"), for: .normal)
        addSubview(micButton)

        cameraButton.addTarget(self, action: #selector(clickCameraBtn(_:)), for: .touchUpInside)
        cameraButton.setImage(getImageFromCache("ToolViewInputCamera"), for: .normal)
        cameraButton.setImage(getImageFromCache("ToolViewInputCamera"), for: .highlighted)
        addSubview(cameraButton)

        initRecordView()
    }

    func initRecordView() {
        recordView.backgroundColor = TUISwift.rgba(255, g: 255, b: 255, a: 1)
        recordView.isHidden = true
        addSubview(recordView)

        recordView.addSubview(recordDeleteView)

        recordView.addSubview(recordBackgroudView)

        recordTimeLabel.textColor = .white
        recordTimeLabel.font = UIFont.systemFont(ofSize: 14)
        recordView.addSubview(recordTimeLabel)

        for _ in 0..<6 {
            let recordAnimateView = UIImageView()
            recordAnimateView.image = getImageFromCache("voice_record_animation")
            recordView.addSubview(recordAnimateView)
            recordAnimateViews.append(recordAnimateView)
        }

        recordView.addSubview(recordAnimateCoverView)

        recordTipsView.backgroundColor = .white
        recordTipsView.frame = CGRect(x: 0, y: -56, width: TUISwift.screen_Width(), height: 56)
        recordView.addSubview(recordTipsView)

        recordTipsLabel.textColor = TUISwift.rgba(102, g: 102, b: 102, a: 1)
        recordTipsLabel.textColor = .black
        recordTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordTipsTitle")
        recordTipsLabel.textAlignment = .center
        recordTipsLabel.font = UIFont.systemFont(ofSize: 14)
        recordTipsLabel.frame = CGRect(x: 0, y: 10, width: TUISwift.screen_Width(), height: 22)
        recordTipsView.addSubview(recordTipsLabel)

        setRecordStatus(.initial)
    }

    private func setRecordStatus(_ status: TUIRecordStatus) {
        switch status {
        case .initial, .record, .cancel:
            recordDeleteView.frame = CGRect(x: TUISwift.kScale390(16), y: recordDeleteView.frame.minY, width: 24, height: 24)
            if TUISwift.isRTL() {
                recordDeleteView.resetFrameToFitRTL()
            }
            recordDeleteView.image = getImageFromCache("voice_record_delete")
            recordBackgroudView.backgroundColor = TUISwift.rgba(20, g: 122, b: 255, a: 1)
            recordAnimateCoverView.backgroundColor = recordBackgroudView.backgroundColor
            recordAnimateCoverView.frame = recordAnimateCoverViewFrame ?? CGRect.zero
            recordTimeLabel.text = "0:00"
            recordTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordTipsTitle")

            if status == .record {
                recordView.isHidden = false
            } else {
                recordView.isHidden = true
            }
        case .delete:
            recordDeleteView.frame = CGRect(x: TUISwift.kScale390(16), y: recordDeleteView.frame.minY, width: 26, height: 30)
            if TUISwift.isRTL() {
                recordDeleteView.resetFrameToFitRTL()
            }
            recordDeleteView.image = getImageFromCache("voice_record_delete_ready")
            recordBackgroudView.backgroundColor = TUISwift.rgba(255, g: 88, b: 76, a: 1)
            recordAnimateCoverView.backgroundColor = recordBackgroudView.backgroundColor
            recordTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordCancelTipsTitle")

            recordView.isHidden = false
        }
    }

    func defaultLayout() {
        lineView.frame = CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: TUISwift.tLine_Height())

        let iconSize: CGFloat = 24
        moreButton.frame = CGRect(x: TUISwift.kScale390(16), y: TUISwift.kScale390(13), width: iconSize, height: iconSize)
        cameraButton.frame = CGRect(x: TUISwift.screen_Width() - TUISwift.kScale390(16) - iconSize, y: 13, width: iconSize, height: iconSize)
        micButton.frame = CGRect(x: TUISwift.screen_Width() - TUISwift.kScale390(56) - iconSize, y: 13, width: iconSize, height: iconSize)

        let faceSize: CGFloat = 19
        faceButton.frame = CGRect(x: micButton.frame.minX - TUISwift.kScale390(50), y: 15, width: faceSize, height: faceSize)

        keyboardButton.frame = faceButton.frame
        inputTextView.frame = CGRect(x: TUISwift.kScale390(56), y: 7, width: TUISwift.screen_Width() - TUISwift.kScale390(152), height: 36)

        recordView.frame = CGRect(x: 0, y: inputTextView.frame.minY, width: frame.width, height: inputTextView.frame.height)
        recordDeleteView.frame = CGRect(x: TUISwift.kScale390(16), y: 4, width: iconSize, height: iconSize)
        recordBackgroudView.frame = CGRect(x: TUISwift.kScale390(54), y: 0, width: frame.width - TUISwift.kScale390(70), height: recordView.frame.height)
        recordTimeLabel.frame = CGRect(x: TUISwift.kScale390(70), y: TUISwift.kScale390(7), width: 32, height: 22)

        let animationStartX: CGFloat = TUISwift.kScale390(112)
        let animationY: CGFloat = 8
        let animationSize: CGFloat = 20
        let animationSpace: CGFloat = TUISwift.kScale390(8)
        var animationCoverWidth: CGFloat = 0
        for i in 0..<recordAnimateViews.count {
            let animationView = recordAnimateViews[i]
            animationView.frame = CGRect(x: animationStartX + (animationSize + animationSpace) * CGFloat(i), y: animationY, width: animationSize, height: animationSize)
            animationCoverWidth = (animationSize + animationSpace) * CGFloat(i + 1)
        }
        recordAnimateCoverViewFrame = CGRect(x: animationStartX, y: animationY, width: animationCoverWidth, height: animationSize)
        recordAnimateCoverView.frame = recordAnimateCoverViewFrame ?? CGRect.zero
        applyBorderTheme()

        if TUISwift.isRTL() {
            for subview in subviews {
                subview.resetFrameToFitRTL()
            }
            for subview in recordView.subviews {
                subview.resetFrameToFitRTL()
            }
        }
    }

    func layoutButton(_ height: CGFloat) {
        var frame = frame
        let offset = height - frame.size.height
        frame.size.height = height
        self.frame = frame

        delegate?.inputBarDidChangeInputHeight(self, offset: offset)
    }

    @objc func onThemeChanged() {
        applyBorderTheme()
    }

    func applyBorderTheme() {
        recordBackgroudView.layer.masksToBounds = true
        recordBackgroudView.layer.cornerRadius = recordBackgroudView.frame.height / 2.0

        inputTextView.layer.masksToBounds = true
        inputTextView.layer.cornerRadius = inputTextView.frame.height / 2.0
        inputTextView.layer.borderWidth = 0.5
        inputTextView.layer.borderColor = TUISwift.rgba(221, g: 221, b: 221, a: 1).cgColor
    }

    func getImageFromCache(_ path: String) -> UIImage {
        return TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist(path)) ?? UIImage()
    }

    func getStickerFromCache(_ path: String) -> UIImage {
        return TUIImageCache.sharedInstance().getFaceFromCache(path) ?? UIImage()
    }

    // MARK: - Button events

    @objc func clickCameraBtn(_ sender: UIButton) {
        micButton.isHidden = false
        keyboardButton.isHidden = true
        inputTextView.isHidden = false
        faceButton.isHidden = false
        setRecordStatus(.cancel)
        delegate?.inputBarDidTouchCamera(self)
    }

    @objc func clickKeyboardBtn(_ sender: UIButton) {
        micButton.isHidden = false
        keyboardButton.isHidden = true
        inputTextView.isHidden = false
        faceButton.isHidden = false
        setRecordStatus(.cancel)
        layoutButton(inputTextView.frame.height + CGFloat(2 * TTextView_Margin))
        delegate?.inputBarDidTouchKeyboard(self)
    }

    @objc func clickFaceBtn(_ sender: UIButton) {
        micButton.isHidden = false
        faceButton.isHidden = true
        keyboardButton.isHidden = false
        inputTextView.isHidden = false
        setRecordStatus(.cancel)
        delegate?.inputBarDidTouchFace(self)
        keyboardButton.frame = faceButton.frame
    }

    @objc func clickMoreBtn(_ sender: UIButton) {
        delegate?.inputBarDidTouchMore(self)
    }

    @objc func recordBtnDown(_ sender: UIButton) {
        recorder.record()
    }

    @objc func recordBtnUp(_ sender: UIButton) {
        let interval = Date().timeIntervalSince(recordStartTime ?? Date())
        if interval < 1 {
            recorder.cancel()
        } else if interval > 60 {
            recorder.cancel()
        } else {
            recorder.stop()
            let path = recorder.recordedFilePath
            delegate?.inputBarDidSendVoice(self, path: path)
        }
        setRecordStatus(.cancel)
    }

    @objc func recordBtnCancel(_ gesture: UIGestureRecognizer) {
        setRecordStatus(.cancel)
        recorder.cancel()
    }

    @objc func recordBtnDragExit(_ sender: UIButton) {
        setRecordStatus(.delete)
    }

    @objc func recordBtnDragEnter(_ sender: UIButton) {
        setRecordStatus(.record)
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
            delegate?.inputTextViewShouldBeginTyping(textView)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        isFocusOn = false
        delegate?.inputTextViewShouldEndTyping(textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        if allowSendTypingStatusByChangeWord && isFocusOn && textView.textStorage.tui_getPlainString().count > 0 {
            delegate?.inputTextViewShouldBeginTyping(textView)
        }

        if isFocusOn && textView.textStorage.tui_getPlainString().count == 0 {
            delegate?.inputTextViewShouldEndTyping(textView)
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
            var textFrame = self.inputTextView.frame
            textFrame.size.height += newHeight - oldHeight
            self.inputTextView.frame = textFrame
            self.layoutButton(newHeight + CGFloat(2 * TTextView_Margin))
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.tui_contains("[") && text.tui_contains("]") {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                textView.textStorage.deleteCharacters(in: selectedRange)
            }
            var locations: [[NSValue: NSAttributedString]]? = nil
            let textChange = text.getAdvancedFormatEmojiString(withFont: normalFont, textColor: normalColor, emojiLocations: &locations)
            textView.textStorage.insert(textChange, at: textView.textStorage.length)
            DispatchQueue.main.async {
                self.inputTextView.selectedRange = NSRange(location: self.inputTextView.textStorage.length + 1, length: 0)
            }
            return false
        }

        if text == "\n" {
            let sp = textView.textStorage.tui_getPlainString().trimmingCharacters(in: .whitespaces)
            if sp.count == 0 {
                let ac = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitInputBlankMessageTitle"), message: nil, preferredStyle: .alert)
                ac.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Confirm"), style: .default, handler: nil))
                mm_viewController?.present(ac, animated: true, completion: nil)
            } else {
                delegate?.inputBarDidSendText(self, text: textView.textStorage.tui_getPlainString())
                clearInput()
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
                                    delegate?.inputBarDidDeleteAt(self, text: atText)
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
            delegate?.inputBarDidInputAt(self)
            return false
        }
        return true
    }

    // MARK: - TUIResponderTextViewDelegate

    func onDeleteBackward(_ textView: TUIResponderTextView_Minimalist) {
        delegate?.inputBarDidDeleteBackward(self)
    }

    // MARK: - TUIAudioRecorderDelegate

    func didCheckPermission(_ recorder: TUIAudioRecorder, _ isGranted: Bool, _ isFirstTime: Bool) {
        if isFirstTime {
            if !isGranted {
                showRequestMicAuthorizationAlert()
            }
            return
        }
        setRecordStatus(.record)
        recordStartTime = Date()
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
            self.mm_viewController?.present(ac, animated: true, completion: nil)
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
        let maxDuration = min(59.7, TUIChatConfig.shared.maxAudioRecordDuration)
        let seconds = Int(maxDuration - time)
        recordTimeLabel.text = String(format: "%d:%.2d", Int(time) / 60, Int(time) % 60 + 1)
        let width = recordAnimateCoverViewFrame?.size.width ?? 0
        let interval_ms = Int(time * 1000)
        let runloop_ms = 5 * 1000
        let offset_x = width * CGFloat(interval_ms % runloop_ms) / CGFloat(runloop_ms)
        recordAnimateCoverView.frame = CGRect(x: (recordAnimateCoverViewFrame?.origin.x ?? 0) + offset_x,
                                              y: recordAnimateCoverViewFrame?.origin.y ?? 0,
                                              width: width - offset_x,
                                              height: recordAnimateCoverViewFrame?.size.height ?? 0)
        if time > maxDuration {
            recorder.stop()
            setRecordStatus(.cancel)
            let path = recorder.recordedFilePath
            delegate?.inputBarDidSendVoice(self, path: path)
        }
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
        emojiTextAttachment.image = getStickerFromCache(emoji.path ?? "")

        // Set emoji size
        emojiTextAttachment.emojiSize = kTIMDefaultEmojiSize
        let str = NSAttributedString(attachment: emojiTextAttachment)

        let selectedRange = inputTextView.selectedRange
        if selectedRange.length > 0 {
            inputTextView.textStorage.deleteCharacters(in: selectedRange)
        }
        // Insert emoji image
        inputTextView.textStorage.insert(str, at: inputTextView.selectedRange.location)

        inputTextView.selectedRange = NSRange(location: inputTextView.selectedRange.location + 1, length: 0)
        resetTextStyle()

        if inputTextView.contentSize.height > CGFloat(TTextView_TextView_Height_Max) {
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
        clickKeyboardBtn(keyboardButton)
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
}
