import UIKit
import TIMCommon

protocol TUICameraViewDelegate: NSObjectProtocol {
    // Flash
    func flashLightAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void)
    
    // Fill light
    func torchLightAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void)
    
    // Switch camera
    func switchCameraAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void)
    
    // Auto focus and exposure
    func autoFocusAndExposureAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void)
    
    // Focus
    func focusAction(_ cameraView: TUICameraView, point: CGPoint, handle: @escaping (Error?) -> Void)
    
    // Expose
    func exposeAction(_ cameraView: TUICameraView, point: CGPoint, handle: @escaping (Error?) -> Void)
    
    // Zoom
    func zoomAction(_ cameraView: TUICameraView, factor: CGFloat)
    
    func cancelAction(_ cameraView: TUICameraView)
    
    func pictureLibAction(_ cameraView: TUICameraView)
    
    func takePhotoAction(_ cameraView: TUICameraView)
    
    func stopRecordVideoAction(_ cameraView: TUICameraView, recordDuration: CGFloat)
    
    func startRecordVideoAction(_ cameraView: TUICameraView)
    
    func didChangeTypeAction(_ cameraView: TUICameraView, type: TUICameraMediaType)
}

class TUICameraView: UIView {
    weak var delegate: TUICameraViewDelegate?
    
    private var contentView: UIView!
    private var switchCameraButton: UIButton!
    private var closeButton: UIButton!
    private var pictureLibButton: UIButton!
    private var focusView: UIView!
    private var slider: UISlider!
    private var photoBtn: UIView!
    private var photoStateView: UIView!
    private var longPress: UILongPressGestureRecognizer!
    private var lastRect: CGRect = .zero
    
    private var progressLayer: CAShapeLayer!
    
    private var timer: TUICaptureTimer!
    private var isVideoRecording: Bool = false
    
    var type: TUICameraMediaType = .photo
    var aspectRatio: TUICameraViewAspectRatio = .aspectRatio16x9
    var maxVideoCaptureTimeLimit: CGFloat = 15.0
    
    var progress: CGFloat = 0.0 {
        didSet {
            if progress < 0 {
                return
            } else if progress < 1.0 {
                progressLayer.strokeEnd = progress
            }
            
            if progress >= 1.0 {
                progressLayer.strokeEnd = 1.0
            }
        }
    }
    
