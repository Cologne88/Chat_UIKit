import AVFoundation
import TIMCommon
import UIKit

class TUICaptureVideoPreviewViewController: UIViewController {
    var fileURL: URL
    var player: AVPlayer?
    var item: AVPlayerItem?
    var playerLayer: AVPlayerLayer?
    var commitButton: UIButton?
    var cancelButton: UIButton?

    var lastRect: CGRect = .zero
    var onShow: Bool = false
    var onReadyToPlay: Bool = false

    var commitBlock: (() -> Void)?
    var cancelBlock: (() -> Void)?

    init(videoURL: URL) {
        self.fileURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black

        self.item = AVPlayerItem(url: self.fileURL)
        self.player = AVPlayer(playerItem: self.item)
        self.playerLayer = AVPlayerLayer(player: self.player)
        if let playerLayer = self.playerLayer {
            self.view.layer.addSublayer(playerLayer)
        }

        self.commitButton = UIButton(type: .custom)
        let commitImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camer_commit"))
        self.commitButton?.setImage(commitImage, for: .normal)

        let commitBGImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camer_commitBg"))
        self.commitButton?.setBackgroundImage(commitBGImage, for: .normal)

        self.commitButton?.addTarget(self, action: #selector(self.commitButtonClick(_:)), for: .touchUpInside)
        if let commitButton = self.commitButton {
            self.view.addSubview(commitButton)
        }

        self.cancelButton = UIButton(type: .custom)
        let cancelButtonBGImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camera_cancel"))
        self.cancelButton?.setBackgroundImage(cancelButtonBGImage?.rtlImageFlippedForRightToLeftLayoutDirection(), for: .normal)

        self.cancelButton?.addTarget(self, action: #selector(self.cancelButtonClick(_:)), for: .touchUpInside)
        if let cancelButton = self.cancelButton {
            self.view.addSubview(cancelButton)
        }

        self.item?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playFinished(_:)), name: .AVPlayerItemDidPlayToEndTime, object: self.item)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let statusNumber = change?[.newKey] as? NSNumber, let status = AVPlayer.Status(rawValue: statusNumber.intValue) {
                if status == .readyToPlay {
                    self.onReadyToPlay = true
                    self.playVideo()
                }
            }
        }
    }

    func playVideo() {
        DispatchQueue.main.async {
            if self.onShow && self.onReadyToPlay {
                self.player?.play()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.onShow = true
        self.playVideo()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !self.lastRect.equalTo(self.view.bounds) {
            self.lastRect = self.view.bounds

            self.playerLayer?.frame = self.view.bounds

            let commitButtonWidth: CGFloat = 80.0
            let buttonDistance = (self.view.bounds.size.width - 2 * commitButtonWidth) / 3.0
            let commitButtonY = self.view.bounds.size.height - commitButtonWidth - 50.0
            let commitButtonX = 2 * buttonDistance + commitButtonWidth
            self.commitButton?.frame = CGRect(x: commitButtonX, y: commitButtonY, width: commitButtonWidth, height: commitButtonWidth)

            let cancelButtonX = commitButtonWidth
            self.cancelButton?.frame = CGRect(x: cancelButtonX, y: commitButtonY, width: commitButtonWidth, height: commitButtonWidth)
            if TUISwift.isRTL() {
                self.commitButton?.resetFrameToFitRTL()
                self.cancelButton?.resetFrameToFitRTL()
            }
        }
    }

    @objc func commitButtonClick(_ btn: UIButton) {
        if let commitBlock = self.commitBlock {
            self.removeObserver()
            commitBlock()
        }
    }

    @objc func cancelButtonClick(_ btn: UIButton) {
        if let cancelBlock = self.cancelBlock {
            self.removeObserver()
            cancelBlock()
        }
    }

    @objc func playFinished(_ noti: Notification) {
        self.player?.seek(to: CMTimeMake(value: 0, timescale: 1))
        self.player?.play()
    }

    func removeObserver() {
        self.item?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
    }
}
