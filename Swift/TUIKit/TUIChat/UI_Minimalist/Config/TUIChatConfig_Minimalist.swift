import TIMCommon
import UIKit

enum TUIAvatarStyleMinimalist: Int {
    case rectangle
    case circle
    case roundedRectangle
}

struct TUIChatItemWhenLongPressMessageMinimalist: OptionSet {
    let rawValue: Int

    static let none = TUIChatItemWhenLongPressMessageMinimalist([])
    static let reply = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 0)
    static let emojiReaction = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 1)
    static let quote = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 2)
    static let pin = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 3)
    static let recall = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 4)
    static let translate = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 5)
    static let convert = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 6)
    static let forward = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 7)
    static let select = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 8)
    static let copy = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 9)
    static let delete = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 10)
    static let info = TUIChatItemWhenLongPressMessageMinimalist(rawValue: 1 << 11)
}

protocol TUIChatConfigDelegateMinimalist: NSObjectProtocol {
    func onUserAvatarClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onUserAvatarLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onMessageClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onMessageLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
}

enum UIMessageCellLayoutType: Int {
    case text
    case image
    case video
    case voice
    case other
    case system
}

class TUIChatConfigMinimalist: NSObject {
    static let sharedConfig: TUIChatConfigMinimalist = {
        let instance = TUIChatConfigMinimalist()
        TUIChatConfig.shared.eventConfig.chatEventListener = instance as? any TUIChatEventListener
        return instance
    }()

    weak var delegate: TUIChatConfigDelegateMinimalist?

    var backgroudColor: UIColor? {
        get {
            return TUIChatConfig.shared.backgroudColor
        }
        set {
            TUIChatConfig.shared.backgroudColor = newValue ?? .black
        }
    }

    var backgroudImage: UIImage? {
        get {
            return TUIChatConfig.shared.backgroudImage
        }
        set {
            TUIChatConfig.shared.backgroudImage = newValue ?? UIImage()
        }
    }

    var avatarStyle: TUIAvatarStyleMinimalist {
        get {
            return TUIAvatarStyleMinimalist(rawValue: TUIConfig.default().avatarType.rawValue)!
        }
        set {
            TUIConfig.default().avatarType = TUIKitAvatarType(rawValue: newValue.rawValue)!
        }
    }

    var avatarCornerRadius: CGFloat {
        get {
            return TUIConfig.default().avatarCornerRadius
        }
        set {
            TUIConfig.default().avatarCornerRadius = newValue
        }
    }

    var enableGroupGridAvatar: Bool {
        get {
            return TUIConfig.default().enableGroupGridAvatar
        }
        set {
            TUIConfig.default().enableGroupGridAvatar = newValue
        }
    }

    var defaultAvatarImage: UIImage? {
        get {
            return TUIConfig.default().defaultAvatarImage
        }
        set {
            TUIConfig.default().defaultAvatarImage = newValue
        }
    }

    var enableTypingIndicator: Bool {
        get {
            return TUIChatConfig.shared.enableTypingStatus
        }
        set {
            TUIChatConfig.shared.enableTypingStatus = newValue
        }
    }

    var isMessageReadReceiptNeeded: Bool {
        get {
            return TUIChatConfig.shared.msgNeedReadReceipt
        }
        set {
            TUIChatConfig.shared.msgNeedReadReceipt = newValue
        }
    }

    var hideVideoCallButton: Bool {
        get {
            return !TUIChatConfig.shared.enableVideoCall
        }
        set {
            TUIChatConfig.shared.enableVideoCall = !newValue
        }
    }

    var hideAudioCallButton: Bool {
        get {
            return !TUIChatConfig.shared.enableAudioCall
        }
        set {
            TUIChatConfig.shared.enableAudioCall = !newValue
        }
    }

    var enableFloatWindowForCall: Bool {
        get {
            return TUIChatConfig.shared.enableFloatWindowForCall
        }
        set {
            TUIChatConfig.shared.enableFloatWindowForCall = newValue
        }
    }

    var enableMultiDeviceForCall: Bool {
        get {
            return TUIChatConfig.shared.enableMultiDeviceForCall
        }
        set {
            TUIChatConfig.shared.enableMultiDeviceForCall = newValue
        }
    }

    var isExcludedFromUnreadCount: Bool {
        get {
            return TUIConfig.default().isExcludedFromUnreadCount
        }
        set {
            TUIConfig.default().isExcludedFromUnreadCount = newValue
        }
    }

    var isExcludedFromLastMessage: Bool {
        get {
            return TUIConfig.default().isExcludedFromLastMessage
        }
        set {
            TUIConfig.default().isExcludedFromLastMessage = newValue
        }
    }

