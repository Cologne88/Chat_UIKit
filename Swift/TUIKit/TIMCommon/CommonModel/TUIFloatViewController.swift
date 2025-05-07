import UIKit

public protocol TUIFloatSubViewControllerProtocol: AnyObject {
    var floatDataSourceChanged: (([Any]) -> Void)? { get set }
    func floatControllerLeftButtonClick()
    func floatControllerRightButtonClick()
}

public extension TUIFloatSubViewControllerProtocol {
    func floatControllerLeftButtonClick() {}
    func floatControllerRightButtonClick() {}
}

public class TUIFloatTitleView: UIView {
    public var leftButton: UIButton!
    public var rightButton: UIButton!
    public var leftButtonClickCallback: (() -> Void)?
    public var rightButtonClickCallback: (() -> Void)?
    public var titleLabel: UILabel!
    public var subTitleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel = UILabel()
        titleLabel.text = ""
        titleLabel.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(20))
        addSubview(titleLabel)

        subTitleLabel = UILabel()
        subTitleLabel.text = ""
        subTitleLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        subTitleLabel.tintColor = UIColor.gray
        addSubview(subTitleLabel)

        leftButton = UIButton(type: .custom)
        addSubview(leftButton)
        leftButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitCreateCancel"), for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        leftButton.addTarget(self, action: #selector(leftButtonClick), for: .touchUpInside)
        leftButton.setTitleColor(UIColor.tui_color(withHex: "#0365F9"), for: .normal)

        rightButton = UIButton(type: .custom)
        addSubview(rightButton)
        rightButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitCreateNext"), for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        rightButton.addTarget(self, action: #selector(rightButtonClick), for: .touchUpInside)
        rightButton.setTitleColor(UIColor.tui_color(withHex: "#0365F9"), for: .normal)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.sizeToFit()
        subTitleLabel.sizeToFit()

        if subTitleLabel.isHidden || subTitleLabel.text?.isEmpty == true {
            titleLabel.frame = CGRect(x: (frame.size.width - titleLabel.frame.size.width) * 0.5, y: TUISwift.kScale390(23.5), width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        } else {
            titleLabel.frame = CGRect(x: (frame.size.width - titleLabel.frame.size.width) * 0.5, y: TUISwift.kScale390(17.5), width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)

            subTitleLabel.frame = CGRect(x: (frame.size.width - subTitleLabel.frame.size.width) * 0.5, y: titleLabel.frame.origin.y + titleLabel.frame.size.height + TUISwift.kScale390(1), width: subTitleLabel.frame.size.width, height: subTitleLabel.frame.size.height)
        }

        leftButton.sizeToFit()
        leftButton.frame = CGRect(x: TUISwift.kScale390(15), y: TUISwift.kScale390(23.5), width: leftButton.frame.size.width, height: leftButton.frame.size.height)

        rightButton.sizeToFit()
        rightButton.frame = CGRect(x: frame.size.width - rightButton.frame.size.width - TUISwift.kScale390(14), y: TUISwift.kScale390(23.5), width: rightButton.frame.size.width, height: rightButton.frame.size.height)

        if TUISwift.isRTL() {
            leftButton.resetFrameToFitRTL()
            rightButton.resetFrameToFitRTL()
        }
    }

    @objc private func leftButtonClick() {
        leftButtonClickCallback?()
    }

    @objc private func rightButtonClick() {
        rightButtonClickCallback?()
    }

    public func setTitleText(mainText: String, subTitleText: String, leftBtnText: String, rightBtnText: String) {
        titleLabel.text = mainText
        subTitleLabel.text = subTitleText
        leftButton.setTitle(leftBtnText, for: .normal)
        rightButton.setTitle(rightBtnText, for: .normal)
    }
}

public class TUIFloatViewController: UIViewController {
    var topImgView: UIImageView!
    public var childVC: (UIViewController & TUIFloatSubViewControllerProtocol)?
    private var topMargin: CGFloat = 0.0
    private var currentLoaction: FLEX_Location! {
        didSet {
            if currentLoaction == .top {
                containerView.frame = CGRect(x: 0, y: topMargin, width: view.frame.size.width, height: view.frame.size.height - topMargin)
            } else if currentLoaction == .bottom {
                containerView.frame = CGRect(x: 0, y: view.frame.size.height - TUISwift.kScale390(393), width: view.frame.size.width, height: TUISwift.kScale390(393))
            }
        }
    }

    lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TUISwift.kScale390(12)
        return view
    }()

    public lazy var topGestureView: TUIFloatTitleView = {
        let view = TUIFloatTitleView()
        return view
    }()

    lazy var panCover: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onPanCover(_:)))
        return gesture
    }()

    enum FLEX_Location {
        case top
        case bottom
    }

    deinit {
        print("deinit")
    }

    public func appendChildViewController(_ vc: UIViewController & TUIFloatSubViewControllerProtocol, topMargin: CGFloat) {
        childVC = vc
        self.topMargin = topMargin

        addChild(vc)
        view.addSubview(containerView)
        containerView.addSubview(vc.view)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.tui_color(withHex: "#000000", alpha: 0.6)
        modalPresentationStyle = .custom

        containerView.backgroundColor = UIColor.white
        
        topImgView = UIImageView(image: UIImage.safeImage(TUISwift.timCommonImagePath("icon_flex_arrow")))
        topGestureView.addSubview(topImgView)
        topImgView.isHidden = true
        
        containerView.addSubview(topGestureView)
        
        topGestureView.leftButtonClickCallback = { [weak self] in
            guard let self = self else { return }
            self.childVC?.floatControllerLeftButtonClick()
        }

        topGestureView.rightButtonClickCallback = { [weak self] in
            guard let self = self else { return }
            self.childVC?.floatControllerRightButtonClick()
        }

        addSingleTapGesture()

        if currentLoaction != .top {
            currentLoaction = .top
        }

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
        currentLoaction = .top
    }

    func setNormalBottom() {
        currentLoaction = .bottom
    }

    public func floatDismissViewControllerAnimated(_ flag: Bool, completion: (() -> Void)?) {
        dismiss(animated: flag, completion: completion)
    }

    private func updateSubContainerView() {
        topGestureView.frame = CGRect(x: 0, y: 0, width: containerView.frame.size.width, height: TUISwift.kScale390(68.5))
        topImgView.frame = CGRect(x: (topGestureView.frame.size.width - TUISwift.kScale390(24)) * 0.5, y: TUISwift.kScale390(22), width: TUISwift.kScale390(24), height: TUISwift.kScale390(6))

        childVC?.view.frame = CGRect(x: 0, y: topGestureView.frame.origin.y + topGestureView.frame.size.height, width: containerView.frame.size.width, height: containerView.frame.size.height - topGestureView.frame.size.height)
    }

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
                    self.currentLoaction = .top
                    self.topGestureView.addGestureRecognizer(self.panCover)
                }, completion: { finished in
                    if finished {
                        self.updateSubContainerView()
                    }
                })
            } else {
                // scroll down
                if currentLoaction == .bottom {
                    dismiss(animated: true, completion: nil)
                }
                topGestureView.removeGestureRecognizer(panCover)
                UIView.animate(withDuration: 0.3, animations: {
                    self.currentLoaction = .bottom
                    self.topGestureView.addGestureRecognizer(self.panCover)
                }, completion: { finished in
                    if finished {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.updateSubContainerView()
                        }
                    }
                })
            }
        }
    }
}
