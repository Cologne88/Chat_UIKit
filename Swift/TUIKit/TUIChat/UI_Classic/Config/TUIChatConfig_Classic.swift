import Foundation
import TIMCommon
import UIKit

enum TUIAvatarStyleClassic: Int {
    case rectangle
    case circle
    case roundedRectangle
}

struct TUIChatItemWhenLongPressMessageClassic: OptionSet {
    let rawValue: Int

    static let none = TUIChatItemWhenLongPressMessageClassic([])
    static let reply = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 0)
    static let emojiReaction = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 1)
    static let quote = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 2)
    static let pin = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 3)
    static let recall = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 4)
    static let translate = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 5)
    static let convert = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 6)
    static let forward = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 7)
    static let select = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 8)
    static let copy = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 9)
    static let delete = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 10)
    static let info = TUIChatItemWhenLongPressMessageClassic(rawValue: 1 << 11)
}

protocol TUIChatConfigDelegateClassic: NSObjectProtocol {
    func onUserAvatarClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onUserAvatarLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onMessageClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    func onMessageLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
}

class TUIChatConfigClassic: NSObject {
    static let shared = TUIChatConfigClassic()

    weak var delegate: TUIChatConfigDelegateClassic?

    var backgroundColor: UIColor? {
        get {
            return TUIChatConfig.shared.backgroudColor
        }
        set {
            TUIChatConfig.shared.backgroudColor = newValue ?? .black
        }
    }

    var backgroundImage: UIImage? {
        get {
            return TUIChatConfig.shared.backgroudImage
        }
        set {
            TUIChatConfig.shared.backgroudImage = newValue ?? UIImage()
        }
    }

    var avatarStyle: TUIAvatarStyleClassic {
        get {
            return TUIAvatarStyleClassic(rawValue: TUIConfig.default().avatarType.rawValue)!
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

    var maxAudioRecordDuration: TimeInterval {
        get {
            return TUIChatConfig.shared.maxAudioRecordDuration
        }
        set {
            TUIChatConfig.shared.maxAudioRecordDuration = newValue
        }
    }

    var maxVideoRecordDuration: TimeInterval {
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

    static func hideItemsWhenLongPressMessage(_ items: TUIChatItemWhenLongPressMessageClassic) {
        let value = items.rawValue
        TUIChatConfig.shared.enablePopMenuReplyAction = (value & TUIChatItemWhenLongPressMessageClassic.reply.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuEmojiReactAction = (value & TUIChatItemWhenLongPressMessageClassic.emojiReaction.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuReferenceAction = (value & TUIChatItemWhenLongPressMessageClassic.quote.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuPinAction = (value & TUIChatItemWhenLongPressMessageClassic.pin.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuRecallAction = (value & TUIChatItemWhenLongPressMessageClassic.recall.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuTranslateAction = (value & TUIChatItemWhenLongPressMessageClassic.translate.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuConvertAction = (value & TUIChatItemWhenLongPressMessageClassic.convert.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuForwardAction = (value & TUIChatItemWhenLongPressMessageClassic.forward.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuSelectAction = (value & TUIChatItemWhenLongPressMessageClassic.select.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuCopyAction = (value & TUIChatItemWhenLongPressMessageClassic.copy.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuDeleteAction = (value & TUIChatItemWhenLongPressMessageClassic.delete.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuInfoAction = (value & TUIChatItemWhenLongPressMessageClassic.info.rawValue) == 0
    }

    static func setPlayingSoundMessageViaSpeakerByDefault() {
        if TUIVoiceMessageCellData.getAudioplaybackStyle() == .handset {
            TUIVoiceMessageCellData.changeAudioPlaybackStyle()
        }
    }

    static func setCustomTopView(_ view: UIView) {
        TUIBaseChatViewController.customTopView = view
    }

    func registerCustomMessage(businessID: String, messageCellClassName: String, messageCellDataClassName: String) {
        TUIChatConfig.shared.registerCustomMessage(businessID: businessID, messageCellClassName: messageCellClassName, messageCellDataClassName: messageCellDataClassName, styleType: .classic)
    }

    // MARK: - Message style

    enum UIMessageCellLayoutType: Int {
        case text
        case image
        case video
        case voice
        case other
        case system
    }

    var sendTextMessageColor: UIColor? {
        get {
            return TUITextMessageCell.outgoingTextColor
        }
        set {
            TUITextMessageCell.outgoingTextColor = newValue
        }
    }

    var sendTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell.outgoingTextFont
        }
        set {
            TUITextMessageCell.outgoingTextFont = newValue
        }
    }

    var receiveTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell.incommingTextFont
        }
        set {
            TUITextMessageCell.incommingTextFont = newValue
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

    var receiveNicknameFont: UIFont {
        get {
            return TUIMessageCell.incommingNameFont
        }
        set {
            TUIMessageCell.incommingNameFont = newValue
        }
    }

    var receiveNicknameColor: UIColor {
        get {
            return TUIMessageCell.incommingNameColor
        }
        set {
            TUIMessageCell.incommingNameColor = newValue
        }
    }

    // MARK: MessageLayout

    func sendTextMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: true)
    }

    func receiveTextMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: false)
    }

    func sendImageMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: true)
    }

    func receiveImageMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: false)
    }

    func sendVoiceMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: true)
    }

    func receiveVoiceMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: false)
    }

