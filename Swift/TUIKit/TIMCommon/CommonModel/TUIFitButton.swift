import UIKit

public class TUIFitButton: UIButton {
    public var titleRect: CGRect = .zero
    public var imageRect: CGRect = .zero
    public var imageSize: CGSize = .zero
    public var titleSize: CGSize = .zero
    public var hoverImage: UIImage?
    public var normalImage: UIImage? {
        didSet {
            setImage(normalImage, for: .normal)
        }
    }

    override public func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        if !titleRect.equalTo(.zero) {
            return titleRect
        } else if !titleSize.equalTo(.zero) {
            let oldRect = super.titleRect(forContentRect: contentRect)
            var newRect = CGRect.zero
            newRect.origin.x = oldRect.origin.x + (oldRect.size.width - titleSize.width) / 2
            newRect.origin.y = oldRect.origin.y + (oldRect.size.height - titleSize.height) / 2
            newRect.size.width = titleSize.width
            newRect.size.height = titleSize.height
            return newRect
        }
        return super.titleRect(forContentRect: contentRect)
    }

    override public func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        if !imageRect.equalTo(.zero) {
            return imageRect
        } else if !imageSize.equalTo(.zero) {
            let oldRect = super.imageRect(forContentRect: contentRect)
            var newRect = CGRect.zero
            newRect.origin.x = oldRect.origin.x + (oldRect.size.width - imageSize.width) / 2
            newRect.origin.y = oldRect.origin.y + (oldRect.size.height - imageSize.height) / 2
            newRect.size.width = imageSize.width
            newRect.size.height = imageSize.height
            return newRect
        }
        return super.imageRect(forContentRect: contentRect)
    }
}

public class TUIBlockButton: TUIFitButton {
    public var clickCallBack: ((TUIBlockButton) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTarget(self, action: #selector(buttonTap(_:)), for: .touchUpInside)
    }

    @objc private func buttonTap(_ button: UIButton) {
        clickCallBack?(self)
    }
}
