import TIMCommon
import TUICore
import UIKit

@objc protocol TUIMessageMultiChooseViewDelegate_Minimalist: AnyObject {
    /**
     * Callback when the cancel button on the multi-select message panel is clicked
     */
    @objc optional func onCancelClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist)

    /**
     * Callback for when the forward button on the multi-select message panel is clicked
     */
    @objc optional func onRelayClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist)

    /**
     * Callback for when the delete button on the multi-select message panel is clicked
     */
    @objc optional func onDeleteClicked(_ multiChooseView: TUIMessageMultiChooseView_Minimalist)
}

class TUIMessageMultiChooseView_Minimalist: UIView {
    weak var delegate: TUIMessageMultiChooseViewDelegate_Minimalist?

    // Top toolbar
    var toolView: UIView?
    var cancelButton: UIButton?
    var titleLabel: UILabel?

    // Bottom menu bar
    var menuView: UIView?
    var relayButton: UIButton?
    var deleteButton: UIButton?
    var selectedCountLabel: UILabel?
    var bottomCancelButton: UIButton?

    lazy var separatorLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB").cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            if hitView == self {
                return nil
            } else {
                return hitView
            }
        }
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var toolHeight: CGFloat = 44
        var menuHeight: CGFloat = 54
        var centerTopOffset: CGFloat = 0
        if #available(iOS 11.0, *) {
            toolHeight += safeAreaInsets.top
            menuHeight += safeAreaInsets.bottom
            centerTopOffset = safeAreaInsets.top
        }

        toolView?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: toolHeight)
        menuView?.frame = CGRect(x: 0, y: bounds.size.height - menuHeight, width: bounds.size.width, height: menuHeight)
        separatorLayer.frame = CGRect(x: 0, y: 0, width: (menuView?.bounds.size.width ?? 0), height: 1)

        // toolView
        let centerY = 0.5 * ((toolView?.bounds.size.height ?? 0) - (cancelButton?.bounds.size.height ?? 0))
        cancelButton?.frame = CGRect(x: 10, y: centerY + 0.5 * centerTopOffset, width: cancelButton?.bounds.size.width ?? 0, height: cancelButton?.bounds.size.height ?? 0)

        titleLabel?.sizeToFit()
        titleLabel?.center = toolView?.center ?? CGPointZero
        var titleRect = titleLabel?.frame
        titleRect?.origin.y += 0.5 * centerTopOffset
        titleLabel?.frame = titleRect ?? CGRectZero

        // menuView
        let width = menuView?.bounds.size.width ?? 0
        relayButton?.frame = CGRect(x: TUISwift.kScale390(23), y: TUISwift.kScale390(17), width: TUISwift.kScale390(16), height: TUISwift.kScale390(16))
        deleteButton?.frame = CGRect(x: (relayButton?.frame.origin.x ?? 0) + (relayButton?.frame.size.width ?? 0) + TUISwift.kScale390(17), y: TUISwift.kScale390(17), width: TUISwift.kScale390(16), height: TUISwift.kScale390(16))

        selectedCountLabel?.sizeToFit()
        let labelWidth = (selectedCountLabel?.frame.size.width ?? 0) + 20
        selectedCountLabel?.frame = CGRect(x: (width - labelWidth) * 0.5, y: TUISwift.kScale390(14), width: labelWidth, height: TUISwift.kScale390(30))

        bottomCancelButton?.frame = CGRect(x: width - TUISwift.kScale390(50) - TUISwift.kScale390(23), y: TUISwift.kScale390(14), width: TUISwift.kScale390(50), height: TUISwift.kScale390(30))

        if TUISwift.isRTL() {
            guard let toolView = toolView, let menuView = menuView else { return }
            for subview in toolView.subviews {
                subview.resetFrameToFitRTL()
            }
            for subview in menuView.subviews {
                subview.resetFrameToFitRTL()
            }
        }
    }

    private func setupViews() {
        toolView = UIView()
        toolView!.backgroundColor = TUISwift.timCommonDynamicColor("head_bg_gradient_start_color", defaultColor: "#EBF0F6")
//        addSubview(toolView!)

        menuView = UIView()
        menuView!.backgroundColor = TUISwift.tuiChatDynamicColor("chat_controller_bg_color", defaultColor: "#FFFFFF")
        menuView!.layer.addSublayer(separatorLayer)
        addSubview(menuView!)

        cancelButton = UIButton(type: .custom)
        cancelButton!.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        cancelButton!.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        cancelButton!.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        cancelButton!.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
        cancelButton!.sizeToFit()
        toolView!.addSubview(cancelButton!)

        titleLabel = UILabel()
        titleLabel!.text = ""
        titleLabel!.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel!.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        toolView!.addSubview(titleLabel!)

        relayButton = UIButton(type: .custom)
        relayButton!.setImage(UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_mutilselect_forward")), for: .normal)
        relayButton!.addTarget(self, action: #selector(onRelay(_:)), for: .touchUpInside)
        menuView!.addSubview(relayButton!)

        deleteButton = UIButton(type: .custom)
        deleteButton!.setImage(UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_mutilselect_delete")), for: .normal)
        deleteButton!.addTarget(self, action: #selector(onDelete(_:)), for: .touchUpInside)
        menuView!.addSubview(deleteButton!)

        selectedCountLabel = UILabel()
        selectedCountLabel!.text = "1 Selected"
        selectedCountLabel!.font = UIFont.systemFont(ofSize: 14.0)
        menuView!.addSubview(selectedCountLabel!)

        bottomCancelButton = UIButton(type: .custom)
        bottomCancelButton!.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        bottomCancelButton!.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        bottomCancelButton!.setTitleColor(UIColor.systemBlue, for: .normal)
        bottomCancelButton!.addTarget(self, action: #selector(onCancel(_:)), for: .touchUpInside)
        menuView!.addSubview(bottomCancelButton!)
    }

    @objc private func onCancel(_ cancelButton: UIButton) {
        delegate?.onCancelClicked?(self)
    }

    @objc private func onRelay(_ cancelButton: UIButton) {
        delegate?.onRelayClicked?(self)
    }

    @objc private func onDelete(_ cancelButton: UIButton) {
        delegate?.onDeleteClicked?(self)
    }
}
