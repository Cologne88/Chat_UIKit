import AVFoundation
import AVKit
import Photos
import TIMCommon
import UIKit

class TUIVideoCollectionCellScrollView: UIScrollView, UIScrollViewDelegate {
    var videoView: UIView!
    var videoViewNormalWidth: CGFloat = 0 {
        didSet {
            videoView.frame = CGRect(x: 0, y: 0, width: videoViewNormalWidth, height: videoViewNormalHeight)
            videoView.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        }
    }

    var videoViewNormalHeight: CGFloat = 0 {
        didSet {
            videoView.frame = CGRect(x: 0, y: 0, width: videoViewNormalWidth, height: videoViewNormalHeight)
            videoView.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 2.0
        videoViewNormalHeight = frame.size.height
        videoViewNormalWidth = frame.size.width
        videoView = UIView(frame: frame)
        addSubview(videoView)
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pictureZoomWithScale(_ zoomScale: CGFloat) {
        let imageScaleWidth = zoomScale * videoViewNormalWidth
        let imageScaleHeight = zoomScale * videoViewNormalHeight
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageScaleWidth < frame.size.width {
            imageX = floor((frame.size.width - imageScaleWidth) / 2.0)
        }
        if imageScaleHeight < frame.size.height {
            imageY = floor((frame.size.height - imageScaleHeight) / 2.0)
        }
        videoView.frame = CGRect(x: imageX, y: imageY, width: imageScaleWidth, height: imageScaleHeight)
        contentSize = CGSize(width: imageScaleWidth, height: imageScaleHeight)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return videoView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("BeginZooming")
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("EndZooming")
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageScaleWidth = scrollView.zoomScale * videoViewNormalWidth
        let imageScaleHeight = scrollView.zoomScale * videoViewNormalHeight
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageScaleWidth < frame.size.width {
            imageX = floor((frame.size.width - imageScaleWidth) / 2.0)
        }
        if imageScaleHeight < frame.size.height {
            imageY = floor((frame.size.height - imageScaleHeight) / 2.0)
        }
        videoView.frame = CGRect(x: imageX, y: imageY, width: imageScaleWidth, height: imageScaleHeight)
    }
}

class TUIVideoCollectionCell: TUIMediaCollectionCell {
    var scrollView: TUIVideoCollectionCellScrollView!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoPath: String?
    var videoUrl: URL?
    var isPlay: Bool = false
    var isSaveVideo: Bool = false
    var videoData: TUIVideoMessageCellData?
    private var thumbImageObservation: NSKeyValueObservation?
    private var videoProgressObservation: NSKeyValueObservation?
    private var videoPathObservation: NSKeyValueObservation?

    lazy var mainPlayBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.contentMode = .scaleToFill
        button.setImage(TUISwift.tuiChatCommonBundleImage("video_play_big"), for: .normal)
        button.addTarget(self, action: #selector(onPlayBtnClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var playBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.contentMode = .scaleToFill
        button.setImage(TUISwift.tuiChatCommonBundleImage("video_play"), for: .normal)
        button.addTarget(self, action: #selector(onPlayBtnClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.contentMode = .scaleToFill
        button.setImage(TUISwift.tuiChatCommonBundleImage("video_close"), for: .normal)
        button.addTarget(self, action: #selector(onCloseBtnClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    lazy var playTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "00:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var playProcessSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = .white
        slider.addTarget(self, action: #selector(onSliderValueChangedBegin), for: .touchDown)
        slider.addTarget(self, action: #selector(onSliderValueChanged), for: .touchUpInside)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    lazy var mainDownloadBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.contentMode = .scaleToFill
        button.setImage(TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("download")), for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(mainDownloadBtnClick), for: .touchUpInside)
        self.addSubview(button)
        return button
    }()

    lazy var animateCircleView: TUICircleLoadingView = {
        let view = TUICircleLoadingView(frame: CGRect(x: 0, y: 0, width: TUISwift.kScale390(40), height: TUISwift.kScale390(40)))
        view.progress = 0
        view.isHidden = true
        self.addSubview(view)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupRotationNotifications()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupRotationNotifications() {
        if #available(iOS 16.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange(_:)), name: NSNotification.Name("TUIMessageMediaViewDeviceOrientationChangeNotification"), object: nil)
        } else {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        videoPathObservation?.invalidate()
        videoPathObservation = nil
        videoProgressObservation?.invalidate()
        videoProgressObservation = nil
    }

    func setupViews() {
        scrollView = TUIVideoCollectionCellScrollView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        addSubview(scrollView)

        imageView = UIImageView()
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        addSubview(imageView)
        imageView.mm_fill()
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(mainPlayBtn)
        addSubview(mainDownloadBtn)
        addSubview(animateCircleView)
        addSubview(playBtn)
        addSubview(closeBtn)

        downloadBtn = UIButton(type: .custom)
        downloadBtn.contentMode = .scaleToFill
        downloadBtn.setImage(TUISwift.tuiChatCommonBundleImage("download"), for: .normal)
        downloadBtn.addTarget(self, action: #selector(onDownloadBtnClick), for: .touchUpInside)
        addSubview(downloadBtn)

        addSubview(playTimeLabel)
        addSubview(durationLabel)
        addSubview(playProcessSlider)
    }

    override func fill(with data: TUIMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIVideoMessageCellData else { return }
        videoData = data
        isSaveVideo = false

        let hasRiskContent = data.innerMessage.hasRiskContent
        if hasRiskContent {
            imageView.image = TUISwift.timCommonBundleThemeImage("", defaultImage: "icon_security_strike")
            for subview in subviews {
                if subview != scrollView && subview != closeBtn {
                    subview.isHidden = true
                }
            }
            return
        }

        let duration = data.videoItem?.duration ?? 0
        durationLabel.text = String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)

        imageView.image = nil
        if data.thumbImage == nil {
            data.downloadThumb()
        }

        thumbImageObservation = data.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.imageView.image = thumbImage
        }

        if !(videoData?.isVideoExist() ?? false) {
            mainDownloadBtn.isHidden = false
            mainPlayBtn.isHidden = true
            animateCircleView.isHidden = true
        } else {
            videoPath = videoData?.videoPath
            if let videoPath = videoPath {
                addPlayer(URL(fileURLWithPath: videoPath))
            }
        }

        videoProgressObservation = videoData?.observe(\.videoProgress, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            if progress == 100 {
                self.animateCircleView.progress = 99
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateCircleView.progress = 100
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.animateCircleView.progress = 0
                        self.mainDownloadBtn.isHidden = true
                        self.animateCircleView.isHidden = true
                        self.mainPlayBtn.isHidden = false
                    }
                }
            } else if progress > 1 && progress < 100 {
                self.animateCircleView.progress = CGFloat(progress)
                self.mainDownloadBtn.isHidden = true
                self.animateCircleView.isHidden = false
            } else {
                self.animateCircleView.progress = CGFloat(progress)
            }
        }

        videoPathObservation = videoData?.observe(\.videoPath, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let path = change.newValue, path.count > 0 else { return }

            // To match "take: 1"
            self.videoPathObservation?.invalidate()
            self.videoPathObservation = nil

            self.videoPath = path
            if self.isSaveVideo {
                self.saveVideo()
            }
            animateCircleView.isHidden = true
            self.addPlayer(URL(fileURLWithPath: path))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        mainDownloadBtn.sizeToFit()
        mainDownloadBtn.snp.makeConstraints { make in
            make.width.height.equalTo(65)
            make.center.equalToSuperview()
        }
        mainDownloadBtn.layer.cornerRadius = 32.5 // Half of 65

        animateCircleView.snp.remakeConstraints { make in
            make.height.width.equalTo(TUISwift.kScale390(40))
            make.center.equalToSuperview()
        }

        mainPlayBtn.snp.remakeConstraints { make in
            make.width.height.equalTo(65)
            make.center.equalTo(self)
        }
        closeBtn.snp.remakeConstraints { make in
            make.width.height.equalTo(31)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-48)
        }
        downloadBtn.snp.makeConstraints { make in
            make.width.height.equalTo(31)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-48)
        }
        playBtn.snp.remakeConstraints { make in
            make.width.height.equalTo(30)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-108)
        }
        playTimeLabel.snp.remakeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(21)
            make.left.equalTo(playBtn.snp.right).offset(12)
            make.centerY.equalTo(playBtn)
        }
        durationLabel.snp.remakeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(21)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(playBtn)
        }
        playProcessSlider.sizeToFit()
        playProcessSlider.snp.remakeConstraints { make in
            make.left.equalTo(playTimeLabel.snp.right).offset(10)
            make.right.equalTo(durationLabel.snp.left).offset(-10)
            make.centerY.equalTo(playBtn)
        }

