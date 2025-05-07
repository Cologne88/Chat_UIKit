import UIKit

let TUIBadgeViewColor = UIColor.red
let TUIBadgeLabelColor = UIColor.white
let TUIBadgeLabelFont = UIFont.systemFont(ofSize: 14.0)
let kAssistCircleDefaultWH: CGFloat = 10.0

public class TUIBadgeView: UIView {
    
    public var title: String? {
        didSet {
            let point = self.center
            label.text = title
            self.isHidden = (title?.count ?? 0) == 0
            self.sizeToFit()
            self.center = point
        }
    }
    
    public var clearCallback: (() -> Void)?
    
    private lazy var label: UILabel = {
        let lbl = UILabel()
        lbl.textColor = TUIBadgeLabelColor
        lbl.font = TUIBadgeLabelFont
        return lbl
    }()
    
    // Assist circle view for displaying in the origin position
    private lazy var assistCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = TUIBadgeViewColor
        view.isHidden = true
        view.layer.cornerRadius = 0.5 * kAssistCircleDefaultWH
        view.layer.masksToBounds = true
        return view
    }()
    
    // initial position
    private var initialCenterPosition: CGPoint = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    // MARK: - setupUI
    private func setupUI() {
        self.backgroundColor = TUIBadgeViewColor
        self.addSubview(label)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        pan.cancelsTouchesInView = false
        pan.delegate = self
        self.addGestureRecognizer(pan)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        label.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
        self.layer.cornerRadius = 0.5 * self.bounds.size.height
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        label.sizeToFit()
        var width = label.bounds.size.width + 8
        let height = label.bounds.size.height + 2
        if width < height {
            width = height
        }
        return CGSize(width: width, height: height)
    }
    
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        guard let clearCallback = clearCallback else {
            return
        }
        
        if gesture.state == .began {
            initialCenterPosition = self.center
        }
        
        let point = gesture.location(in: self.superview)
        let distance_x = point.x - initialCenterPosition.x
        let distance_y = point.y - initialCenterPosition.y
        let distance = sqrt(distance_x * distance_x + distance_y * distance_y)
        self.center = point
        
        if gesture.state == .ended {
            self.isHidden = distance >= 60
            self.center = initialCenterPosition
            if distance >= 60 {
                reset()
                clearCallback()
            }
        }
    }
    
    private func reset() {
        initialCenterPosition = .zero
        self.title = ""
    }
}

extension TUIBadgeView: UIGestureRecognizerDelegate {
    
}
