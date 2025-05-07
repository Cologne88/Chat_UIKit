import Photos
import TIMCommon
import TUICore
import UIKit

class TUIImageCollectionCellScrollView: UIScrollView, UIScrollViewDelegate {
    var containerView: UIView
    var imageNormalWidth: CGFloat {
        didSet {
            updateContainerViewFrame()
        }
    }

    var imageNormalHeight: CGFloat {
        didSet {
            updateContainerViewFrame()
        }
    }

    private func updateContainerViewFrame() {
        containerView.frame = CGRect(x: 0, y: 0, width: imageNormalWidth, height: imageNormalHeight)
        containerView.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    }

    override init(frame: CGRect) {
        self.containerView = UIView(frame: frame)
        self.imageNormalWidth = frame.size.width
        self.imageNormalHeight = frame.size.height
        super.init(frame: frame)
        self.delegate = self
        self.minimumZoomScale = 0.1
        self.maximumZoomScale = 2.0
        addSubview(containerView)
        if #available(iOS 11.0, *) {
            self.contentInsetAdjustmentBehavior = .never
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pictureZoom(withScale zoomScale: CGFloat) {
        let imageScaleWidth = zoomScale * imageNormalWidth
        let imageScaleHeight = zoomScale * imageNormalHeight
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageScaleWidth < frame.size.width {
            imageX = floor((frame.size.width - imageScaleWidth) / 2.0)
        }
        if imageScaleHeight < frame.size.height {
            imageY = floor((frame.size.height - imageScaleHeight) / 2.0)
        }
        containerView.frame = CGRect(x: imageX, y: imageY, width: imageScaleWidth, height: imageScaleHeight)
        contentSize = CGSize(width: imageScaleWidth, height: imageScaleHeight)
    }

    // MARK: UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("BeginZooming")
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        print("EndZooming")
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageScaleWidth = scrollView.zoomScale * imageNormalWidth
        let imageScaleHeight = scrollView.zoomScale * imageNormalHeight
        var imageX: CGFloat = 0
        var imageY: CGFloat = 0
        if imageScaleWidth < frame.size.width {
            imageX = floor((frame.size.width - imageScaleWidth) / 2.0)
        }
        if imageScaleHeight < frame.size.height {
            imageY = floor((frame.size.height - imageScaleHeight) / 2.0)
        }
        containerView.frame = CGRect(x: imageX, y: imageY, width: imageScaleWidth, height: imageScaleHeight)
    }
}

