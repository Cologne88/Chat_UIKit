import TIMCommon
import UIKit

public class TUIConversationMultiChooseView_Minimalist: UIView {
    // Top toolbar
    var toolView: UIView!
    var cancelButton: UIButton!
    var titleLabel: UILabel!

    // Bottom menu bar
    var menuView: UIView!
    var hideButton: TUIBlockButton!
    public var readButton: TUIBlockButton!
    var deleteButton: TUIBlockButton!

    private var separtorLayer: CALayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            return nil
        } else {
            return hitView
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        var toolHeight: CGFloat = 44
        var menuHeight: CGFloat = 54 + 3
        var centerTopOffset: CGFloat = 0
        var centerBottomOffset: CGFloat = 0

        if #available(iOS 11.0, *) {
            toolHeight += safeAreaInsets.top
            menuHeight += safeAreaInsets.bottom
            centerTopOffset = safeAreaInsets.top
            centerBottomOffset = safeAreaInsets.bottom
        }

        if let toolView = toolView {
            toolView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: toolHeight)
        }
        if let menuView = menuView {
            menuView.frame = CGRect(x: 0, y: bounds.size.height - menuHeight, width: bounds.size.width, height: menuHeight)
        }

        // toolView
        do {
            let centerY = 0.5 * (toolView.bounds.size.height - cancelButton.bounds.size.height)
            cancelButton.frame = CGRect(x: 10, y: centerY + 0.5 * centerTopOffset, width: cancelButton.bounds.size.width, height: cancelButton.bounds.size.height)

            titleLabel.sizeToFit()
            titleLabel.center = toolView.center
            var titleRect = titleLabel.frame
            titleRect.origin.y += 0.5 * centerTopOffset
            titleLabel.frame = titleRect
        }

        // menuView
        do {
            let count = menuView.subviews.count
            let width = menuView.bounds.size.width / CGFloat(count)
            let height = (menuView.bounds.size.height - centerBottomOffset)
            for i in 0 ..< menuView.subviews.count {
                let sub = menuView.subviews[i]
                let centerY = (menuView.bounds.size.height - height) * 0.5
                sub.frame = CGRect(x: CGFloat(i) * width, y: centerY - 0.5 * centerBottomOffset, width: width, height: height)
            }
        }
    }

    private func setupViews() {
        toolView = UIView()
        toolView.backgroundColor = TUISwift.timCommonDynamicColor("head_bg_gradient_start_color", defaultColor: "#EBF0F6")
        addSubview(toolView)

        menuView = UIView()
        menuView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_controller_bg_color", defaultColor: "#FFFFFF")
        if let separtorLayer = separtorLayer {
            menuView.layer.addSublayer(separtorLayer)
        }
        addSubview(menuView)

        cancelButton = UIButton(type: .custom)
        cancelButton.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        cancelButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        cancelButton.sizeToFit()
        toolView.addSubview(cancelButton)

        titleLabel = UILabel()
        titleLabel.text = ""
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        toolView.addSubview(titleLabel)

        hideButton = TUIBlockButton(type: .custom)
        hideButton.setTitle("Mark as Hide", for: .normal)
        hideButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        hideButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF"), for: .normal)
        hideButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF").withAlphaComponent(0.3), for: .disabled)
        menuView.addSubview(hideButton)

        readButton = TUIBlockButton(type: .custom)
        readButton.setTitle("Mark as Read", for: .normal)
        readButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        readButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF"), for: .normal)
        readButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF").withAlphaComponent(0.3), for: .disabled)
        menuView.addSubview(readButton)

        deleteButton = TUIBlockButton(type: .custom)
        deleteButton.setTitle(TUISwift.timCommonLocalizableString("Delete"), for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        deleteButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF"), for: .normal)
        deleteButton.setTitleColor(TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF").withAlphaComponent(0.3), for: .disabled)
        menuView.addSubview(deleteButton)
    }
}