    var timeIntervalForAllowedMessageRecall: UInt {
        get {
            return TUIChatConfig.shared.timeIntervalForMessageRecall
        }
        set {
            TUIChatConfig.shared.timeIntervalForMessageRecall = newValue
        }
    }

    var maxAudioRecordDuration: CGFloat {
        get {
            return TUIChatConfig.shared.maxAudioRecordDuration
        }
        set {
            TUIChatConfig.shared.maxAudioRecordDuration = newValue
        }
    }

    var maxVideoRecordDuration: CGFloat {
        get {
            return TUIChatConfig.shared.maxVideoRecordDuration
        }
        set {
            TUIChatConfig.shared.maxVideoRecordDuration = newValue
        }
    }

    var enableAndroidCustomRing: Bool {
        get {
            return TUIConfig.default().enableCustomRing
        }
        set {
            TUIConfig.default().enableCustomRing = newValue
        }
    }

    var sendTextMessageColor: UIColor? {
        get {
            return TUITextMessageCell_Minimalist.outgoingTextColor
        }
        set {
            TUITextMessageCell_Minimalist.outgoingTextColor = newValue
        }
    }

    var sendTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell_Minimalist.outgoingTextFont ?? UIFont()
        }
        set {
            TUITextMessageCell_Minimalist.outgoingTextFont = newValue
        }
    }

    var receiveTextMessageColor: UIColor? {
        get {
            return TUITextMessageCell_Minimalist.incommingTextColor ?? UIColor()
        }
        set {
            TUITextMessageCell_Minimalist.incommingTextColor = newValue
        }
    }

    var receiveTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell_Minimalist.incommingTextFont ?? UIFont()
        }
        set {
            TUITextMessageCell_Minimalist.incommingTextFont = newValue
        }
    }

    var systemMessageTextColor: UIColor {
        get {
            return TUISystemMessageCellData.textColor
        }
        set {
            TUISystemMessageCellData.textColor = newValue
        }
    }

    var systemMessageTextFont: UIFont {
        get {
            return TUISystemMessageCellData.textFont
        }
        set {
            TUISystemMessageCellData.textFont = newValue
        }
    }

    var systemMessageBackgroundColor: UIColor {
        get {
            return TUISystemMessageCellData.textBackgroundColor
        }
        set {
            TUISystemMessageCellData.textBackgroundColor = newValue
        }
    }

    var sendTextMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: true)
    }

    var receiveTextMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: false)
    }

    var sendImageMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: true)
    }

    var receiveImageMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: false)
    }

    var sendVoiceMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: true)
    }

    var receiveVoiceMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: false)
    }

    var sendVideoMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: true)
    }

    var receiveVideoMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: false)
    }

    var sendMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: true)
    }

    var receiveMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: false)
    }

    var systemMessageLayout: TUIMessageCellLayout {
        return getMessageLayout(ofType: .system, isSender: false)
    }

    var enableMessageBubbleStyle: Bool {
        get {
            return TIMConfig.default().enableMessageBubble
        }
        set {
            TIMConfig.default().enableMessageBubble = newValue
        }
    }

    var sendLastBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.outgoingBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.outgoingBubble = newValue ?? UIImage()
        }
    }

    var sendBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.outgoingSameBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.outgoingSameBubble = newValue ?? UIImage()
        }
    }

    var sendHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.outgoingHighlightedBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.outgoingHighlightedBubble = newValue ?? UIImage()
        }
    }

    var sendAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.outgoingAnimatedHighlightedAlpha20
        }
        set {
            TUIBubbleMessageCell_Minimalist.outgoingAnimatedHighlightedAlpha20 = newValue ?? UIImage()
        }
    }

    var sendAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.outgoingAnimatedHighlightedAlpha50
        }
        set {
            TUIBubbleMessageCell_Minimalist.outgoingAnimatedHighlightedAlpha50 = newValue ?? UIImage()
        }
    }

    var receiveLastBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.incommingBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.incommingBubble = newValue ?? UIImage()
        }
    }

    var receiveBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.incommingSameBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.incommingSameBubble = newValue ?? UIImage()
        }
    }

    var receiveHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.incommingHighlightedBubble
        }
        set {
            TUIBubbleMessageCell_Minimalist.incommingHighlightedBubble = newValue ?? UIImage()
        }
    }

    var receiveAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.incommingAnimatedHighlightedAlpha20
        }
        set {
            TUIBubbleMessageCell_Minimalist.incommingAnimatedHighlightedAlpha20 = newValue ?? UIImage()
        }
    }

    var receiveAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell_Minimalist.incommingAnimatedHighlightedAlpha50
        }
        set {
            TUIBubbleMessageCell_Minimalist.incommingAnimatedHighlightedAlpha50 = newValue ?? UIImage()
        }
    }

    var inputBarDataSource: TUIChatInputBarConfigDataSource? {
        get {
            return TUIChatConfig.shared.inputBarDataSource
        }
        set {
            TUIChatConfig.shared.inputBarDataSource = newValue
        }
    }

    var showInputBar: Bool {
        get {
            return !TUIChatConfig.shared.enableMainPageInputBar
        }
        set {
            TUIChatConfig.shared.enableMainPageInputBar = !newValue
        }
    }

    private func getMessageLayout(ofType type: UIMessageCellLayoutType, isSender: Bool) -> TUIMessageCellLayout {
        switch type {
        case .text:
            return isSender ? TUIMessageCellLayout.outgoingTextMessage() : TUIMessageCellLayout.incommingTextMessage()
        case .image:
            return isSender ? TUIMessageCellLayout.outgoingImageMessage() : TUIMessageCellLayout.incommingImageMessage()
        case .video:
            return isSender ? TUIMessageCellLayout.outgoingVideoMessage() : TUIMessageCellLayout.incommingVideoMessage()
        case .voice:
            return isSender ? TUIMessageCellLayout.outgoingVoiceMessage() : TUIMessageCellLayout.incommingVoiceMessage()
        case .other:
            return isSender ? TUIMessageCellLayout.outgoingMessage() : TUIMessageCellLayout.incommingMessage()
        case .system:
            return TUIMessageCellLayout.systemMessage()
        }
    }

    class func hideItemsWhenLongPressMessage(_ items: TUIChatItemWhenLongPressMessageMinimalist) {
        let value = items.rawValue
        TUIChatConfig.shared.enablePopMenuReplyAction = (value & TUIChatItemWhenLongPressMessageMinimalist.reply.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuEmojiReactAction = (value & TUIChatItemWhenLongPressMessageMinimalist.emojiReaction.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuReferenceAction = (value & TUIChatItemWhenLongPressMessageMinimalist.quote.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuPinAction = (value & TUIChatItemWhenLongPressMessageMinimalist.pin.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuRecallAction = (value & TUIChatItemWhenLongPressMessageMinimalist.recall.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuTranslateAction = (value & TUIChatItemWhenLongPressMessageMinimalist.translate.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuConvertAction = (value & TUIChatItemWhenLongPressMessageMinimalist.convert.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuForwardAction = (value & TUIChatItemWhenLongPressMessageMinimalist.forward.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuSelectAction = (value & TUIChatItemWhenLongPressMessageMinimalist.select.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuCopyAction = (value & TUIChatItemWhenLongPressMessageMinimalist.copy.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuDeleteAction = (value & TUIChatItemWhenLongPressMessageMinimalist.delete.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuInfoAction = (value & TUIChatItemWhenLongPressMessageMinimalist.info.rawValue) == 0
    }

    class func setPlayingSoundMessageViaSpeakerByDefault() {
        if TUIVoiceMessageCellData.getAudioplaybackStyle() == .handset {
            TUIVoiceMessageCellData.changeAudioPlaybackStyle()
        }
    }

    class func setCustomTopView(_ view: UIView) {
        TUIBaseChatViewController_Minimalist.customTopView = view
    }

    class func hideItemsInMoreMenu(_ items: TUIChatInputBarMoreMenuItem) {
        let value = items.rawValue
        TUIChatConfig.shared.enableWelcomeCustomMessage = (value & TUIChatInputBarMoreMenuItem.customMessage.rawValue) == 0
        TUIChatConfig.shared.showRecordVideoButton = (value & TUIChatInputBarMoreMenuItem.recordVideo.rawValue) == 0
        TUIChatConfig.shared.showTakePhotoButton = (value & TUIChatInputBarMoreMenuItem.takePhoto.rawValue) == 0
        TUIChatConfig.shared.showAlbumButton = (value & TUIChatInputBarMoreMenuItem.album.rawValue) == 0
        TUIChatConfig.shared.showFileButton = (value & TUIChatInputBarMoreMenuItem.file.rawValue) == 0
    }

    func registerCustomMessage(businessID: String,
                               messageCellClassName: String,
                               messageCellDataClassName: String)
    {
        TUIChatConfig.shared.registerCustomMessage(businessID: businessID,
                                                   messageCellClassName: messageCellClassName,
                                                   messageCellDataClassName: messageCellDataClassName,
                                                   styleType: .minimalist)
    }

    func addStickerGroup(_ group: TUIFaceGroup) {
        if let service = TIMCommonMediator.share().getObject(TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol {
            service.append(group)
        } else {
            print("Failed to get TUIEmojiMeditorProtocol service")
        }
    }
}
