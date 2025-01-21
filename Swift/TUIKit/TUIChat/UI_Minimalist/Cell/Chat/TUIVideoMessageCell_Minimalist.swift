import TIMCommon
import UIKit

class TUIVideoMessageCell_Minimalist: TUIMessageCell_Minimalist, TUIMessageProgressManagerDelegate {
    private var videoData: TUIVideoMessageCellData?
    private var videoTranscodingObservation: NSKeyValueObservation?
    private var thumbImageObservation: NSKeyValueObservation?
    private var thumbProgressObservation: NSKeyValueObservation?
    private var uploadProgressObservation: NSKeyValueObservation?
    
    lazy var thumb: UIImageView = {
        let image = UIImageView()
        image.layer.cornerRadius = 5.0
        image.layer.masksToBounds = true
        image.contentMode = .scaleAspectFit
        image.backgroundColor = .clear
        image.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return image
    }()

    lazy var play: UIImageView = {
        let image = UIImageView(frame: CGRect(x: 0, y: 0, width: TUISwift.tVideoMessageCell_Play_Size().width, height: TUISwift.tVideoMessageCell_Play_Size().height))
        image.contentMode = .scaleAspectFit
        image.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("play_normal"))
        return image
    }()

    lazy var animateCircleView: TUICircleLoadingView = {
        let view = TUICircleLoadingView(frame: CGRectMake(0, 0, TUISwift.kScale390(40), TUISwift.kScale390(40)))
        view.progress = 0
        return view
    }()

    lazy var progress: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.layer.cornerRadius = 5.0
        label.isHidden = true
        label.backgroundColor = TUISwift.tVideoMessageCell_Progress_Color()
        label.layer.masksToBounds = true
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return label
    }()
                                        
    lazy var animateHighlightView: UIView? = {
        let view = UIView()
        view.backgroundColor = .orange
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videoTranscodingObservation?.invalidate()
        videoTranscodingObservation = nil
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        thumbProgressObservation?.invalidate()
        thumbProgressObservation = nil
        uploadProgressObservation?.invalidate()
        uploadProgressObservation = nil
    }

    private func setupViews() {
        container.addSubview(thumb)
        thumb.addSubview(play)
        thumb.addSubview(animateCircleView)
        container.addSubview(progress)

        msgTimeLabel.textColor = TUISwift.rgb(255.0, green: 255.0, blue: 255.0)
        TUIMessageProgressManager.shared.addDelegate(self)
    }
    
    override func fill(with data: TUIMessageCellData) {
        super.fill(with: data)
        guard let videoData = data as? TUIVideoMessageCellData else { return }
        self.videoData = videoData
        thumb.image = nil
        if videoData.thumbImage == nil {
            videoData.downloadThumb()
        }
        
        if videoData.isPlaceHolderCellData {
            thumb.backgroundColor = .gray
            animateCircleView.progress = data.videoTranscodingProgress * 100
            play.isHidden = true
            indicator.isHidden = true
            animateCircleView.isHidden = false
            
            videoTranscodingObservation = self.videoData?.observe(\.videoTranscodingProgress, options: [.new, .initial]) { [weak self] _, change in
                guard let self = self, let progress = change.newValue else { return }
                self.animateCircleView.progress = progress * 100
            }
            if let thumbImage = videoData.thumbImage {
                thumb.image = thumbImage
            }
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
            return
        } else {
            animateCircleView.isHidden = true
        }
        
        thumbImageObservation = self.videoData?.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.thumb.image = thumbImage
        }

        if data.direction == .MsgDirectionIncoming {
            thumbProgressObservation = self.videoData?.observe(\.thumbProgress, options: [.new, .initial]) { [weak self] _, change in
                guard let self = self, let progress = change.newValue else { return }
                self.progress.text = "\(progress)%"
                self.progress.isHidden = progress >= 100 || progress == 0
                self.play.isHidden = !self.progress.isHidden
            }
        } else {
            uploadProgressObservation = self.videoData?.observe(\.uploadProgress, options: [.new, .initial]) { [weak self] _, _ in
                guard let self = self else { return }
                self.play.isHidden = !self.progress.isHidden
            }
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
        
        thumb.snp.remakeConstraints { make in
            make.edges.equalTo(container)
        }
        
        play.snp.remakeConstraints { make in
            make.size.equalTo(TUISwift.tVideoMessageCell_Play_Size())
            make.center.equalTo(thumb)
        }
        
        msgTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(messageData.msgStatusSize.height)
            make.bottom.equalTo(container).offset(-TUISwift.kScale390(9))
            make.trailing.equalTo(container).offset(-TUISwift.kScale390(8))
        }
        
        msgStatusView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(messageData.msgStatusSize.height)
            make.bottom.trailing.equalTo(msgTimeLabel)
        }
        
        animateCircleView.snp.remakeConstraints { make in
            make.center.equalTo(thumb)
            make.size.equalTo(CGSize(width: TUISwift.kScale390(40), height: TUISwift.kScale390(40)))
        }
    }
    
    override func highlight(whenMatchKeyword keyword: String?) {
        if keyword != nil {
            if highlightAnimating {
                return
            }
            animate(times: 3)
        }
    }
    
    func animate(times: Int) {
        var times = times
        times -= 1
        if times < 0 {
            animateHighlightView?.removeFromSuperview()
            highlightAnimating = false
            return
        }
        highlightAnimating = true
        animateHighlightView?.frame = container.bounds
        animateHighlightView?.alpha = 0.1
        if animateHighlightView != nil {
            container.addSubview(animateHighlightView!)
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.animateHighlightView?.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) {
                self.animateHighlightView?.alpha = 0.1
            } completion: { _ in
                if let videoData = self.videoData, !(videoData.highlightKeyword?.isEmpty ?? false) {
                    self.animate(times: 0)
                    return
                }
                self.animate(times: times)
            }

        })
    }
    
    // MARK: - TUIMessageProgressManagerDelegate
    
    func onUploadProgress(msgID: String, progress: Int) {
        if msgID != videoData?.msgID {
            return
        }
        if videoData?.direction == .MsgDirectionOutgoing {
            videoData?.uploadProgress = UInt(progress)
        }
    }
    
    func onDownloadProgress(msgID: String, progress: Int) {}
    func onMessageSendingResultChanged(type: TUIMessageSendingResultType, messageID: String) {}
    
    // MARK: - TUIMessageCellProtocol
    
    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let videoCellData = data as? TUIVideoMessageCellData else {
            assertionFailure("data must be kind of TUIVideoMessageCellData")
            return CGSize.zero
        }
        
        var size = CGSize.zero
        var isDir = ObjCBool(false)
        if !videoCellData.snapshotPath.isEmpty && FileManager.default.fileExists(atPath: videoCellData.snapshotPath, isDirectory: &isDir) {
            if !isDir.boolValue {
                if let image = UIImage(contentsOfFile: videoCellData.snapshotPath) {
                    size = image.size
                }
            }
        } else {
            size = videoCellData.snapshotItem?.size ?? CGSize.zero
        }
        
        if size == CGSize.zero {
            return size
        }
        
        let widthMax = TUISwift.kScale390(250)
        let heightMax = TUISwift.kScale390(250)
        if size.height > size.width {
            size.width = size.width / size.height * heightMax
            size.height = heightMax
        } else {
            size.height = size.height / size.width * widthMax
            size.width = widthMax
        }
        
        return size
    }
}
