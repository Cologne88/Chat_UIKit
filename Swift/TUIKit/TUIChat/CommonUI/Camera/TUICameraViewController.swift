import AVFoundation
import Photos
import TIMCommon
import UIKit

protocol TUICameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: TUICameraViewController, didFinishPickingMediaWithVideoURL url: URL)
    func cameraViewController(_ controller: TUICameraViewController, didFinishPickingMediaWithImageData data: Data)
    func cameraViewControllerDidCancel(_ controller: TUICameraViewController)
    func cameraViewControllerDidPictureLib(_ controller: TUICameraViewController, finishCallback: @escaping () -> Void)
}

class TUICameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, TUICameraViewDelegate {
    func exposeAction(_ cameraView: TUICameraView, point: CGPoint, handle: @escaping ((any Error)?) -> Void) {
        // to do
    }
    
    func didChangeTypeAction(_ cameraView: TUICameraView, type: TUICameraMediaType) {
        // to do
    }
    
    weak var delegate: TUICameraViewControllerDelegate?
    
    /// default TUICameraMediaTypePhoto
    var type: TUICameraMediaType = .photo
    
    /// default TUICameraViewAspectRatio16x9
    var aspectRatio: TUICameraViewAspectRatio = .aspectRatio16x9
    
    /// default 15s
    var videoMaximumDuration: TimeInterval = 15.0
    
    /// default 3s
    var videoMinimumDuration: TimeInterval = 3.0
    
    private var session: AVCaptureSession?
    private var deviceInput: AVCaptureDeviceInput?
    
    private var videoConnection: AVCaptureConnection?
    private var audioConnection: AVCaptureConnection?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var imageOutput: AVCaptureStillImageOutput?
    
    private var recording = false
    
    var cameraView: TUICameraView!
    var movieManager: TUIMovieManager!
    var cameraManager: TUICameraManager!
    var motionManager: TUIMotionManager!
    
    var isFirstShow = true
    var lastPageBarHidden = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        motionManager = TUIMotionManager()
        cameraManager = TUICameraManager()
        
        // Initialize other properties
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView = TUICameraView(frame: view.bounds)
        cameraView.type = type
        cameraView.aspectRatio = aspectRatio
        cameraView.delegate = self
        cameraView.maxVideoCaptureTimeLimit = videoMaximumDuration
        view.addSubview(cameraView)
        
