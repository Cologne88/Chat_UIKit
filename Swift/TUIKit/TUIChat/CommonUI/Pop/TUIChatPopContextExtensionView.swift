import TIMCommon
import UIKit

class TUIChatPopContextExtensionItem: NSObject {
    var title: String?
    var titleColor: UIColor?
    var titleFont: UIFont?
    var weight: Int = 0
    var markIcon: UIImage?
    var itemHeight: CGFloat = 0
    var needBottomLine: Bool = false
    var actionHandler: ((TUIChatPopContextExtensionItem) -> Void)?

    override init() {
        super.init()
    }

    init(title: String, markIcon: UIImage?, weight: Int, actionHandler: ((TUIChatPopContextExtensionItem) -> Void)?) {
        self.title = title
        self.markIcon = markIcon
        self.weight = weight
        self.actionHandler = actionHandler
    }
}

class TUIChatPopContextExtensionItemView: UIView {
    var item: TUIChatPopContextExtensionItem?
    var icon: UIImageView?
    var label: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configBaseUI(with item: TUIChatPopContextExtensionItem) {
        self.item = item
        let itemWidth = frame.size.width
        let padding: CGFloat = TUISwift.kScale390(16)
        let itemHeight = frame.size.height

        icon = UIImageView()
        addSubview(icon!)
        icon!.frame = CGRect(x: itemWidth - padding - TUISwift.kScale390(18), y: itemHeight * 0.5 - TUISwift.kScale390(18) * 0.5, width: TUISwift.kScale390(18), height: TUISwift.kScale390(18))
        icon!.image = item.markIcon

        label = UILabel()
        label!.frame = CGRect(x: padding, y: 0, width: itemWidth * 0.5, height: itemHeight)
        label!.text = item.title
        label!.font = item.titleFont ?? UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        label!.textAlignment = TUISwift.isRTL() ? .right : .left
        label!.textColor = item.titleColor ?? .black
        label!.isUserInteractionEnabled = false
        addSubview(label!)

        let backButton = UIButton(type: .system)
        backButton.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.frame = CGRect(x: 0, y: 0, width: itemWidth, height: itemHeight)
        addSubview(backButton)

        if item.needBottomLine {
            let line = UIView()
            line.backgroundColor = UIColor.tui_color(withHex: "DDDDDD")
            line.frame = CGRect(x: 0, y: itemHeight - TUISwift.kScale390(0.5), width: itemWidth, height: TUISwift.kScale390(0.5))
            addSubview(line)
        }
        layer.masksToBounds = true
        if TUISwift.isRTL() {
            for subview in subviews {
                subview.resetFrameToFitRTL()
            }
        }
    }

    @objc private func buttonClick() {
        guard let item = item else { return }
        item.actionHandler?(item)
    }
}

class TUIChatPopContextExtensionView: UIView {
    func configUI(with items: [TUIChatPopContextExtensionItem]?, topBottomMargin: CGFloat) {
        guard let items = items else { return }
        subviews.forEach { $0.removeFromSuperview() }
        for (i, item) in items.enumerated() {
            let itemView = TUIChatPopContextExtensionItemView()
            itemView.frame = CGRect(x: 0, y: TUISwift.kScale390(40) * CGFloat(i) + topBottomMargin, width: TUISwift.kScale390(180), height: TUISwift.kScale390(40))
            itemView.configBaseUI(with: item)
            addSubview(itemView)
        }
    }
}