        scrollView.snp.makeConstraints { make in
            make.width.height.centerX.centerY.equalToSuperview()
        }

        scrollView.videoViewNormalWidth = frame.width
        scrollView.videoViewNormalHeight = frame.height

        playerLayer?.frame = scrollView.bounds
        scrollView.videoView.layer.layoutIfNeeded()
    }

    func addPlayer(_ url: URL) {
        videoUrl = url
        if player == nil {
            player = AVPlayer(url: videoUrl!)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = scrollView.videoView.bounds
            scrollView.videoView.layer.insertSublayer(playerLayer!, at: 0)

            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 30), queue: nil) { [weak self] _ in
                guard let self = self else { return }
                let curTime = CMTimeGetSeconds(self.player?.currentItem?.currentTime() ?? CMTime.zero)
                let duration = CMTimeGetSeconds(self.player?.currentItem?.duration ?? CMTime.zero)
                let progress = curTime / duration
                self.playProcessSlider.value = Float(progress)
                self.playTimeLabel.text = String(format: "%02d:%02d", Int(curTime) / 60, Int(curTime) % 60)
            }
            addPlayerItemObserver()
        } else {
            removePlayerItemObserver()
            let item = AVPlayerItem(url: videoUrl!)
            player?.replaceCurrentItem(with: item)
            addPlayerItemObserver()
        }
    }

    func addPlayerItemObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(onVideoPlayEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func removePlayerItemObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func stopVideoPlayAndSave() {
        stopPlay()
        isSaveVideo = false
        TUITool.hideToast()
    }

    @objc func onPlayBtnClick() {
        if !(videoData?.isVideoExist() ?? false) {
            videoData?.downloadVideo()
        } else {
            if isPlay {
                stopPlay()
            } else {
                play()
            }
        }
    }

    @objc func onCloseBtnClick() {
        stopPlay()
        delegate?.onCloseMedia?(cell: self)
    }

    @objc func onVideoPlayEnd() {
        if playProcessSlider.value == 1 {
            player?.seek(to: CMTime.zero)
            stopPlay()
        }
    }

    @objc func onSliderValueChangedBegin(_ sender: Any) {
        player?.pause()
    }

    @objc func onSliderValueChanged(_ sender: Any) {
        if let slider = sender as? UISlider {
            let curTime = CMTimeGetSeconds(player?.currentItem?.duration ?? CMTime.zero) * Double(slider.value)
            player?.seek(to: CMTime(seconds: curTime, preferredTimescale: 30))
            play()
        }
    }

    func play() {
        isPlay = true
        player?.play()
        imageView.isHidden = true
        mainPlayBtn.isHidden = true
        playBtn.setImage(TUISwift.tuiChatCommonBundleImage("video_pause"), for: .normal)
    }

    func stopPlay() {
        let hasRiskContent = videoData?.innerMessage.hasRiskContent ?? false
        isPlay = false
        player?.pause()
        imageView.isHidden = false
        if !hasRiskContent {
            mainPlayBtn.isHidden = false
        }
        playBtn.setImage(TUISwift.tuiChatCommonBundleImage("video_play"), for: .normal)
    }

    @objc func mainDownloadBtnClick() {
        if !(videoData?.isVideoExist() ?? false) {
            videoData?.downloadVideo()
        }
    }

    @objc func onDownloadBtnClick() {
        if !videoData!.isVideoExist() {
            isSaveVideo = true
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitVideoDownloading"), duration: .infinity)
        } else {
            saveVideo()
        }
    }

    func saveVideo() {
        TUITool.hideToast()
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: self.videoPath!))
            request?.creationDate = Date()
        }) { success, _ in
            DispatchQueue.main.async {
                if success {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitVideoSavedSuccess"), duration: 1)
                } else {
                    TUITool.makeToastError(-1, msg: TUISwift.timCommonLocalizableString("TUIKitVideoSavedFailed"))
                }
            }
        }
    }

    @objc func onDeviceOrientationChange(_ noti: Notification) {
        let orientation = UIDevice.current.orientation
        reloadAllView()
    }

    func reloadAllView() {
        if player != nil {
            stopPlay()
            player = nil
        }
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
        }
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        for subview in subviews {
            subview.removeFromSuperview()
        }
        setupViews()
        if let data = videoData {
            fill(with: data)
        }
    }

    // MARK: - TUIMessageProgressManagerDelegate

    func onUploadProgress(_ msgID: String, progress: Int) {
        if msgID != videoData?.msgID {
            return
        }
        if videoData?.direction == .MsgDirectionOutgoing {
            videoData?.uploadProgress = UInt(progress)
        }
    }

    // MARK: - V2TIMAdvancedMsgListener

    func onRecvMessageModified(_ msg: V2TIMMessage) {
        if videoData?.innerMessage.msgID == msg.msgID {
            let hasRiskContent = msg.hasRiskContent
            if hasRiskContent {
                videoData?.innerMessage = msg
                showRiskAlert()
            }
        }
    }

    func showRiskAlert() {
        if player != nil {
            stopPlay()
        }
        let alertController = UIAlertController(title: nil,
                                                message: TUISwift.timCommonLocalizableString("TUIKitVideoCheckRisk"),
                                                preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: TUISwift.timCommonLocalizableString("TUIKitVideoCheckRiskCancel"),
                                         style: .cancel)
        { [weak self] _ in
            guard let self else { return }
            self.reloadAllView()
        }

        alertController.tuitheme_addAction(cancelAction)
        if let rootViewController = TUITool.applicationKeywindow()?.rootViewController {
            rootViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