class TUIImageCollectionCell: TUIMediaCollectionCell {
    var scrollView: TUIImageCollectionCellScrollView!
    var imgCellData: TUIImageMessageCellData?
    var mainDownloadBtn: UIButton!
    var animateCircleView: TUICircleLoadingView!
    private var thumbImageObservation: NSKeyValueObservation?
    private var largeImageObservation: NSKeyValueObservation?
    private var largeProgressObservation: NSKeyValueObservation?
    private var originImageObservation: NSKeyValueObservation?
    private var originProgressObservation: NSKeyValueObservation?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupRotationNotifications()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        largeImageObservation?.invalidate()
        largeImageObservation = nil
        largeProgressObservation?.invalidate()
        largeProgressObservation = nil
        originImageObservation?.invalidate()
        originImageObservation = nil
        originProgressObservation?.invalidate()
        originProgressObservation = nil
    }

    func setupViews() {
        scrollView = TUIImageCollectionCellScrollView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height))
        addSubview(scrollView)

        imageView = UIImageView()
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        scrollView.containerView.addSubview(imageView)
        imageView.mm__fill()
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        mainDownloadBtn = UIButton(type: .custom)
        mainDownloadBtn.contentMode = .scaleToFill
        mainDownloadBtn.setTitle(TUISwift.timCommonLocalizableString("TUIKitImageViewOrigin"), for: .normal)
        mainDownloadBtn.backgroundColor = .gray
        mainDownloadBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        mainDownloadBtn.layer.borderColor = UIColor.white.cgColor
        mainDownloadBtn.layer.cornerRadius = 0.16
        mainDownloadBtn.isHidden = true
        mainDownloadBtn.addTarget(self, action: #selector(mainDownloadBtnClick), for: .touchUpInside)
        addSubview(mainDownloadBtn)

        downloadBtn = UIButton(type: .custom)
        downloadBtn.contentMode = .scaleToFill
        downloadBtn.setImage(TUISwift.tuiChatCommonBundleImage("download"), for: .normal)
        downloadBtn.addTarget(self, action: #selector(onSaveBtnClick), for: .touchUpInside)
        addSubview(downloadBtn)

        animateCircleView = TUICircleLoadingView(frame: CGRect(x: 0, y: 0, width: TUISwift.kScale390(40), height: TUISwift.kScale390(40)))
        animateCircleView.isHidden = true
        animateCircleView.progress = 0
        addSubview(animateCircleView)

        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(onSelectMedia))
        addGestureRecognizer(tap)
    }

    func setupRotationNotifications() {
        if #available(iOS 16.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange(_:)), name: NSNotification.Name("TUIMessageMediaViewDeviceOrientationChangeNotification"), object: nil)
        } else {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        }
    }

    @objc func mainDownloadBtnClick() {
        if imgCellData?.originImage == nil {
            imgCellData?.downloadImage(type: .origin)
        }
    }

    @objc func onSaveBtnClick() {
        guard let image = imageView.image else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, _ in
            DispatchQueue.main.async {
                if success {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitPictureSavedSuccess"))
                } else {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitPictureSavedFailed"))
                }
            }
        }
    }

    @objc func onSelectMedia() {
        delegate?.onCloseMedia?(cell: self)
    }

    override func fill(with data: TUIMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIImageMessageCellData else { return }

        imgCellData = data
        imageView.image = nil

        let hasRiskContent = data.innerMessage?.hasRiskContent ?? false
        if hasRiskContent {
            imageView.image = TUISwift.timCommonBundleThemeImage("", defaultImage: "icon_security_strike")
            for subview in subviews {
                if subview != scrollView {
                    subview.isHidden = true
                }
            }
            return
        }

        if originImageFirst(data) {
            return
        }

        if largeImageSecond(data) {
            return
        }

        if data.thumbImage == nil {
            data.downloadImage(type: .thumb)
        }
        if data.thumbImage != nil && data.largeImage == nil {
            animateCircleView.isHidden = false
            data.downloadImage(type: .large)
        }
        fillThumbImage(with: data)
        fillLargeImage(with: data)
        fillOriginImage(with: data)
    }

    func largeImageSecond(_ data: TUIImageMessageCellData) -> Bool {
        var isExist = false
        _ = data.getImagePath(type: .large, isExist: &isExist)
        if isExist {
            data.decodeImage(type: .large)
            fillLargeImage(with: data)
        }
        return isExist
    }

    func originImageFirst(_ data: TUIImageMessageCellData) -> Bool {
        var isExist = false
        _ = data.getImagePath(type: .origin, isExist: &isExist)
        if isExist {
            data.decodeImage(type: .origin)
            fillOriginImage(with: data)
        }
        return isExist
    }

    func fillOriginImage(with data: TUIImageMessageCellData) {
        originImageObservation = data.observe(\.originImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let originImage = change.newValue else { return }
            self.imageView.image = originImage
            self.setNeedsLayout()
        }
        originProgressObservation = data.observe(\.originProgress, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            if progress == 100 {
                self.animateCircleView.progress = 99
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateCircleView.progress = 100
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.animateCircleView.progress = 0
                        self.mainDownloadBtn.isHidden = true
                        self.animateCircleView.isHidden = true
                        self.mainDownloadBtn.setTitle(TUISwift.timCommonLocalizableString("TUIKitImageViewOrigin"), for: .normal)
                    }
                }
            } else if progress > 1 && progress < 100 {
                self.animateCircleView.progress = Double(progress)
                self.mainDownloadBtn.setTitle("\(progress)%", for: .normal)
                self.animateCircleView.isHidden = true
            } else {
                self.animateCircleView.progress = Double(progress)
            }
        }
    }

    func fillLargeImage(with data: TUIImageMessageCellData) {
        largeImageObservation = data.observe(\.largeImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let largeImage = change.newValue else { return }
            self.imageView.image = largeImage
            self.setNeedsLayout()
        }

        largeProgressObservation = data.observe(\.largeProgress, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            if progress == 100 {
                self.animateCircleView.progress = 99
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.animateCircleView.progress = 100
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.animateCircleView.progress = 0
                        self.mainDownloadBtn.isHidden = false
                        self.animateCircleView.isHidden = true
                    }
                }
            } else if progress > 1 && progress < 100 {
                self.animateCircleView.progress = Double(progress)
                self.mainDownloadBtn.isHidden = true
                self.animateCircleView.isHidden = false
            } else {
                self.animateCircleView.progress = Double(progress)
            }
        }
    }

    func fillThumbImage(with data: TUIImageMessageCellData) {
        thumbImageObservation = data.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.imageView.image = thumbImage
            self.setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mainDownloadBtn.sizeToFit()
        mainDownloadBtn.frame = CGRect(x: (bounds.width - mainDownloadBtn.bounds.width - 10) / 2,
                                       y: bounds.height - 48,
                                       width: mainDownloadBtn.bounds.width + 10,
                                       height: mainDownloadBtn.bounds.height)
        mainDownloadBtn.layer.cornerRadius = mainDownloadBtn.bounds.height * 0.5

        animateCircleView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)

        downloadBtn = subviews.first { $0 is UIButton && $0 != mainDownloadBtn } as? UIButton
        downloadBtn?.frame = CGRect(x: bounds.width - 47, y: bounds.height - 48, width: 31, height: 31)

        scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        scrollView.imageNormalWidth = imageView.image?.size.width ?? 0
        scrollView.imageNormalHeight = imageView.image?.size.height ?? 0

        imageView.frame = CGRect(x: scrollView.bounds.origin.x,
                                 y: scrollView.bounds.origin.y,
                                 width: imageView.image?.size.width ?? 0,
                                 height: imageView.image?.size.height ?? 0)
        imageView.layoutIfNeeded()

        adjustScale()
    }

    @objc func onDeviceOrientationChange(_ notification: Notification) {
        reloadAllView()
    }

    func reloadAllView() {
        for subview in subviews {
            UIView.animate(withDuration: 0.1) {
                subview.removeFromSuperview()
            }
        }
        setupViews()
        if let data = imgCellData {
            fill(with: data)
        }
    }

    func adjustScale() {
        var scale: CGFloat = 1
        if TUISwift.screen_Width() > imageView.image?.size.width ?? 0 {
            scale = 1
            let scaleHeight = TUISwift.screen_Height() / (imageView.image?.size.height ?? 1)
            scale = min(scale, scaleHeight)
        } else {
            scale = TUISwift.screen_Width() / (imageView.image?.size.width ?? 1)
            let scaleHeight = TUISwift.screen_Height() / (imageView.image?.size.height ?? 1)
            scale = min(scale, scaleHeight)
        }
        scrollView.containerView.frame = CGRect(x: 0, y: 0, width: min(TUISwift.screen_Width(), imageView.image?.size.width ?? 0), height: imageView.image?.size.height ?? 0)
        scrollView.pictureZoom(withScale: scale)
    }

    // MARK: - V2TIMAdvancedMsgListener

    func onRecvMessageModified(msg: V2TIMMessage) {
        if imgCellData?.innerMessage?.msgID == msg.msgID {
            let hasRiskContent = msg.hasRiskContent
            if hasRiskContent {
                imgCellData?.innerMessage = msg
                showRiskAlert()
            }
        }
    }

    func showRiskAlert() {
        let alertController = UIAlertController(title: nil,
                                                message: TUISwift.timCommonLocalizableString("TUIKitPictureCheckRisk"),
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