        do {
            try setupSession()
            cameraView.previewView.captureSession = session
            startCaptureSession()
        } catch {
            // Handle error
        }
    }
    
    deinit {
        stopCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFirstShow {
            isFirstShow = false
            lastPageBarHidden = navigationController?.navigationBar.isHidden ?? false
        }
        navigationController?.navigationBar.isHidden = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            navigationController?.navigationBar.isHidden = lastPageBarHidden
        }
    }
    
    // MARK: - Input Device

    func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(for: .video)
        return devices.first { $0.position == position }
    }
    
    var activeCamera: AVCaptureDevice? {
        return deviceInput?.device
    }
    
    var inactiveCamera: AVCaptureDevice? {
        guard AVCaptureDevice.devices(for: .video).count > 1 else { return nil }
        return activeCamera?.position == .back ? camera(with: .front) : camera(with: .back)
    }
    
    // MARK: - Configuration

    func setupSession() throws {
        session = AVCaptureSession()
        session?.sessionPreset = .high
        
        try setupSessionInputs()
        try setupSessionOutputs()
    }
    
    func setupSessionInputs() throws {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        if session?.canAddInput(videoInput) == true {
            session?.addInput(videoInput)
        }
        deviceInput = videoInput
        
        if type == .video {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if session?.canAddInput(audioInput) == true {
                session?.addInput(audioInput)
            }
        }
    }
    
    func setupSessionOutputs() throws {
        let captureQueue = DispatchQueue(label: "com.tui.captureQueue")
        
        let videoOut = AVCaptureVideoDataOutput()
        videoOut.alwaysDiscardsLateVideoFrames = true
        videoOut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOut.setSampleBufferDelegate(self, queue: captureQueue)
        if session?.canAddOutput(videoOut) == true {
            session?.addOutput(videoOut)
        }
        videoOutput = videoOut
        videoConnection = videoOut.connection(with: .video)
        
        if type == .video {
            let audioOut = AVCaptureAudioDataOutput()
            audioOut.setSampleBufferDelegate(self, queue: captureQueue)
            if session?.canAddOutput(audioOut) == true {
                session?.addOutput(audioOut)
            }
            audioConnection = audioOut.connection(with: .audio)
        }
        
        let imageOutput = AVCaptureStillImageOutput()
        imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
        if session?.canAddOutput(imageOutput) == true {
            session?.addOutput(imageOutput)
        }
        self.imageOutput = imageOutput
    }
    
    // MARK: - Session Control

    func startCaptureSession() {
        if session?.isRunning == false {
            session?.startRunning()
        }
    }
    
    func stopCaptureSession() {
        if session?.isRunning == true {
            session?.stopRunning()
        }
    }
    
    // MARK: - Camera Operation

    func zoomAction(_ cameraView: TUICameraView, factor: CGFloat) {
        if let activeCamera = activeCamera, let result = cameraManager.zoom(device: activeCamera, factor: factor) {
            print("\(result)")
        }
    }
    
    func focusAction(_ cameraView: TUICameraView, point: CGPoint, handle: @escaping (Error?) -> Void) {
        if let activeCamera = activeCamera, let result = cameraManager.focus(device: activeCamera, point: point) {
            handle(result)
        }
    }
    
    func exposAction(_ cameraView: TUICameraView, point: CGPoint, handle: @escaping (Error?) -> Void) {
        if let activeCamera = activeCamera, let result = cameraManager.expose(device: activeCamera, point: point) {
            handle(result)
        }
    }
    
    func autoFocusAndExposureAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void) {
        if let activeCamera = activeCamera, let result = cameraManager.resetFocusAndExposure(device: activeCamera) {
            handle(result)
        }
    }
    
    func flashLightAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void) {
        guard let activeCamera = activeCamera else { return }
        let on = cameraManager.flashMode(device: activeCamera) == .on
        let mode: AVCaptureDevice.FlashMode = on ? .off : .on
        if let result = cameraManager.changeFlash(device: activeCamera, mode: mode) {
            handle(result)
        }
    }
    
    func torchLightAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void) {
        guard let activeCamera = activeCamera else { return }
        let on = cameraManager.torchMode(device: activeCamera) == .on
        let mode: AVCaptureDevice.TorchMode = on ? .off : .on
        if let result = cameraManager.changeTorch(device: activeCamera, mode: mode) {
            handle(result)
        }
    }
    
    func switchCameraAction(_ cameraView: TUICameraView, handle: @escaping (Error?) -> Void) {
        guard let activeCamera = activeCamera else { return }
        var error: Error?
        guard let videoDevice = inactiveCamera else {
            handle(error)
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            let animation = CATransition()
//            animation.type = "oglFlip"
            animation.subtype = .fromLeft
            animation.duration = 0.5
            cameraView.previewView.layer.add(animation, forKey: "flip")
            
            let mode = cameraManager.flashMode(device: activeCamera)
            
            if let session = session, let deviceInput = deviceInput {
                self.deviceInput = cameraManager.switchCamera(session: session, oldInput: deviceInput, newInput: videoInput)
            }
            
            if let videoOutput = videoOutput {
                videoConnection = videoOutput.connection(with: .video)
            }
            
            if let result = cameraManager.changeFlash(device: activeCamera, mode: mode) {
                print("\(result)")
            }
            
            handle(nil)
        } catch {
            handle(error)
        }
    }
    
    // MARK: - Taking Photo

    func takePhotoAction(_ cameraView: TUICameraView) {
        guard let connection = imageOutput?.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }
        imageOutput?.captureStillImageAsynchronously(from: connection) { imageDataSampleBuffer, error in
            if let error = error {
                self.showErrorStr(error.localizedDescription)
                return
            }
            guard let imageDataSampleBuffer = imageDataSampleBuffer,
                  let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer),
                  let image = UIImage(data: imageData) else { return }
            let vc = TUICaptureImagePreviewController(image: image)
            self.navigationController?.pushViewController(vc, animated: true)
            vc.commitBlock = {
                UIGraphicsBeginImageContext(CGSize(width: image.size.width, height: image.size.height))
                image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
                let convertToUpImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                guard let data = convertToUpImage?.jpegData(compressionQuality: 0.75) else { return }
                self.delegate?.cameraViewController(self, didFinishPickingMediaWithImageData: data)
                self.popViewControllerAnimated(true)
            }
            vc.cancelBlock = {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func cancelAction(_ cameraView: TUICameraView) {
        delegate?.cameraViewControllerDidCancel(self)
        popViewControllerAnimated(true)
    }
    
    func pictureLibAction(_ cameraView: TUICameraView) {
        delegate?.cameraViewControllerDidPictureLib(self) {
            self.popViewControllerAnimated(false)
        }
    }
    
    // MARK: - Record

    func startRecordVideoAction(_ cameraView: TUICameraView) {
        movieManager = TUIMovieManager()
        recording = true
        if let activeCamera = activeCamera {
            movieManager.currentDevice = activeCamera
        }
        movieManager.currentOrientation = currentVideoOrientation()
        movieManager.start { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showErrorStr(error.localizedDescription)
                }
            }
        }
    }
    
    func stopRecordVideoAction(_ cameraView: TUICameraView, recordDuration duration: CGFloat) {
        recording = false
        movieManager.stop { url, error in
            DispatchQueue.main.async {
                if duration < self.videoMinimumDuration {
                    self.showErrorStr("视频录制时间太短")
                } else if let error = error {
                    self.showErrorStr(error.localizedDescription)
                } else {
                    guard let url = url else { return }
                    let videoPreviewController = TUICaptureVideoPreviewViewController(videoURL: url)
                    self.navigationController?.pushViewController(videoPreviewController, animated: true)
                    videoPreviewController.commitBlock = {
                        self.delegate?.cameraViewController(self, didFinishPickingMediaWithVideoURL: url)
                        self.popViewControllerAnimated(true)
                    }
                    videoPreviewController.cancelBlock = {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if recording, let videoConnection = videoConnection, let audioConnection = audioConnection {
            movieManager.writeData(connection: connection, video: videoConnection, audio: audioConnection, buffer: sampleBuffer)
        }
    }
    
    // MARK: - Others

    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch motionManager.deviceOrientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func popViewControllerAnimated(_ animated: Bool) {
        guard let index = navigationController?.viewControllers.firstIndex(of: self), index > 0 else {
            navigationController?.popViewController(animated: animated)
            return
        }
        let lastVC = navigationController?.viewControllers[index - 1]
        navigationController?.navigationBar.isHidden = lastPageBarHidden
        if let lastVC = lastVC {
            navigationController?.popToViewController(lastVC, animated: animated)
        } else {
            navigationController?.popViewController(animated: animated)
        }
    }
    
    func showErrorStr(_ errStr: String) {
        TUITool.makeToast(errStr, duration: 1, position: CGPoint(x: view.bounds.size.width / 2.0, y: view.bounds.size.height / 2.0))
    }
}
