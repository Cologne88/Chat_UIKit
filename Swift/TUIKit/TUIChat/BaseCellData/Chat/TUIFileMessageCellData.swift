import Foundation
import TIMCommon

public class TUIFileMessageCellData: TUIBubbleMessageCellData, TUIMessageCellDataFileUploadProtocol, TUIMessageCellDataFileDownloadProtocol {
    public var downloadProgress: UInt = 0
    var path: String?
    var fileName: String?
    var uuid: String?
    public var uploadProgress: UInt = 100
    @objc public dynamic var downladProgress: UInt = 100
    public var isDownloading: Bool = false

    private var progressBlocks: [() -> Void] = []
    private var responseBlocks: [() -> Void] = []

    private var _length: Int = 0
    var length: Int {
        get {
            let message: V2TIMMessage? = innerMessage
            if let fileElem = message?.fileElem {
                _length = Int(fileElem.fileSize)
            }
            return _length
        }
        set {
            _length = newValue
        }
    }

    public override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.fileElem else { return TUIFileMessageCellData(direction: .incoming) }
        let fileData = TUIFileMessageCellData(direction: message.isSelf ? .outgoing : .incoming)
        fileData.path = elem.path
        fileData.fileName = elem.filename
        fileData.length = Int(elem.fileSize)
        fileData.uuid = elem.uuid
        fileData.reuseId = "TFileMessageCell"

        return fileData
    }

    public override class func getDisplayString(message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIkitMessageTypeFile")
    }

    public override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIFileReplyQuoteViewData")
    }

    public override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIFileReplyQuoteView")
    }

    func downloadFile() {
        var isExist = false
        let path = getFilePath(&isExist)
        if isExist { return }

        guard let msgID = msgID else { return }

        let progress = TUIMessageProgressManager.shared.downloadProgress(forMessage: msgID)
        if progress != 0 { return }

        if isDownloading { return }
        isDownloading = true

        if innerMessage?.elemType == .ELEM_TYPE_FILE {
            if let path = path {
                innerMessage?.fileElem?.downloadFile(path: path, progress: { [weak self] curSize, totalSize in
                    guard let self = self else { return }
                    let progress = curSize * 100 / totalSize
                    self.updateDownloadProgress(min(UInt(progress), 99))
                    TUIMessageProgressManager.shared.appendDownloadProgress(msgID, progress: min(progress, 99))
                }, succ: { [weak self] in
                    guard let self = self else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isDownloading = false
                        self.updateDownloadProgress(100)
                        TUIMessageProgressManager.shared.appendDownloadProgress(msgID, progress: 100)
                        DispatchQueue.main.async {
                            self.path = path
                        }
                    }
                }, fail: { [weak self] _, _ in
                    guard let self else { return }
                    self.isDownloading = false
                })
            }
        }
    }

    private func updateDownloadProgress(_ progress: UInt) {
        DispatchQueue.main.async {
            self.downladProgress = progress
        }
    }

    func isLocalExist() -> Bool {
        var isExist = false
        _ = getFilePath(&isExist)
        return isExist
    }

    func getFilePath(_ isExist: inout Bool) -> String? {
        var filePath = ""
        var isDir = ObjCBool(false)
        isExist = false

        if direction == .outgoing {
            guard let path = path else { return nil }
            let lastComp = URL(string: path)?.lastPathComponent
            filePath = "\(TUISwift.tuiKit_File_Path())\(lastComp ?? "")"
            if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist {
            filePath = "\(TUISwift.tuiKit_File_Path())\(uuid ?? "")\(fileName ?? "")"
            if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if isExist {
            path = filePath
        }

        return filePath
    }
}
