import Accelerate
import UIKit

extension UIImage {
    func applyLightEffect() -> UIImage? {
        let tintColor = UIColor(white: 1.0, alpha: 0.3)
        return applyBlurWithRadius(10, tintColor: tintColor, saturationDeltaFactor: 1.8, maskImage: nil)
    }

    func applyExtraLightEffect() -> UIImage? {
        let tintColor = UIColor(white: 0.97, alpha: 0.82)
        return applyBlurWithRadius(20, tintColor: tintColor, saturationDeltaFactor: 1.8, maskImage: nil)
    }

    func applyDarkEffect() -> UIImage? {
        let tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        return applyBlurWithRadius(20, tintColor: tintColor, saturationDeltaFactor: 1.8, maskImage: nil)
    }

    func applyTintEffect(withColor tintColor: UIColor) -> UIImage? {
        let effectColorAlpha: CGFloat = 0.6
        var effectColor = tintColor
        let componentCount = tintColor.cgColor.numberOfComponents
        if componentCount == 2 {
            var b: CGFloat = 0
            if tintColor.getWhite(&b, alpha: nil) {
                effectColor = UIColor(white: b, alpha: effectColorAlpha)
            }
        } else {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
            if tintColor.getRed(&r, green: &g, blue: &b, alpha: nil) {
                effectColor = UIColor(red: r, green: g, blue: b, alpha: effectColorAlpha)
            }
        }
        return applyBlurWithRadius(10, tintColor: effectColor, saturationDeltaFactor: -1.0, maskImage: nil)
    }

    func applyBlurWithRadius(_ blurRadius: CGFloat, tintColor: UIColor?, saturationDeltaFactor: CGFloat, maskImage: UIImage?) -> UIImage? {
        guard size.width >= 1, size.height >= 1 else {
            print("*** error: invalid size: (\(size.width) x \(size.height)). Both dimensions must be >= 1: \(self)")
            return nil
        }
        guard let cgImage = cgImage else {
            print("*** error: image must be backed by a CGImage: \(self)")
            return nil
        }
        if let maskImage = maskImage, maskImage.cgImage == nil {
            print("*** error: maskImage must be backed by a CGImage: \(maskImage)")
            return nil
        }

        let imageRect = CGRect(origin: .zero, size: size)
        var effectImage = self

        let hasBlur = blurRadius > .ulpOfOne
        let hasSaturationChange = abs(saturationDeltaFactor - 1.0) > .ulpOfOne
        if hasBlur || hasSaturationChange {
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            guard let effectInContext = UIGraphicsGetCurrentContext() else { return nil }
            effectInContext.scaleBy(x: 1.0, y: -1.0)
            effectInContext.translateBy(x: 0, y: -size.height)
            effectInContext.draw(cgImage, in: imageRect)

            var effectInBuffer = vImage_Buffer()
            effectInBuffer.data = effectInContext.data
            effectInBuffer.width = vImagePixelCount(effectInContext.width)
            effectInBuffer.height = vImagePixelCount(effectInContext.height)
            effectInBuffer.rowBytes = effectInContext.bytesPerRow

            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            guard let effectOutContext = UIGraphicsGetCurrentContext() else { return nil }
            var effectOutBuffer = vImage_Buffer()
            effectOutBuffer.data = effectOutContext.data
            effectOutBuffer.width = vImagePixelCount(effectOutContext.width)
            effectOutBuffer.height = vImagePixelCount(effectOutContext.height)
            effectOutBuffer.rowBytes = effectOutContext.bytesPerRow

            if hasBlur {
                let inputRadius = blurRadius * UIScreen.main.scale
                let factor = 3.0 * sqrt(2 * .pi)
                let adjustedRadius = inputRadius * factor
                let roundedRadius = adjustedRadius / 4 + 0.5
                var radius = floor(roundedRadius)
                if radius.truncatingRemainder(dividingBy: 2) != 1 {
                    radius += 1
                }
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
                vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, UInt32(radius), UInt32(radius), nil, vImage_Flags(kvImageEdgeExtend))
            }
            var effectImageBuffersAreSwapped = false
            if hasSaturationChange {
                let s = saturationDeltaFactor
                let floatingPointSaturationMatrix: [CGFloat] = [
                    0.0722 + 0.9278 * s, 0.0722 - 0.0722 * s, 0.0722 - 0.0722 * s, 0,
                    0.7152 - 0.7152 * s, 0.7152 + 0.2848 * s, 0.7152 - 0.7152 * s, 0,
                    0.2126 - 0.2126 * s, 0.2126 - 0.2126 * s, 0.2126 + 0.7873 * s, 0,
                    0, 0, 0, 1
                ]
                let divisor: Int32 = 256
                let matrixSize = floatingPointSaturationMatrix.count
                var saturationMatrix = [Int16](repeating: 0, count: matrixSize)
                for i in 0 ..< matrixSize {
                    saturationMatrix[i] = Int16(round(floatingPointSaturationMatrix[i] * CGFloat(divisor)))
                }
                if hasBlur {
                    vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))
                    effectImageBuffersAreSwapped = true
                } else {
                    vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))
                }
            }
            if !effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
            }
            UIGraphicsEndImageContext()

            if effectImageBuffersAreSwapped {
                effectImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
            }
            UIGraphicsEndImageContext()
        }

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        guard let outputContext = UIGraphicsGetCurrentContext() else { return nil }
        outputContext.scaleBy(x: 1.0, y: -1.0)
        outputContext.translateBy(x: 0, y: -size.height)

        outputContext.draw(cgImage, in: imageRect)

        if hasBlur {
            outputContext.saveGState()
            if let maskImage = maskImage {
                outputContext.clip(to: imageRect, mask: maskImage.cgImage!)
            }
            outputContext.draw(effectImage.cgImage!, in: imageRect)
            outputContext.restoreGState()
        }

        if let tintColor = tintColor {
            outputContext.saveGState()
            outputContext.setFillColor(tintColor.cgColor)
            outputContext.fill(imageRect)
            outputContext.restoreGState()
        }

        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return outputImage
    }
}

extension UIImage {
    static func snapshotImage(with view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, true, UIScreen.main.scale)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
