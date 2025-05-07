import UIKit

extension UIView {
    func setRTLFrame(_ frame: CGRect, width: CGFloat) {
        if TUISwift.isRTL() {
            guard self.superview != nil else {
                assertionFailure("must invoke after having superView")
                return
            }
            let x = width - frame.origin.x - frame.size.width
            var newFrame = frame
            newFrame.origin.x = x
            self.frame = newFrame
        } else {
            self.frame = frame
        }
    }

    func setRTLFrame(_ frame: CGRect) {
        if let superview = self.superview {
            self.setRTLFrame(frame, width: superview.frame.size.width)
        }
    }

    @objc public func resetFrameToFitRTL() {
        self.setRTLFrame(self.frame)
    }
}

extension UIImage {
    func checkOverturn() -> UIImage {
        if TUISwift.isRTL() {
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
            guard let bitmap = UIGraphicsGetCurrentContext() else { return self }
            bitmap.translateBy(x: self.size.width / 2, y: self.size.height / 2)
            bitmap.scaleBy(x: -1.0, y: -1.0)
            bitmap.translateBy(x: -self.size.width / 2, y: -self.size.height / 2)
            bitmap.draw(self.cgImage!, in: CGRect(origin: .zero, size: self.size))
            let image = UIGraphicsGetImageFromCurrentImageContext() ?? self
            UIGraphicsEndImageContext()
            return image
        }
        return self
    }

    func imageFlippedForRightToLeftLayoutDirection() -> UIImage {
        if TUISwift.isRTL() {
            return UIImage(cgImage: self.cgImage!, scale: self.scale, orientation: .upMirrored)
        }
        return self
    }

    public func rtlImageFlippedForRightToLeftLayoutDirection() -> UIImage {
        if TUISwift.isRTL() {
            if #available(iOS 13.0, *) {
                let scaleTraitCollection = UITraitCollection.current
                let darkUnscaledTraitCollection = UITraitCollection(userInterfaceStyle: .dark)
                let darkScaledTraitCollection = UITraitCollection(traitsFrom: [scaleTraitCollection, darkUnscaledTraitCollection])

                let lightImage = self.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: .light)).withHorizontallyFlippedOrientation()
                let darkImage = self.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: .dark)).withHorizontallyFlippedOrientation()

                if let lightImage = lightImage, let darkImage = darkImage {
                    if let config = self.configuration?.withTraitCollection(UITraitCollection(userInterfaceStyle: .light)) {
                        let image = lightImage.withConfiguration(config)
                        image.imageAsset?.register(darkImage, with: darkScaledTraitCollection)
                        return image
                    } else {
                        return self
                    }
                } else {
                    return self
                }
            } else {
                return UIImage(cgImage: self.cgImage!, scale: self.scale, orientation: .upMirrored)
            }
        }
        return self
    }

    public class func safeImage(_ imageName: String) -> UIImage {
        return UIImage(named: imageName) ?? UIImage()
    }
}

extension UINavigationController {
    @objc public static func swiftLoad() {
        let originalSelector = #selector(UINavigationController.init(rootViewController:))
        let swizzledSelector = #selector(UINavigationController.rtl_initWithRootViewController(_:))

        if let originalMethod = class_getInstanceMethod(UINavigationController.self, originalSelector),
           let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledSelector)
        {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc func rtl_initWithRootViewController(_ rootViewController: UIViewController) -> UINavigationController {
        let instance = self.rtl_initWithRootViewController(rootViewController)
        if #available(iOS 9.0, *) {
            if TUISwift.isRTL() {
                instance.navigationBar.semanticContentAttribute = UIView.appearance().semanticContentAttribute
                instance.view.semanticContentAttribute = UIView.appearance().semanticContentAttribute
            }
        }
        return instance
    }
}

public func rtlEdgeInsetsWithInsets(_ insets: UIEdgeInsets) -> UIEdgeInsets {
    if insets.left != insets.right && TUISwift.isRTL() {
        return UIEdgeInsets(top: insets.top, left: insets.right, bottom: insets.bottom, right: insets.left)
    }
    return insets
}

