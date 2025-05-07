import ImSDK_Plus
import TIMCommon
import TUICore
import UIKit

class TUIFileMessageCell: TUIBubbleMessageCell, V2TIMSDKListener, TUIMessageProgressManagerDelegate {
    var fileData: TUIFileMessageCellData?

    lazy var bubbleImageView: UIImageView = {
        let view = UIImageView(frame: container.bounds)
        view.isHidden = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()

    lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    lazy var borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0.5
        layer.strokeColor = UIColor(red: 221 / 255.0, green: 221 / 255.0, blue: 221 / 255.0, alpha: 1.0).cgColor
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }()

    lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 208 / 255.0, green: 228 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        return view
    }()

    lazy var fileContainer: UIView = {
        let view = UIView()
        view.backgroundColor = TUISwift.tuiChatDynamicColor("chat_file_message_bg_color", defaultColor: "#FFFFFF")
        return view
    }()

    lazy var animateHighlightView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    lazy var fileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("msg_file_p"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_file_message_title_color", defaultColor: "#000000")
        return label
    }()

    lazy var lengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_file_message_subtitle_color", defaultColor: "#888888")
        return label
    }()

    lazy var downloadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("file_download"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(downloadClick))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        container.addSubview(bubbleImageView)
        securityStrikeView = TUISecurityStrikeView()
        container.addSubview(securityStrikeView)
        container.addSubview(fileContainer)

        fileContainer.addSubview(progressView)
        fileContainer.addSubview(fileNameLabel)
        fileContainer.addSubview(lengthLabel)
        fileContainer.addSubview(fileImageView)

        fileContainer.layer.insertSublayer(borderLayer, at: 0)
        fileContainer.layer.mask = maskLayer

        V2TIMManager.sharedInstance().addIMSDKListener(listener: self)
        TUIMessageProgressManager.shared.addDelegate(self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup views

    @objc private func downloadClick() {
        downloadImageView.frame = .zero
        _ = delegate?.onSelectMessage(self)
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUIFileMessageCellData else { return }

        fileData = data
        fileNameLabel.text = data.fileName
        lengthLabel.text = formatLength(Int(data.length))

        if let fileName = data.fileName {
            let path = getImagePathByCurrentFileType((fileName as NSString).pathExtension)
            fileImageView.image = TUIImageCache.sharedInstance().getResourceFromCache(path)
        }
        prepareReactTagUI(container)

        securityStrikeView.isHidden = true
        let hasRiskContent = messageData?.innerMessage?.hasRiskContent ?? false
        if hasRiskContent {
            bubbleImageView.image = getErrorBubble()
            securityStrikeView.isHidden = false
            readReceiptLabel.isHidden = true
            retryView.isHidden = false
        }

        DispatchQueue.main.async {
            if let msgID = data.msgID {
                let uploadProgress = TUIMessageProgressManager.shared.uploadProgress(forMessage: msgID)
                let downloadProgress = TUIMessageProgressManager.shared.downloadProgress(forMessage: msgID)
                self.onUploadProgress(msgID: msgID, progress: uploadProgress)
                self.onDownloadProgress(msgID: msgID, progress: downloadProgress)
            }
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()

        // Update the layers after fileContainer's frame is layout.
        var corner: UIRectCorner = [.bottomLeft, .bottomRight, .topLeft]
        if data.direction == .incoming {
            corner = [.bottomLeft, .bottomRight, .topRight]
        }
        let bezierPath = UIBezierPath(roundedRect: fileContainer.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 10, height: 10))
        maskLayer.path = bezierPath.cgPath
        borderLayer.path = bezierPath.cgPath
    }

    func getErrorBubble() -> UIImage? {
        if messageData?.direction == .incoming {
            return TUIBubbleMessageCell.incommingErrorBubble
        } else {
            return TUIBubbleMessageCell.outgoingErrorBubble
        }
    }

    func getImagePathByCurrentFileType(_ pathExtension: String) -> String {
        if !pathExtension.isEmpty {
            if pathExtension.hasSuffix("ppt") || pathExtension.hasSuffix("key") || pathExtension.hasSuffix("pdf") {
                return TUISwift.tuiChatImagePath("msg_file_p")
            }
        }
        return TUISwift.tuiChatImagePath("msg_file")
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !CGRectEqualToRect(maskLayer.frame, fileContainer.bounds) else { return }

        maskLayer.frame = fileContainer.bounds
        borderLayer.frame = fileContainer.bounds
    }

    override func updateConstraints() {
        super.updateConstraints()
        guard let fileData = fileData else { return }

        let fileContainerSize = TUIFileMessageCell.getFileContentSize(fileData)

        fileContainer.snp.remakeConstraints { make in
            make.center.equalTo(container)
            make.size.equalTo(fileContainerSize)
        }

        let imageHeight = fileContainerSize.height - 2 * CGFloat(TFileMessageCell_Margin)
        let imageWidth = imageHeight
        fileImageView.snp.remakeConstraints { make in
            make.leading.equalTo(fileContainer.snp.leading).offset(CGFloat(TFileMessageCell_Margin))
            make.top.equalTo(fileContainer.snp.top).offset(CGFloat(TFileMessageCell_Margin))
            make.size.equalTo(CGSize(width: imageWidth, height: imageHeight))
        }

        let textWidth = fileContainerSize.width - 2 * CGFloat(TFileMessageCell_Margin) - imageWidth
        let nameSize = fileNameLabel.sizeThatFits(fileContainerSize)
        fileNameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(fileImageView.snp.trailing).offset(CGFloat(TFileMessageCell_Margin))
            make.top.equalTo(fileImageView)
            make.size.equalTo(CGSize(width: textWidth, height: nameSize.height))
        }

        let lengthSize = lengthLabel.sizeThatFits(fileContainerSize)
        lengthLabel.snp.remakeConstraints { make in
            make.leading.equalTo(fileNameLabel)
            make.top.equalTo(fileNameLabel.snp.bottom).offset(CGFloat(TFileMessageCell_Margin) * 0.5)
            make.size.equalTo(CGSize(width: textWidth, height: lengthSize.height))
        }

        if (messageData?.messageContainerAppendSize.height ?? 0) > 0 {
            fileContainer.snp.remakeConstraints { make in
                make.center.equalTo(container)
                make.size.equalTo(container)
            }
            bubbleImageView.isHidden = false
        }

//        maskLayer.frame = fileContainer.bounds
//        borderLayer.frame = fileContainer.bounds
//
//        var corner: UIRectCorner = [.bottomLeft, .bottomRight, .topLeft]
//        if fileData.direction == .incoming {
//            corner = [.bottomLeft, .bottomRight, .topRight]
//        }
//
//        let bezierPath = UIBezierPath(roundedRect: fileContainer.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 10, height: 10))
//        maskLayer.path = bezierPath.cgPath
//        borderLayer.path = bezierPath.cgPath

        let hasRiskContent = messageData?.innerMessage?.hasRiskContent ?? false
        if hasRiskContent {
            fileContainer.snp.remakeConstraints { make in
                make.top.equalTo(container).offset(13)
                make.leading.equalTo(12)
                make.size.equalTo(fileContainerSize)
            }
            bubbleImageView.snp.remakeConstraints { make in
                make.leading.equalTo(0)
                make.size.equalTo(container)
                make.top.equalTo(container)
            }
            securityStrikeView.snp.remakeConstraints { make in
                make.top.equalTo(fileContainer.snp.bottom)
                make.width.equalTo(container)
                make.bottom.equalTo(container).offset(-(messageData?.messageContainerAppendSize.height ?? 0))
            }
            bubbleImageView.isHidden = false
        } else {
            bubbleImageView.isHidden = true
        }

        progressView.snp.remakeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(0)
            make.width.equalTo(progressView.frame.width > 0 ? progressView.frame.width : 1)
            make.height.equalTo(fileContainer.frame.height)
        }
    }

    // MARK: - TUIMessageProgressManagerDelegate

    @objc func onUploadProgress(msgID: String, progress: Int) {
        guard msgID == fileData?.msgID else { return }
        fileData?.uploadProgress = UInt(progress)
        updateUploadProgress(progress)
    }

    @objc func onDownloadProgress(msgID: String, progress: Int) {
        guard msgID == fileData?.msgID else { return }
        fileData?.downladProgress = UInt(progress)
        updateDownloadProgress(progress)
    }

    func onMessageSendingResultChanged(type: TUIMessageSendingResultType, messageID: String) {}

    private func updateUploadProgress(_ progress: Int) {
        indicator.startAnimating()
        progressView.isHidden = true
        lengthLabel.text = formatLength(Int(fileData?.length ?? 0))
        print("updateProgress:\(progress),isLocalExist:\(fileData?.isLocalExist() ?? false),isDownloading:\(fileData?.isDownloading ?? false)")
        if progress >= 100 || progress == 0 {
            indicator.stopAnimating()
            return
        }
        showProgressLoadingAnimation(progress)
    }

    private func updateDownloadProgress(_ progress: Int) {
        indicator.startAnimating()
        progressView.isHidden = true
        lengthLabel.text = formatLength(Int(fileData?.length ?? 0))

        if progress >= 100 || progress == 0 {
            indicator.stopAnimating()
            return
        }

        showProgressLoadingAnimation(progress)
    }

    private func showProgressLoadingAnimation(_ progress: Int) {
        progressView.isHidden = false
        print("showProgressLodingAnimation:\(progress)")
        UIView.animate(withDuration: 0.25) {
            self.progressView.snp.updateConstraints { make in
                make.width.equalTo(self.fileContainer.mm_w * CGFloat(progress) / 100.0)
            }
        } completion: { _ in
            if progress == 0 || progress >= 100 {
                self.progressView.isHidden = true
                self.indicator.stopAnimating()
                self.lengthLabel.text = self.formatLength(Int(self.fileData?.length ?? 0))
            }
        }

        lengthLabel.text = formatLength(Int(fileData?.length ?? 0))
    }

    private func formatLength(_ length: Int) -> String {
        var len = Double(length)
        let array = ["Bytes", "K", "M", "G", "T"]
        var factor = 0
        while len > 1024 {
            len /= 1024
            factor += 1
            if factor >= 4 {
                break
            }
        }
        var str = String(format: "%4.2f%@", len, array[factor])

        if fileData?.direction == .outgoing {
            if length == 0 && (fileData?.status == .sending || fileData?.status == .sending2) {
                str = String(format: "%zd%%", fileData?.direction == .incoming ? (fileData?.downladProgress ?? 0) : (fileData?.uploadProgress ?? 0))
            }
        } else {
            if !(fileData?.isLocalExist() ?? false) && !(fileData?.isDownloading ?? false) {
                str = String(format: "%@ %@", str, TUISwift.timCommonLocalizableString("TUIKitNotDownload"))
            }
        }

        return str
    }

    override open func highlightWhenMatchKeyword(_ keyword: String?) {
        if let _ = keyword {
            if highlightAnimating {
                return
            }
            animate(times: 3)
        }
    }

    private func animate(times: Int) {
        var times = times
        times -= 1
        if times < 0 {
            animateHighlightView.removeFromSuperview()
            highlightAnimating = false
            return
        }
        highlightAnimating = true
        animateHighlightView.frame = container.bounds
        animateHighlightView.alpha = 0.1
        fileContainer.addSubview(animateHighlightView)
        UIView.animate(withDuration: 0.25) {
            self.animateHighlightView.alpha = 0.5
        } completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.animateHighlightView.alpha = 0.1
            } completion: { _ in
                if let keyword = self.messageData?.highlightKeyword, !keyword.isEmpty {
                    self.animate(times: 0)
                    return
                }
                self.animate(times: times)
            }
        }
    }

    func prepareReactTagUI(_ containerView: UIView) {
        let param: [String: Any] = ["TUICore_TUIChatExtension_ChatMessageReactPreview_Delegate": self]
        TUICore.raiseExtension("TUICore_TUIChatExtension_ChatMessageReactPreview_ClassicExtensionID", parentView: containerView, param: param)
    }

    // MARK: - V2TIMSDKListener

    func onConnectSuccess() {
        if let data = fileData {
            fill(with: data)
        }
    }

    // MARK: - TUIMessageCellProtocol

    class func getFileContentSize(_ data: TUIMessageCellData) -> CGSize {
        let hasRiskContent = data.innerMessage?.hasRiskContent ?? false
        if hasRiskContent {
            return CGSize(width: 237, height: 62)
        }
        return TUISwift.tFileMessageCell_Container_Size()
    }

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        var size = getFileContentSize(data)
        let hasRiskContent = data.innerMessage?.hasRiskContent ?? false
        if hasRiskContent {
            let bubbleTopMargin: CGFloat = 12
            let bubbleBottomMargin: CGFloat = 12
            size.width = max(size.width, 261)
            size.height += bubbleTopMargin
            size.height += kTUISecurityStrikeViewTopLineMargin
            size.height += CGFloat(kTUISecurityStrikeViewTopLineToBottom)
            size.height += bubbleBottomMargin
        }
        return size
    }
}
