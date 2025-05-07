import SnapKit
import TUICore
import UIKit

public let kTUISecurityStrikeViewTopLineToBottom = 28
public let kTUISecurityStrikeViewTopLineMargin = 14.5

public class TUISecurityStrikeView: UIView {
    var topLine: UIView = .init()
    public var textLabel: UILabel = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        topLine.backgroundColor = TUISwift.tuiDynamicColor("", themeModule: TUIThemeModule.timCommon, defaultColor: "#E5C7C7")
        addSubview(topLine)

        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.text = TUISwift.timCommonLocalizableString("TUIKitMessageTypeSecurityStrike")
        textLabel.textColor = TUISwift.tuiDynamicColor("", themeModule: TUIThemeModule.timCommon, defaultColor: "#DA2222")
        textLabel.numberOfLines = 0
        textLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        addSubview(textLabel)
    }

    override public class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override public func updateConstraints() {
        super.updateConstraints()

        topLine.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(14.5)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(0.5)
        }

        textLabel.sizeToFit()
        textLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-11)
            make.width.equalToSuperview()
        }
    }

    static func changeImageColor(with color: UIColor, image: UIImage, alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setAlpha(alpha)
        context.setBlendMode(.normal)
        let rect = CGRect(origin: .zero, size: image.size)
        context.clip(to: rect, mask: image.cgImage!)
        color.setFill()
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