extension UIButton {
    @objc public static func swiftLoad() {
        self.swizzleInstanceMethod(UIButton.self, #selector(setter: UIButton.contentEdgeInsets), #selector(self.rtl_setContentEdgeInsets(_:)))
        self.swizzleInstanceMethod(UIButton.self, #selector(setter: UIButton.imageEdgeInsets), #selector(self.rtl_setImageEdgeInsets(_:)))
        self.swizzleInstanceMethod(UIButton.self, #selector(setter: UIButton.titleEdgeInsets), #selector(self.rtl_setTitleEdgeInsets(_:)))
    }

    static func swizzleInstanceMethod(_ cls: AnyClass?, _ originSelector: Selector, _ swizzleSelector: Selector) {
        guard let cls = cls else {
            return
        }

        // if current class not exist selector, then get super
        guard let originalMethod = class_getInstanceMethod(cls, originSelector),
              let swizzledMethod = class_getInstanceMethod(cls, swizzleSelector)
        else {
            return
        }

        // add selector if not exist, implement append with method
        if class_addMethod(cls,
                           originSelector,
                           method_getImplementation(swizzledMethod),
                           method_getTypeEncoding(swizzledMethod))
        {
            // replace class instance method, added if selector not exist
            // for class cluster , it always add new selector here
            class_replaceMethod(cls,
                                swizzleSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))
        } else {
            // swizzleMethod maybe belong to super
            class_replaceMethod(cls,
                                swizzleSelector,
                                class_replaceMethod(cls,
                                                    originSelector,
                                                    method_getImplementation(swizzledMethod),
                                                    method_getTypeEncoding(swizzledMethod))!,
                                method_getTypeEncoding(originalMethod))
        }
    }

    @objc func rtl_setContentEdgeInsets(_ contentEdgeInsets: UIEdgeInsets) {
        self.rtl_setContentEdgeInsets(rtlEdgeInsetsWithInsets(contentEdgeInsets))
    }

    @objc func rtl_setImageEdgeInsets(_ imageEdgeInsets: UIEdgeInsets) {
        self.rtl_setImageEdgeInsets(rtlEdgeInsetsWithInsets(imageEdgeInsets))
    }

    @objc func rtl_setTitleEdgeInsets(_ titleEdgeInsets: UIEdgeInsets) {
        self.rtl_setTitleEdgeInsets(rtlEdgeInsetsWithInsets(titleEdgeInsets))
    }
}

public enum TUITextRTLAlignment: UInt {
    case undefine
    case leading
    case trailing
    case center
}

public extension UILabel {
    private enum AssociatedKeys {
        static var rtlAlignment: String = "rtlAlignment"
    }

    var rtlAlignment: TUITextRTLAlignment {
        get {
            if let number = objc_getAssociatedObject(self, AssociatedKeys.rtlAlignment) as? UInt {
                return TUITextRTLAlignment(rawValue: number) ?? .undefine
            }
            return .undefine
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.rtlAlignment, NSNumber(value: newValue.rawValue), .OBJC_ASSOCIATION_ASSIGN)

            switch newValue {
            case .leading:
                self.textAlignment = TUISwift.isRTL() ? .right : .left
            case .trailing:
                self.textAlignment = TUISwift.isRTL() ? .left : .right
            case .center:
                self.textAlignment = .center
            case .undefine:
                break
            @unknown default:
                break
            }
        }
    }
}

// TODO: TO BE DELETED
// extension NSMutableAttributedString {
//     func setRtlAlignment(_ rtlAlignment: TUITextRTLAlignment) {
//         switch rtlAlignment {
//         case .leading:
//             self.textAlignment = TUISwift.isRTL() ? .right : .left
//         case .trailing:
//             self.textAlignment = TUISwift.isRTL() ? .left : .right
//         case .center:
//             self.textAlignment = .center
//         case .undefine:
//             break
//         @unknown default:
//             break
//         }
//     }
// }

func isRTLString(_ string: String) -> Bool {
    return string.hasPrefix("\u{202B}") || string.hasPrefix("\u{202A}")
}

public func rtlString(_ string: String) -> String {
    if string.isEmpty || isRTLString(string) {
        return string
    }
    return TUISwift.isRTL() ? "\u{202B}\(string)" : "\u{202A}\(string)"
}

public func rtlAttributeString(_ attributeString: NSAttributedString, textAlignment: NSTextAlignment) -> NSAttributedString {
    if attributeString.length == 0 {
        return attributeString
    }
    let originAttributes = attributeString.attributes(at: 0, effectiveRange: nil)
    var style = originAttributes[.paragraphStyle] as? NSParagraphStyle

    if style != nil && isRTLString(attributeString.string) {
        return attributeString
    }

    var attributes = originAttributes
    if style == nil {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        let testLabel = UILabel()
        testLabel.textAlignment = textAlignment
        mutableParagraphStyle.alignment = testLabel.textAlignment
        style = mutableParagraphStyle
        attributes[.paragraphStyle] = mutableParagraphStyle
    }
    let string = rtlString(attributeString.string)
    return NSAttributedString(string: string, attributes: attributes)
}

public class TUICollectionRTLFitFlowLayout: UICollectionViewFlowLayout {
    func effectiveUserInterfaceLayoutDirection() -> UIUserInterfaceLayoutDirection {
        if TUISwift.isRTL() {
            return .rightToLeft
        }
        return .leftToRight
    }

    override public var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return TUISwift.isRTL()
    }
}
