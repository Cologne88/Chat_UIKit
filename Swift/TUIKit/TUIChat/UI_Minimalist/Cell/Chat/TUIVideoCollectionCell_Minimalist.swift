import AVFoundation
import AVKit
import MediaPlayer
import Photos
import TIMCommon
import UIKit

class TUIVideoCollectionCell_Minimalist: TUIMediaCollectionCell_Minimalist {
    var player: AVPlayer?
    var videoPath: String?
    var videoUrl: URL?
    var isPlay: Bool = false
    var isSaveVideo: Bool = false
    var videoData: TUIVideoMessageCellData?
    private var thumbImageObservation: NSKeyValueObservation?
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        videoPathObservation?.invalidate()
        videoPathObservation = nil
    }

    func setupViews() {
        imageView = UIImageView()
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        addSubview(imageView)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(mainPlayBtn)
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

        let duration = data.videoItem?.duration ?? 00
        durationLabel.text = String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)

        imageView.image = nil
        if data.thumbImage == nil {
            data.downloadThumb()
        }

        thumbImageObservation = data.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.imageView.image = thumbImage
        }

        if !data.isVideoExist() {
            data.getVideoUrl { [weak self] url in
                guard let self = self else { return }
                if let urlString = url, let videoURL = URL(string: urlString) {
                    self.addPlayer(videoURL)
                }
            }
            data.downloadVideo()
        } else {
            videoPath = data.videoPath
            if let videoPath = videoPath {
                addPlayer(URL(fileURLWithPath: videoPath))
            }
        }

        videoPathObservation = videoData?.observe(\.videoPath, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let path = change.newValue, path.count > 0 else { return }

            self.videoPathObservation?.invalidate()
            self.videoPathObservation = nil

            self.videoPath = path
            if self.isSaveVideo {
                self.saveVideo()
            }

            if self.player?.status == .failed || self.player?.status == .readyToPlay {
                self.addPlayer(URL(fileURLWithPath: path))
            }
        }

        videoPathObservation = data.observe(\.videoPath, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let path = change.newValue else { return }
            self.videoPath = path
            if self.isSaveVideo {
                self.saveVideo()
            }

            if self.player?.status == .failed || self.player?.status == .readyToPlay {
                self.addPlayer(URL(fileURLWithPath: self.videoPath ?? ""))
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
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
    }

    func addPlayer(_ url: URL) {
        videoUrl = url
        if player == nil {
            player = AVPlayer(url: videoUrl!)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = bounds
            layer.insertSublayer(playerLayer, at: 0)

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

    // MARK: -  Player event

    @objc func onPlayBtnClick() {
        if isPlay {
            stopPlay()
        } else {
            play()
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
        isPlay = false
        player?.pause()
        mainPlayBtn.isHidden = false
        playBtn.setImage(TUISwift.tuiChatCommonBundleImage("video_play"), for: .normal)
    }

    // MARK: - Video save

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
}
