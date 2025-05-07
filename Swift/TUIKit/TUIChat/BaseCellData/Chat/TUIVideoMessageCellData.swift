import Foundation
import TIMCommon
import TUICore

class TUIVideoMessageCellData: TUIBubbleMessageCellData, TUIMessageCellDataFileUploadProtocol {
    @objc dynamic var thumbImage: UIImage?
    @objc dynamic var thumbProgress: UInt = 0
    @objc dynamic var uploadProgress: UInt = 100
    @objc dynamic var videoProgress: UInt = 0
    @objc dynamic var videoPath: String?
    var snapshotPath: String?
    var videoItem: TUIVideoItem?
    var snapshotItem: TUISnapshotItem?

    var isPlaceHolderCellData: Bool = false

    private var videoUrl: String?
    private var isDownloadingSnapshot: Bool = false
    private var isDownloadingVideo: Bool = false
    private var onFinish: TUIVideoMessageDownloadCallback?

    override init(direction: TMsgDirection) {
        super.init(direction: direction)
        self.uploadProgress = 100
        self.isDownloadingVideo = false
        self.isDownloadingSnapshot = false
        if direction == .incoming {
            self.cellLayout = TUIMessageCellLayout.incomingVideoMessageLayout
        } else {
            self.cellLayout = TUIMessageCellLayout.outgoingVideoMessageLayout
        }
    }

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.videoElem else {
            return TUIVideoMessageCellData(direction: .incoming)
        }

        let videoData = TUIVideoMessageCellData(direction: message.isSelf ? .outgoing : .incoming)
        videoData.videoPath = elem.videoPath
        videoData.snapshotPath = elem.snapshotPath

        videoData.videoItem = TUIVideoItem()
        videoData.videoItem?.uuid = elem.videoUUID ?? ""
        videoData.videoItem?.type = elem.videoType ?? ""
        videoData.videoItem?.length = Int(elem.videoSize)
        videoData.videoItem?.duration = Int(elem.duration)

        videoData.snapshotItem = TUISnapshotItem()
        videoData.snapshotItem?.uuid = elem.snapshotUUID ?? ""
        videoData.snapshotItem?.length = Int(elem.snapshotSize)
        videoData.snapshotItem?.size = CGSizeMake(CGFloat(elem.snapshotWidth), CGFloat(elem.snapshotHeight))
        videoData.reuseId = "TVideoMessageCell"

