import TIMCommon
import UIKit

enum TUIImageReplyQuoteStatus: UInt {
    case initStatus = 0
    case downloading
    case success
    case failed
}

class TUIImageReplyQuoteViewData: TUIReplyQuoteViewData {
    var imageStatus: TUIImageReplyQuoteStatus = .initStatus
    var image: UIImage?
    var imageSize: CGSize = .zero

    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUIImageMessageCellData else {
            return nil
        }

        let myData = TUIImageReplyQuoteViewData()
        var thumb: V2TIMImage?
        for image in originCellData.innerMessage.imageElem?.imageList ?? [] {
            if image.type == .IMAGE_TYPE_THUMB {
                thumb = image
                break
            }
        }
        myData.imageSize = TUIImageReplyQuoteViewData.displaySizeWithOriginSize(originSize: CGSizeMake(CGFloat(thumb?.width ?? 60), CGFloat(thumb?.height ?? 60)))
        myData.originCellData = originCellData
        myData.imageStatus = .initStatus
        return myData
    }

    override func contentSize(maxWidth: CGFloat) -> CGSize {
        return imageSize
    }

    static func displaySizeWithOriginSize(originSize: CGSize) -> CGSize {
        guard originSize.width != 0, originSize.height != 0 else {
            return .zero
        }

        let max: CGFloat = 60
        var w: CGFloat = 0, h: CGFloat = 0
        if originSize.width > originSize.height {
            w = max
            h = max * originSize.height / originSize.width
        } else {
            w = max * originSize.width / originSize.height
            h = max
        }
        return CGSize(width: w, height: h)
    }

    func downloadImage() {
        imageStatus = .downloading
        if let imageData = originCellData as? TUIImageMessageCellData {
            imageData.downloadImage(type: .thumb) { [weak self] in
                self?.image = imageData.thumbImage
                self?.imageStatus = .success
                self?.onFinish?()
            }
        }
    }
}
