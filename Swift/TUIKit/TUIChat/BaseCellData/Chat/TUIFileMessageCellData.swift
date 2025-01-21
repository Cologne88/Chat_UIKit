import Foundation
import TIMCommon

class TUIFileMessageCellData: TUIBubbleMessageCellData, TUIMessageCellDataFileUploadProtocol, TUIMessageCellDataFileDownloadProtocol {
    var path: String?
    var fileName: String?
    var uuid: String?
    var uploadProgress: UInt = 100
    @objc dynamic var downladProgress: UInt = 100
    var isDownloading: Bool = false

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

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.fileElem else { return TUIFileMessageCellData(direction: .MsgDirectionIncoming) }
        let fileData = TUIFileMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        fileData.path = elem.path.safeValue
        fileData.fileName = elem.filename.safeValue
        fileData.length = Int(elem.fileSize)
        fileData.uuid = elem.uuid.safeValue
        fileData.reuseId = TUISwift.tFileMessageCell_ReuseId()

        return fileData
    }

    override class func getDisplayString(_ message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIkitMessageTypeFile")
    }

    override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIFileReplyQuoteViewData")
    }

    override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIFileReplyQuoteView")
    }

    func downloadFile() {
        var isExist = false
        let path = getFilePath(&isExist)
        if isExist { return }

        let progress = TUIMessageProgressManager.shared.downloadProgress(forMessage: msgID)
        if progress != 0 { return }

        if isDownloading { return }
        isDownloading = true

        if innerMessage.elemType == .ELEM_TYPE_FILE {
            let msgID = self.msgID
            innerMessage.fileElem?.downloadFile(path, progress: { [weak self] curSize, totalSize in
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

        if direction == .MsgDirectionOutgoing {
            guard let path = path else { return nil }
            let lastComp = URL(string: path)?.lastPathComponent
            filePath = "\(TUISwift.tuiKit_File_Path() ?? "")\(lastComp ?? "")"
            if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist {
            filePath = "\(TUISwift.tuiKit_File_Path() ?? "")\(uuid ?? "")\(fileName ?? "")"
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
