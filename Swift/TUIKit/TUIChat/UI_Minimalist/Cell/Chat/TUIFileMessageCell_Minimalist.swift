import ImSDK_Plus
import TIMCommon
import TUICore
import UIKit

class TUIFileMessageCell_Minimalist: TUIBubbleMessageCell_Minimalist, V2TIMSDKListener, TUIMessageProgressManagerDelegate {
    var fileData: TUIFileMessageCellData?

    lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 208/255.0, green: 228/255.0, blue: 255/255.0, alpha: 1.0)
        return view
    }()

    lazy var fileContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
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
        imageView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("msg_file"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()

    lazy var lengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TUISwift.rgba(122, g: 122, b: 122, a: 1)
        return label
    }()

    lazy var downloadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("file_download"))
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(downloadClick))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()

    // Life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        bubbleView.addSubview(fileContainer)
        fileContainer.addSubview(progressView)
        fileContainer.addSubview(fileImageView)
        fileContainer.addSubview(fileNameLabel)
        bubbleView.addSubview(lengthLabel)
        contentView.addSubview(downloadImageView)

       V2TIMManager.sharedInstance().addIMSDKListener(listener: self)
        TUIMessageProgressManager.shared.addDelegate(self)
    }

    @objc private func downloadClick() {
        downloadImageView.frame = .zero
        delegate?.onSelectMessage(self)
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUIFileMessageCellData else { return }

        fileData = data
        fileNameLabel.text = data.fileName
        lengthLabel.text = formatLength(Int(data.length))

        DispatchQueue.main.async {
            guard let msgID = data.msgID else { return }
            let uploadProgress = TUIMessageProgressManager.shared.uploadProgress(forMessage: msgID)
            let downloadProgress = TUIMessageProgressManager.shared.downloadProgress(forMessage: msgID)
            self.onUploadProgress(msgID: msgID, progress: uploadProgress)
            self.onDownloadProgress(msgID: msgID, progress: downloadProgress)
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

        var containerSize = CGSize.zero
        if let data = fileData {
            containerSize = TUIFileMessageCell_Minimalist.getContentSize(data)
        }
        fileContainer.snp.remakeConstraints { make in
            make.width.equalTo(containerSize.width - TUISwift.kScale390(32))
            make.height.equalTo(48)
            make.leading.equalTo(TUISwift.kScale390(16))
            make.top.equalTo(bubbleView).offset(8)
        }

        let fileImageSize: CGFloat = 24
        fileImageView.snp.remakeConstraints { make in
            make.leading.equalTo(container).offset(TUISwift.kScale390(17))
            make.top.equalTo(container).offset(TUISwift.kScale390(12))
            make.size.equalTo(fileImageSize)
        }

        fileNameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(fileImageView.snp.trailing).offset(TUISwift.kScale390(8))
            make.top.equalTo(15)
            make.trailing.equalTo(container).offset(-TUISwift.kScale390(12))
            make.height.equalTo(17)
        }

        lengthLabel.snp.remakeConstraints { make in
            make.leading.equalTo(container).offset(TUISwift.kScale390(22))
            make.bottom.equalTo(container).offset(-11)
            make.size.equalTo(CGSize(width: 150, height: 14))
        }

        if !(fileData?.isLocalExist() ?? false) && !(fileData?.isDownloading ?? false) {
            let downloadSize: CGFloat = 16
            downloadImageView.snp.remakeConstraints { make in
                if fileData?.direction == .incoming {
                    make.leading.equalTo(bubbleView.snp.trailing).offset(TUISwift.kScale390(8))
                } else {
                    make.trailing.equalTo(bubbleView.snp.leading).offset(-TUISwift.kScale390(8))
                }
                make.centerY.equalTo(lengthLabel)
                make.height.width.equalTo(downloadSize)
            }
        } else {
            downloadImageView.frame = .zero
        }

        progressView.snp.remakeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(0)
            make.width.equalTo(progressView.mm_w != 0 ? progressView.mm_w : 1)
            make.height.equalTo(fileContainer.mm_h)
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
        if !(fileData?.isLocalExist() ?? false) && !(fileData?.isDownloading ?? false) {
            downloadImageView.isHidden = false
        } else {
            downloadImageView.isHidden = true
        }

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
                make.width.equalTo(self.fileContainer.mm_w * CGFloat(progress)/100.0)
            }
        } completion: { _ in
            if progress == 0 || progress >= 100 {
                self.progressView.isHidden = true
                self.indicator.stopAnimating()
                self.lengthLabel.text = self.formatLength(Int(self.fileData?.length ?? 0))
                self.downloadImageView.isHidden = true
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
        let str = String(format: "%4.2f%@", len, array[factor])

        if (fileData?.isDownloading ?? false) || (length == 0 && (fileData?.status == .sending || fileData?.status == .sending2)) {
            return String(format: "%zd%%", fileData?.direction == .incoming ? fileData?.downladProgress ?? 0 : fileData?.uploadProgress ?? 0)
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
        animateHighlightView.frame = bubbleView.bounds
        animateHighlightView.alpha = 0.1
        container.addSubview(animateHighlightView)
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

    // MARK: - V2TIMSDKListener

    func onConnectSuccess() {
        if let data = fileData {
            fill(with: data)
        }
    }

    // MARK: - TUIMessageCellProtocol

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        return CGSize(width: TUISwift.kScale390(250), height: 90)
    }
}