        return videoData
    }

    static func placeholderCellData(snapshotUrl: String, thumbImage: UIImage) -> TUIMessageCellData {
        let videoData = TUIVideoMessageCellData(direction: .outgoing)
        videoData.thumbImage = thumbImage
        videoData.snapshotPath = snapshotUrl
        videoData.videoItem = TUIVideoItem()
        videoData.snapshotItem = TUISnapshotItem()
        videoData.snapshotItem?.size = thumbImage.size == .zero ? CGSize(width: TUISwift.kScale375(100), height: TUISwift.kScale375(100)) : thumbImage.size
        videoData.reuseId = "TVideoMessageCell"
        videoData.avatarUrl = URL(string: TUILogin.getFaceUrl() ?? "")
        videoData.isPlaceHolderCellData = true
        return videoData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIkitMessageTypeVideo")
    }

    override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIVideoReplyQuoteViewData")
    }

    override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIVideoReplyQuoteView")
    }

    func downloadThumb(finish: TUIVideoMessageDownloadCallback? = nil) {
        onFinish = finish
        downloadThumb()
    }

    func downloadThumb() {
        var isExist = false
        let path = getSnapshotPath(isExist: &isExist)
        if isExist {
            decodeThumb()
            return
        }

        if isDownloadingSnapshot {
            return
        }
        isDownloadingSnapshot = true
        let message: V2TIMMessage? = innerMessage
        guard let imMsg = message, imMsg.elemType == .ELEM_TYPE_VIDEO else { return }

        updateThumbProgress(1)
        imMsg.videoElem?.downloadSnapshot(
            path: path,
            progress: { [weak self] curSize, totalSize in
                guard let self else { return }
                self.updateThumbProgress(UInt(max(1, curSize * 100 / totalSize)))
            },
            succ: { [weak self] in
                guard let self else { return }
                self.isDownloadingSnapshot = false
                self.updateThumbProgress(100)
                self.decodeThumb()
            },
            fail: { [weak self] _, _ in
                guard let self else { return }
                self.isDownloadingSnapshot = false
            }
        )
    }

    private func updateThumbProgress(_ progress: UInt) {
        DispatchQueue.main.async {
            self.thumbProgress = progress
        }
    }

    private func decodeThumb() {
        var isExist = false
        let path = getSnapshotPath(isExist: &isExist)
        if !isExist {
            return
        }

        TUITool.asyncDecodeImage(path, complete: { [weak self] _, image in
            guard let self else { return }
            DispatchQueue.main.async {
                self.thumbImage = image
                self.thumbProgress = 100
                self.onFinish?()
            }
        })
    }

    func downloadVideo() {
        var isExist = false
        let path = getVideoPath(isExist: &isExist)
        if isExist {
            return
        }

        if isDownloadingVideo {
            return
        }
        isDownloadingVideo = true

        let message: V2TIMMessage? = innerMessage
        guard let imMsg = message, imMsg.elemType == .ELEM_TYPE_VIDEO else { return }

        imMsg.videoElem?.downloadVideo(path: path,
                                       progress: { [weak self] curSize, totalSize in
                                           guard let self else { return }
                                           self.updateVideoProgress(UInt(curSize * 100 / totalSize))
                                       },
                                       succ: { [weak self] in
                                           guard let self else { return }
                                           self.isDownloadingVideo = false
                                           self.updateVideoProgress(100)
                                           DispatchQueue.main.async {
                                               self.videoPath = path
                                           }
                                       },
                                       fail: { [weak self] _, _ in
                                           guard let self else { return }
                                           self.isDownloadingVideo = false
                                       })
    }

    private func updateVideoProgress(_ progress: UInt) {
        DispatchQueue.main.async {
            self.videoProgress = progress
        }
    }

    func getVideoUrl(urlCallBack: ((String?) -> Void)?) {
        guard let urlCallBack = urlCallBack else { return }
        if let videoUrl = videoUrl {
            urlCallBack(videoUrl)
            return
        }

        let message: V2TIMMessage? = innerMessage
        guard let imMsg = message, imMsg.elemType == .ELEM_TYPE_VIDEO else { return }
        imMsg.videoElem?.getVideoUrl { [weak self] url in
            guard let self else { return }
            self.videoUrl = url
            urlCallBack(url)
        }
    }

    func isVideoExist() -> Bool {
        var isExist = false
        _ = getVideoPath(isExist: &isExist)
        return isExist
    }

    private func getVideoPath(isExist: inout Bool) -> String {
        var path: String?
        var isDir = ObjCBool(false)
        isExist = false

        if let videoPath = videoPath, !videoPath.isEmpty, let lastComp = URL(string: videoPath)?.lastPathComponent {
            path = "\(TUISwift.tuiKit_Video_Path())\(lastComp)"
            if FileManager.default.fileExists(atPath: path!, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist, let videoItem = videoItem, !videoItem.uuid.isEmpty, !videoItem.type.isEmpty {
            path = "\(TUISwift.tuiKit_Video_Path())\(videoItem.uuid).\(videoItem.type)"
            if FileManager.default.fileExists(atPath: path!, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if isExist {
            videoPath = path!
        }

        return path ?? ""
    }

    private func getSnapshotPath(isExist: inout Bool) -> String {
        var path: String?
        var isDir = ObjCBool(false)
        isExist = false

        if let snapshotPath = snapshotPath, let lastComp = URL(string: snapshotPath)?.lastPathComponent, !snapshotPath.isEmpty {
            path = "\(TUISwift.tuiKit_Video_Path())\(lastComp)"
            if FileManager.default.fileExists(atPath: path!, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist, let snapshotItem = snapshotItem, !snapshotItem.uuid.isEmpty {
            path = "\(TUISwift.tuiKit_Video_Path())\(snapshotItem.uuid)"
            if FileManager.default.fileExists(atPath: path!, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        return path ?? ""
    }
}
