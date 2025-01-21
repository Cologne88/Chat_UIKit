import Foundation
import ImSDK_Plus
import TIMCommon

enum TUIMediaLoadType: Int {
    case older = 1
    case newer = 2
    case olderAndNewer = 3
}

class TUIMessageBaseMediaDataProvider: NSObject {
    var conversationModel: TUIChatConversationModel?
    var loadType: TUIMediaLoadType = .olderAndNewer
    var loadMessage: V2TIMMessage?
    var isOlderNoMoreMsg: Bool = false
    var isNewerNoMoreMsg: Bool = false
    var pageCount: Int = 20
    @objc dynamic var mediaCellData: [TUIMessageCellData] = []
    var isLoadingData: Bool = false
    var isFirstLoad: Bool = true

    init(conversationModel: TUIChatConversationModel?) {
        self.conversationModel = conversationModel
        self.isOlderNoMoreMsg = false
        self.isNewerNoMoreMsg = false
        self.pageCount = 20
        self.mediaCellData = []
    }

    func loadMediaWithMessage(_ curMessage: V2TIMMessage) {
        self.loadMessage = curMessage
        self.loadType = .olderAndNewer
        if self.loadMessage?.status != .MSG_STATUS_SENDING {
            self.loadMedia()
        } else {
            var celldata = self.mediaCellData
            if let data = Self.getMediaCellData(curMessage) {
                celldata.append(data)
                self.mediaCellData = celldata
            }
        }
    }

    func loadOlderMedia() {
        if self.loadMessage?.status != .MSG_STATUS_SENDING {
            if let firstData = self.mediaCellData.first {
                self.loadMessage = firstData.innerMessage
                self.loadType = .older
                self.loadMedia()
            }
        }
    }

    func loadNewerMedia() {
        if self.loadMessage?.status != .MSG_STATUS_SENDING {
            if let lastData = self.mediaCellData.last {
                self.loadMessage = lastData.innerMessage
                self.loadType = .newer
                self.loadMedia()
            }
        }
    }

    func loadMedia() {
        guard let loadMessage = self.loadMessage else { return }
        if !self.isNeedLoad(self.loadType) { return }

        var celldata = self.mediaCellData
        self.loadMediaMessage(loadMessage, loadType: self.loadType, succeedBlock: { [weak self] olders, newers in
            guard let self = self else { return }
            for msg in olders {
                if let data = Self.getMediaCellData(msg) {
                    celldata.insert(data, at: 0)
                }
            }
            if self.loadType == .olderAndNewer {
                if let data = Self.getMediaCellData(loadMessage) {
                    celldata.append(data)
                }
            }
            for msg in newers {
                if let data = Self.getMediaCellData(msg) {
                    celldata.append(data)
                }
            }
            self.mediaCellData = celldata
        }, failBlock: { _, _ in
            print("load message failed!")
        })
    }

    func isNeedLoad(_ type: TUIMediaLoadType) -> Bool {
        if (type == .older && self.isOlderNoMoreMsg) || (type == .newer && self.isNewerNoMoreMsg) || (type == .olderAndNewer && self.isOlderNoMoreMsg && self.isNewerNoMoreMsg) {
            return false
        }
        return true
    }

    func loadMediaMessage(_ loadMsg: V2TIMMessage, loadType type: TUIMediaLoadType, succeedBlock: @escaping ([V2TIMMessage], [V2TIMMessage]) -> Void, failBlock: @escaping (Int, String) -> Void) {
        if self.isLoadingData {
            failBlock(Int(ERR_SUCC.rawValue), "loading")
            return
        }
        self.isLoadingData = true

        let group = DispatchGroup()
        var olders: [V2TIMMessage] = []
        var newers: [V2TIMMessage] = []
        var isOldLoadFail = false
        var isNewLoadFail = false
        var failCode = 0
        var failDesc: String?

        if type == .older || type == .olderAndNewer {
            group.enter()
            let option = V2TIMMessageListGetOption()
            option.getType = .GET_LOCAL_OLDER_MSG
            option.count = UInt(self.pageCount)
            option.groupID = self.conversationModel?.groupID
            option.userID = self.conversationModel?.userID
            option.lastMsg = loadMsg
            option.messageTypeList = [NSNumber(value: V2TIMElemType.ELEM_TYPE_IMAGE.rawValue), NSNumber(value: V2TIMElemType.ELEM_TYPE_VIDEO.rawValue)]
            V2TIMManager.sharedInstance().getHistoryMessageList(option, succ: { msgs in
                olders = msgs ?? []
                if olders.count < self.pageCount {
                    self.isOlderNoMoreMsg = true
                }
                group.leave()
            }, fail: { code, desc in
                isOldLoadFail = true
                failCode = Int(code)
                failDesc = desc
                group.leave()
            })
        }

        if type == .newer || type == .olderAndNewer {
            group.enter()
            let option = V2TIMMessageListGetOption()
            option.getType = .GET_LOCAL_NEWER_MSG
            option.count = UInt(self.pageCount)
            option.groupID = self.conversationModel?.groupID
            option.userID = self.conversationModel?.userID
            option.lastMsg = loadMsg
            option.messageTypeList = [NSNumber(value: V2TIMElemType.ELEM_TYPE_IMAGE.rawValue), NSNumber(value: V2TIMElemType.ELEM_TYPE_VIDEO.rawValue)]
            V2TIMManager.sharedInstance().getHistoryMessageList(option, succ: { msgs in
                newers = msgs ?? []
                if newers.count < self.pageCount {
                    self.isNewerNoMoreMsg = true
                }
                group.leave()
            }, fail: { code, desc in
                isNewLoadFail = true
                failCode = Int(code)
                failDesc = desc
                group.leave()
            })
        }

        group.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
            self.isLoadingData = false
            if isOldLoadFail || isNewLoadFail {
                DispatchQueue.main.async {
                    failBlock(failCode, failDesc ?? "")
                }
            }
            self.isFirstLoad = false

            DispatchQueue.main.async {
                succeedBlock(olders, newers)
            }
        }
    }

    func removeCache() {
        self.mediaCellData.removeAll()
        self.isNewerNoMoreMsg = false
        self.isOlderNoMoreMsg = false
        self.isFirstLoad = true
    }

    class func getMediaCellData(_ message: V2TIMMessage) -> TUIMessageCellData? {
        // subclass override required
        return nil
    }
}
