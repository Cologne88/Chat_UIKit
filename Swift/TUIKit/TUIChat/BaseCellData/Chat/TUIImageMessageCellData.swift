import Foundation
import SDWebImage
import TIMCommon
import TUICore

class TUIImageMessageCellData: TUIBubbleMessageCellData, TUIMessageCellDataFileUploadProtocol {
    @objc dynamic var thumbImage: UIImage?
    @objc dynamic var originImage: UIImage?
    @objc dynamic var largeImage: UIImage?
    @objc dynamic var thumbProgress: UInt = 0
    var path: String?
    var length: Int?
    var items: [TUIImageItem] = []
    @objc dynamic var originProgress: UInt = 0
    @objc dynamic var largeProgress: UInt = 0
    @objc dynamic var uploadProgress: UInt = 100
    var isSuperLongImage: Bool = false

    private var isDownloading: Bool = false
    private var onFinish: TUIImageMessageDownloadCallback?

    override init(direction: TMsgDirection) {
        super.init(direction: direction)
        self.uploadProgress = 100
        self.cellLayout = direction == .incoming ? TUIMessageCellLayout.incomingImageMessageLayout : TUIMessageCellLayout.outgoingImageMessageLayout
    }

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.imageElem else {
            return TUIImageMessageCellData(direction: .incoming)
        }

        let imageData = TUIImageMessageCellData(direction: message.isSelf ? .outgoing : .incoming)
        imageData.path = elem.path

        for item in elem.imageList {
            let itemData = TUIImageItem()
            itemData.uuid = item.uuid ?? ""
            itemData.size = CGSizeMake(CGFloat(item.width), CGFloat(item.height))

            switch item.type {
            case .IMAGE_TYPE_THUMB:
                itemData.type = .thumb
            case .IMAGE_TYPE_LARGE:
                itemData.type = .large
            case .IMAGE_TYPE_ORIGIN:
                itemData.type = .origin
            default:
                break
            }

            imageData.items.append(itemData)
        }

        imageData.reuseId = "TImageMessageCell"
        return imageData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIkitMessageTypeImage")
    }

    override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIImageReplyQuoteViewData")
    }

    override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIImageReplyQuoteView")
    }

    func getImagePath(type: TUIImageType, isExist: inout Bool) -> String? {
        var imagePath = ""
        var isDir = ObjCBool(false)
        isExist = false

        if direction == .outgoing {
            let lastComp = URL(string: path ?? "")?.lastPathComponent
            imagePath = "\(TUISwift.tuiKit_Image_Path())\(lastComp ?? "")"
            if FileManager.default.fileExists(atPath: imagePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist {
            if let tImageItem = getTImageItem(type: type) {
                imagePath = "\(TUISwift.tuiKit_Image_Path())\(tImageItem.uuid)_\(tImageItem.type.rawValue)"
                if FileManager.default.fileExists(atPath: imagePath, isDirectory: &isDir), !isDir.boolValue {
                    isExist = true
                }
            }
        }

        return imagePath
    }

    func downloadImage(type: TUIImageType, finish: TUIImageMessageDownloadCallback? = nil) {
        onFinish = finish
        downloadImage(type: type)
    }

    func downloadImage(type: TUIImageType) {
        var isExist = false
        let path = getImagePath(type: type, isExist: &isExist)
        if isExist {
            decodeImage(type: type)
            return
        }

        if isDownloading {
            return
        }
        isDownloading = true

        guard let imImage = getIMImage(type: type) else { return }

        if let path = path {
            imImage.downloadImage(path: path, progress: { [weak self] curSize, totalSize in
                guard let self = self else { return }
                let progress = curSize * 100 / totalSize
                self.updateProgress(UInt(min(progress, 99)), withType: type)
            }, succ: { [weak self] in
                guard let self = self else { return }
                self.isDownloading = false
                self.updateProgress(100, withType: type)
                self.decodeImage(type: type)
            }, fail: { [weak self] _, _ in
                self?.isDownloading = false
                self?.decodeImage(type: type)
            })
        }
    }

    private func updateProgress(_ progress: UInt, withType type: TUIImageType) {
        DispatchQueue.main.async {
            switch type {
            case .thumb:
                self.thumbProgress = progress
            case .large:
                self.largeProgress = progress
            case .origin:
                self.originProgress = progress
            }
        }
    }

    func decodeImage(type: TUIImageType) {
        var isExist = false
        let path = getImagePath(type: type, isExist: &isExist)
        if !isExist {
            return
        }

        let finishBlock: (UIImage) -> Void = { [weak self] image in
            guard let self = self else { return }
            switch type {
            case .thumb:
                self.thumbImage = image
                self.thumbProgress = 100
                self.uploadProgress = 100
            case .large:
                self.largeImage = image
                self.largeProgress = 100
            case .origin:
                self.originImage = image
                self.originProgress = 100
            }
            self.onFinish?()
        }

        guard let path = path else { return }
        let cacheKey = String(path.dropFirst(TUISwift.tuiKit_Image_Path().count))
        if let cacheImage = SDImageCache.shared.imageFromCache(forKey: cacheKey) {
            finishBlock(cacheImage)
        } else {
            TUITool.asyncDecodeImage(path, complete: { path, image in
                guard let path = path, let image = image else { return }
                DispatchQueue.main.async {
                    if !path.tui_contains(".gif") || image.sd_imageFormat != .GIF {
                        // The gif image is too large to be cached in memory. Only cache images less than 1M
                        if let imageData = image.sd_imageData(), imageData.count < 1 * 1024 * 1024 {
                            SDImageCache.shared.storeImage(toMemory: image, forKey: cacheKey)
                        }
                    }
                    finishBlock(image)
                }
            })
        }
    }

    private func getTImageItem(type: TUIImageType) -> TUIImageItem? {
        return items.first { $0.type == type }
    }

    private func getIMImage(type: TUIImageType) -> V2TIMImage? {
        let msg: V2TIMMessage? = innerMessage
        guard let imMsg = msg, imMsg.elemType == .ELEM_TYPE_IMAGE else {
            return nil
        }

        if let imageElem = imMsg.imageElem {
            for imImage in imageElem.imageList {
                if type == .thumb && imImage.type == .IMAGE_TYPE_THUMB {
                    return imImage
                } else if type == .origin && imImage.type == .IMAGE_TYPE_ORIGIN {
                    return imImage
                } else if type == .large && imImage.type == .IMAGE_TYPE_LARGE {
                    return imImage
                }
            }
        }
        return nil
    }
}
