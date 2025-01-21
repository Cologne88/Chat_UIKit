import Foundation

let kMemberCellReuseId = "kMemberCellReuseId"
let TUITencentCloudHomePageCN = "https://cloud.tencent.com/document/product/269/68228"
let TUITencentCloudHomePageEN = "https://www.tencentcloud.com/document/product/1047/45913"
let TUIChatSendMessageNotification = "TUIChatSendMessageNotification"
let TUIChatSendMessageWithoutUpdateUINotification = "TUIChatSendMessageWithoutUpdateUINotification"

typealias TUIImageMessageDownloadCallback = () -> Void
typealias TUIVideoMessageDownloadCallback = () -> Void
typealias TUIReplyAsyncLoadFinish = () -> Void
typealias TUIInputPreviewBarCallback = () -> Void
typealias TUIReplyQuoteAsyncLoadFinish = () -> Void
typealias TUIChatSelectAllContentCallback = (Bool) -> Void
typealias TUIReferenceSelectAllContentCallback = (Bool) -> Void
typealias TUIReplySelectAllContentCallback = (Bool) -> Void

enum TUIMultiResultOption: Int {
    case all = 0
    case filterUnsupportRelay = 1
}

enum TUIMessageReadViewTag: Int {
    case unknown = 0
    case read
    case unread
    case readDisable
    case c2c
}

enum InputStatus: UInt {
    case input
    case inputFace
    case inputMore
    case inputKeyboard
    case inputTalk
    case inputCamera
}

enum RecordStatus: UInt {
    case tooShort
    case tooLong
    case recording
    case cancel
}

enum TUIChatSmallTongueType: Int {
    case none
    case scrollToBoom
    case receiveNewMsg
    case someoneAt
}