    lazy var previewView: TUICaptureVideoPreviewView = {
        var previewView = TUICaptureVideoPreviewView()
        previewView.isUserInteractionEnabled = true
        return previewView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView = UIView()
        addSubview(contentView)
        
        previewView.isUserInteractionEnabled = true
        contentView.addSubview(previewView)
        
        switchCameraButton = UIButton(type: .custom)
        let switchCameraButtonImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camera_switchCamera"))
        switchCameraButton.setImage(switchCameraButtonImage, for: .normal)
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonClick(_:)), for: .touchUpInside)
        contentView.addSubview(switchCameraButton)
        
        closeButton = UIButton(type: .custom)
        let closeButtonImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camera_back"))
        closeButton.setBackgroundImage(closeButtonImage.rtl_imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonClick(_:)), for: .touchUpInside)
        contentView.addSubview(closeButton)
        
        pictureLibButton = UIButton(type: .custom)
        let pictureImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("more_picture"))
        pictureLibButton.setBackgroundImage(pictureImage, for: .normal)
        pictureLibButton.addTarget(self, action: #selector(pictureLibClick(_:)), for: .touchUpInside)
        contentView.addSubview(pictureLibButton)
        
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        focusView.backgroundColor = .clear
        focusView.layer.borderColor = UIColor(red: 0, green: 204.0 / 255, blue: 0, alpha: 1).cgColor
        focusView.layer.borderWidth = 3.0
        focusView.isHidden = true
        previewView.addSubview(focusView)
        
        slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.maximumTrackTintColor = .white
        slider.minimumTrackTintColor = .white
        slider.alpha = 0.0
        slider.isHidden = true
        previewView.addSubview(slider)
        
        photoBtn = UIView()
        photoBtn.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        if type == .video {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
            photoBtn.addGestureRecognizer(longPress)
        }
        if type == .photo {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
            photoBtn.addGestureRecognizer(tapGesture)
        }
        photoBtn.isUserInteractionEnabled = true
        
        photoStateView = UIView()
        photoStateView.backgroundColor = .white
        photoBtn.addSubview(photoStateView)
        contentView.addSubview(photoBtn)
        
        progressLayer = CAShapeLayer()
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 5.0
        progressLayer.strokeColor = UIColor(red: 0, green: 204.0 / 255, blue: 0, alpha: 1).cgColor
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = 0
        progressLayer.lineCap = .butt
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        previewView.addGestureRecognizer(tap)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        previewView.addGestureRecognizer(pinch)
        
        timer = TUICaptureTimer()
        timer.maxCaptureTime = maxVideoCaptureTimeLimit
        timer.progressBlock = { [weak self] ratio, recordTime in
            self?.progress = ratio
        }
        timer.progressFinishBlock = { [weak self] ratio, recordTime in
            self?.progress = 1
            self?.longPress.isEnabled = false
            self?.endVideoRecordWithCaptureDuration(recordTime)
            self?.longPress.isEnabled = true
        }
        timer.progressCancelBlock = { [weak self] in
            self?.progress = 0
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !lastRect.equalTo(bounds) {
            setupUI()
            
            lastRect = bounds
            contentView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
            
            let previewViewWidth = contentView.bounds.size.width
            var previewViewHeight: CGFloat = 0
            switch aspectRatio {
                case .aspectRatio1x1:
                    previewViewHeight = previewViewWidth
                case .aspectRatio16x9:
                    previewViewHeight = previewViewWidth * (16.0 / 9.0)
                case .aspectRatio5x4:
                    previewViewHeight = previewViewWidth * (5.0 / 4.0)
            }
            let previewViewY = (contentView.bounds.size.height - previewViewHeight) / 2.0
            previewView.frame = CGRect(x: 0, y: previewViewY, width: contentView.bounds.size.width, height: previewViewHeight)
            
            let switchCameraButtonWidth: CGFloat = 44.0
            switchCameraButton.frame = CGRect(x: contentView.bounds.size.width - switchCameraButtonWidth - 16.0, y: 30.0, width: switchCameraButtonWidth, height: switchCameraButtonWidth)
            
            if TUISwift.isRTL() {
                switchCameraButton.resetFrameToFitRTL()
            }
            
            let photoBtnWidth: CGFloat = 100.0
            photoBtn.frame = CGRect(x: (contentView.bounds.size.width - photoBtnWidth) / 2.0, y: contentView.bounds.size.height - photoBtnWidth - 30, width: photoBtnWidth, height: photoBtnWidth)
            photoBtn.layer.cornerRadius = photoBtnWidth / 2.0
            
            let distanceToPhotoBtn: CGFloat = 10.0
            let photoStateViewWidth = photoBtnWidth - 2 * distanceToPhotoBtn
            photoStateView.frame = CGRect(x: distanceToPhotoBtn, y: distanceToPhotoBtn, width: photoStateViewWidth, height: photoStateViewWidth)
            photoStateView.layer.cornerRadius = photoStateViewWidth / 2.0
            
            if type == .video {
                progressLayer.frame = photoBtn.bounds.insetBy(dx: 5.0 / 2.0, dy: 5.0 / 2.0)
                
                let radius = progressLayer.bounds.size.width / 2
                let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: -.pi / 2, endAngle: -.pi / 2 + .pi * 2, clockwise: true)
                progressLayer.path = path.cgPath
                photoBtn.layer.addSublayer(progressLayer)
            }
            
            let closeButtonWidth: CGFloat = 30.0
            let closeButtonX = (photoBtn.frame.origin.x - closeButtonWidth) / 2.0
            let closeButtonY = photoBtn.center.y - closeButtonWidth / 2.0
            closeButton.frame = CGRect(x: closeButtonX, y: closeButtonY, width: closeButtonWidth, height: closeButtonWidth)
            if TUISwift.isRTL() {
                closeButton.resetFrameToFitRTL()
            }
            let pictureButtonWidth: CGFloat = 30.0
            
            pictureLibButton.frame = CGRect(x: contentView.frame.size.width - closeButtonX, y: closeButtonY, width: pictureButtonWidth, height: pictureButtonWidth)
            if TUISwift.isRTL() {
                pictureLibButton.resetFrameToFitRTL()
            }
            slider.transform = CGAffineTransform(rotationAngle: .pi / 2)
            slider.frame = CGRect(x: bounds.size.width - 50, y: 50, width: 15, height: 200)
        }
    }
    
    @objc func tapAction(_ tap: UIGestureRecognizer) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("focusAction")))) != nil) {
            let point = tap.location(in: previewView)
            runFocusAnimation(focusView, point: point)
            self.delegate?.focusAction(self, point: previewView.captureDevicePoint(for: point)) { error in
                if let error = error {
                    assertionFailure("\(error)")
                }
            }
        }
    }
        
    func runFocusAnimation(_ view: UIView, point: CGPoint) {
        view.center = point
        view.isHidden = false
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
            view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0)
        }) { _ in
            let delayInSeconds = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                view.isHidden = true
                view.transform = .identity
            }
        }
    }
        
    @objc func pinchAction(_ pinch: UIPinchGestureRecognizer) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("zoomAction")))) != nil) {
            if pinch.state == .began {
                UIView.animate(withDuration: 0.1) {
                    self.slider.alpha = 1
                }
            } else if pinch.state == .changed {
                if pinch.velocity > 0 {
                    slider.value += Float(pinch.velocity / 100)
                } else {
                    slider.value += Float(pinch.velocity / 20)
                }
                self.delegate?.zoomAction(self, factor: pow(5, CGFloat(slider.value)))
            } else {
                UIView.animate(withDuration: 0.1) {
                    self.slider.alpha = 0.0
                }
            }
        }
    }
        
    @objc func switchCameraButtonClick(_ btn: UIButton) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("swicthCameraAction")))) != nil) {
            delegate?.switchCameraAction(self, handle: { error in
                // to do
            })
        }
    }
        
    @objc func closeButtonClick(_ btn: UIButton) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("cancelAction")))) != nil) {
            delegate?.cancelAction(self)
        }
    }
        
    @objc func pictureLibClick(_ btn: UIButton) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("pictureLibAction")))) != nil) {
            delegate?.pictureLibAction(self)
        }
    }
        
    @objc func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            beginVideoRecord()
        case .changed:
            break
        case .ended:
            endVideoRecordWithCaptureDuration(timer.captureDuration)
        default:
            break
        }
    }
        
    func beginVideoRecord() {
        if isVideoRecording {
            return
        }
        
        closeButton.isHidden = true
        isVideoRecording = true
        pictureLibButton.isHidden = true
        timer.startTimer()
        
        DispatchQueue.main.async {
            self.progressLayer.strokeEnd = 0.0
            UIView.animate(withDuration: 0.2) {
                self.photoStateView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.photoBtn.transform = CGAffineTransform(scaleX: 1.125, y: 1.125)
            }
            if self.delegate != nil && ((self.delegate?.responds(to: Selector(("startRecordVideoAction")))) != nil) {
                self.delegate?.startRecordVideoAction(self)
            }
        }
    }
        
    func endVideoRecordWithCaptureDuration(_ duration: CGFloat) {
        if !isVideoRecording {
            return
        }
        
        closeButton.isHidden = false
        isVideoRecording = false
        pictureLibButton.isHidden = false
        timer.stopTimer()
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.photoStateView.transform = .identity
                self.photoBtn.transform = .identity
            }
            if self.delegate != nil && ((self.delegate?.responds(to: Selector(("stopRecordVideoAction")))) != nil) {
                self.delegate?.stopRecordVideoAction(self, recordDuration: duration)
            }
            
            self.progressLayer.strokeEnd = 0.0
        }
    }
        
    @objc func tapGesture(_ tapGesture: UITapGestureRecognizer) {
        if self.delegate != nil && ((self.delegate?.responds(to: Selector(("takePhotoAction")))) != nil) {
            self.delegate?.takePhotoAction(self)
        }
    }
}