    func sendVideoMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: true)
    }

    func receiveVideoMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: false)
    }

    func sendMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: true)
    }

    func receiveMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: false)
    }

    func systemMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .system, isSender: false)
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

    // MARK: - MessageBubble

    var enableMessageBubbleStyle: Bool {
        get {
            return TIMConfig.default().enableMessageBubble
        }
        set {
            TIMConfig.default().enableMessageBubble = newValue
        }
    }

    var sendBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingBubble = image
            }
        }
    }

    var sendHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingHighlightedBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingHighlightedBubble = image
            }
        }
    }

    var sendAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha20
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha20 = image
            }
        }
    }

    var sendAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha50
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha50 = image
            }
        }
    }

    var sendErrorBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingErrorBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingErrorBubble = image
            }
        }
    }

    var receiveBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingBubble = image
            }
        }
    }

    var receiveHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingHighlightedBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingHighlightedBubble = image
            }
        }
    }

    var receiveAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha20
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha20 = image
            }
        }
    }

    var receiveAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha50
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha50 = image
            }
        }
    }

    var receiveErrorBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingErrorBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingErrorBubble = image
            }
        }
    }

    // MARK: - InputBar

    var inputBarDataSource: TUIChatInputBarConfigDataSource? {
        get {
            return TUIChatConfig.shared.inputBarDataSource
        }
        set {
            TUIChatConfig.shared.inputBarDataSource = newValue
        }
    }

    var shortcutViewDataSource: TUIChatShortcutViewDataSource? {
        get {
            return TUIChatConfig.shared.shortcutViewDataSource
        }
        set {
            TUIChatConfig.shared.shortcutViewDataSource = newValue
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

    static func hideItemsInMoreMenu(_ items: TUIChatInputBarMoreMenuItem) {
        let value = items.rawValue
        TUIChatConfig.shared.enableWelcomeCustomMessage = (value & TUIChatInputBarMoreMenuItem.customMessage.rawValue) == 0
        TUIChatConfig.shared.showRecordVideoButton = (value & TUIChatInputBarMoreMenuItem.recordVideo.rawValue) == 0
        TUIChatConfig.shared.showTakePhotoButton = (value & TUIChatInputBarMoreMenuItem.takePhoto.rawValue) == 0
        TUIChatConfig.shared.showAlbumButton = (value & TUIChatInputBarMoreMenuItem.album.rawValue) == 0
        TUIChatConfig.shared.showFileButton = (value & TUIChatInputBarMoreMenuItem.file.rawValue) == 0
    }

    func addStickerGroup(_ group: TUIFaceGroup) {
        if let service = TIMCommonMediator.share().getObject(TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol {
            service.append(group)
        } else {
            print("Failed to get TUIEmojiMeditorProtocol service")
        }
    }

    // MARK: - TUIChatEventListener

    func onUserIconClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool {
        return delegate?.onUserAvatarClicked(view: view, messageCellData: messageCellData) ?? false
    }

    func onUserIconLongClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool {
        return delegate?.onUserAvatarLongPressed(view: view, messageCellData: messageCellData) ?? false
    }

    func onMessageClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool {
        return delegate?.onMessageClicked(view: view, messageCellData: messageCellData) ?? false
    }

    func onMessageLongClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool {
        return delegate?.onMessageLongPressed(view: view, messageCellData: messageCellData) ?? false
    }
}
