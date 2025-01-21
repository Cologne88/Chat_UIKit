import AVFoundation
import UIKit

class TUICaptureVideoPreviewView: UIView {

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        if let previewLayer = self.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.videoGravity = .resizeAspectFill
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let previewLayer = self.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.videoGravity = .resizeAspectFill
        }
    }

    var captureSession: AVCaptureSession? {
        get {
            return (self.layer as? AVCaptureVideoPreviewLayer)?.session
        }
        set {
            (self.layer as? AVCaptureVideoPreviewLayer)?.session = newValue
        }
    }

    func captureDevicePoint(for point: CGPoint) -> CGPoint {
        guard let layer = self.layer as? AVCaptureVideoPreviewLayer else {
            return CGPoint.zero
        }
        return layer.captureDevicePointConverted(fromLayerPoint: point)
    }
}
