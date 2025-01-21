import TIMCommon
import UIKit

enum FLEXLocation: UInt {
    case top
    case bottom
}

class TUIChatFlexViewController: UIViewController {
    var topImgView: UIImageView!
    private var singleTap: UITapGestureRecognizer!
    private let topMargin: CGFloat = TUISwift.navBar_Height() + 30

    private var currentLocation: FLEXLocation = .top {
        didSet {
            switch currentLocation {
            case .top:
                containerView.frame = CGRect(x: 0, y: topMargin, width: view.frame.size.width, height: view.frame.size.height - topMargin)
            case .bottom:
                containerView.frame = CGRect(x: 0, y: view.frame.size.height - TUISwift.kScale390(393), width: view.frame.size.width, height: TUISwift.kScale390(393))
            }
        }
    }

    lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TUISwift.kScale390(12)
        self.view.addSubview(view)
        return view
    }()

    lazy var topGestureView: UIView = {
        let view = UIView()
        view.addGestureRecognizer(panCover)
        containerView.addSubview(view)
        return view
    }()

    private lazy var panCover: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanCover(_:)))
        return pan
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = TUISwift.rgb(0, green: 0, blue: 0, alpha: 0.5)
        containerView.backgroundColor = .white

        topImgView = UIImageView(image: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_flex_arrow")))
        topGestureView.addSubview(topImgView)

        addSingleTapGesture()

        currentLocation = .top

        updateSubContainerView()
    }

    private func addSingleTapGesture() {
        view.isUserInteractionEnabled = true
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        singleTap.cancelsTouchesInView = false
        view.addGestureRecognizer(singleTap)
    }

    @objc private func singleTap(_ tap: UITapGestureRecognizer) {
        let translation = tap.location(in: containerView)

        if translation.x < 0 || translation.y < 0 || translation.x > containerView.frame.size.width || translation.y > containerView.frame.size.height {
            dismiss(animated: true, completion: nil)
        }
    }

    func setnormalTop() {
        currentLocation = .top
    }

    func setNormalBottom() {
        currentLocation = .bottom
    }

    private func setCurrentLocation(_ location: FLEXLocation) {
        currentLocation = location
        if location == .top {
            containerView.frame = CGRect(x: 0, y: topMargin, width: view.frame.size.width, height: view.frame.size.height - topMargin)
        } else if location == .bottom {
            containerView.frame = CGRect(x: 0, y: view.frame.size.height - TUISwift.kScale390(393), width: view.frame.size.width, height: TUISwift.kScale390(393))
        }
    }

    // MARK: - Lazy Loading

    @objc private func onPanCover(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: topGestureView)
        let absX = abs(translation.x)
        let absY = abs(translation.y)

        if max(absX, absY) < 2 { return }
        if absX > absY {
            if translation.x < 0 {
                // scroll left
            } else {
                // scroll right
            }
        } else if absY > absX {
            if translation.y < 0 {
                // scroll up
                topGestureView.removeGestureRecognizer(panCover)
                UIView.animate(withDuration: 0.3, animations: {
                    self.currentLocation = .top
                    self.topGestureView.addGestureRecognizer(self.panCover)
                }) { finished in
                    if finished {
                        self.updateSubContainerView()
                    }
                }
            } else {
                // scroll down
                if currentLocation == .bottom {
                    dismiss(animated: true, completion: nil)
                }
                topGestureView.removeGestureRecognizer(panCover)
                UIView.animate(withDuration: 0.3, animations: {
                    self.currentLocation = .bottom
                    self.topGestureView.addGestureRecognizer(self.panCover)
                }) { finished in
                    if finished {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.updateSubContainerView()
                        }
                    }
                }
            }
        }
    }

    func updateSubContainerView() {
        topGestureView.frame = CGRect(x: 0, y: 0, width: containerView.frame.size.width, height: TUISwift.kScale390(40))
        topImgView.frame = CGRect(x: (topGestureView.frame.size.width - TUISwift.kScale390(24)) * 0.5, y: TUISwift.kScale390(22), width: TUISwift.kScale390(24), height: TUISwift.kScale390(6))
    }
}
