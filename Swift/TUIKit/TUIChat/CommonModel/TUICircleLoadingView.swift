import UIKit

class TUICircleLoadingView: UIView {
    var progress: Double = 0.0 {
        didSet {
            labProgress.text = String(format: "%.0f%%", progress)
            drawProgress()
        }
    }
    
    lazy var labProgress: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        label.textAlignment = .center
        label.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.width / 2)
        label.textColor = kCircleFillColor
        label.font = UIFont.systemFont(ofSize: 10)
        self.addSubview(label)
        return label
    }()

    lazy var grayProgressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = kCircleUnFillColor.cgColor
        layer.opacity = 1
        layer.lineCap = .round
        layer.lineWidth = 3
        self.layer.addSublayer(layer)
        return layer
    }()

    lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = kCircleFillColor.cgColor
        layer.opacity = 1
        layer.lineCap = .round
        layer.lineWidth = 3
        self.layer.addSublayer(layer)
        return layer
    }()

    private let kCircleUnFillColor = UIColor.white.withAlphaComponent(0.4)
    private let kCircleFillColor = UIColor.white
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawProgressCircle(endAngle: -CGFloat.pi / 2 + CGFloat.pi * 2, isGrayCircle: true)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        drawProgressCircle(endAngle: -CGFloat.pi / 2 + CGFloat.pi * 2, isGrayCircle: true)
    }
    
    private func drawProgress() {
        guard progress < 100 else { return }
        drawProgressCircle(endAngle: -CGFloat.pi / 2 + CGFloat.pi * 2 * CGFloat(progress) * 0.01, isGrayCircle: false)
    }
    
    private func drawProgressCircle(endAngle: CGFloat, isGrayCircle: Bool) {
        let center = CGPoint(x: frame.size.width / 2, y: frame.size.width / 2)
        let radius = frame.size.width / 2
        let startA = -CGFloat.pi / 2
        let endA = endAngle
        
        let layer = isGrayCircle ? grayProgressLayer : progressLayer
        
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startA, endAngle: endA, clockwise: true)
        layer.path = path.cgPath
    }

    // TODO: 应该不需要这段了，先注释掉
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        if labProgress == nil {
//            setupLabProgress()
//        }
//        if grayProgressLayer == nil {
//            setupGrayProgressLayer()
//        }
//        if progressLayer == nil {
//            setupProgressLayer()
//        }
//    }
}
