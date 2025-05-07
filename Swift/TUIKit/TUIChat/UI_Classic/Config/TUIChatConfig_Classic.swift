import Foundation
import TIMCommon
import UIKit

public enum TUIAvatarStyle_Classic: Int {
    case rectangle
    case circle
    case roundedRectangle
}

public struct TUIChatItemWhenLongPressMessage_Classic: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = TUIChatItemWhenLongPressMessage_Classic([])
    public static let reply = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 0)
    public static let emojiReaction = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 1)
    public static let quote = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 2)
    public static let pin = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 3)
    public static let recall = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 4)
    public static let translate = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 5)
    public static let convert = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 6)
    public static let forward = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 7)
    public static let select = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 8)
    public static let copy = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 9)
    public static let delete = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 10)
    public static let info = TUIChatItemWhenLongPressMessage_Classic(rawValue: 1 << 11)
}

public protocol TUIChatConfigDelegate_Classic: NSObjectProtocol {
    /**
     * Tells the delegate a user's avatar in the chat list is clicked.
     * Returning YES indicates this event has been intercepted, and Chat will not process it further.
     * Returning NO indicates this event is not intercepted, and Chat will continue to process it.
     */
    func onUserAvatarClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    /**
     * Tells the delegate a user's avatar in the chat list is long pressed.
     * Returning YES indicates that this event has been intercepted, and Chat will not process it further.
     * Returning NO indicates that this event is not intercepted, and Chat will continue to process it.
     */
    func onUserAvatarLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    /**
     * Tells the delegate a message in the chat list is clicked.
     * Returning YES indicates that this event has been intercepted, and Chat will not process it further.
     * Returning NO indicates that this event is not intercepted, and Chat will continue to process it.
     */
    func onMessageClicked(view: UIView, messageCellData: TUIMessageCellData) -> Bool
    /**
     * Tells the delegate a message in the chat list is long pressed.
     * Returning YES indicates that this event has been intercepted, and Chat will not process it further.
     * Returning NO indicates that this event is not intercepted, and Chat will continue to process it.
     */
    func onMessageLongPressed(view: UIView, messageCellData: TUIMessageCellData) -> Bool
}

public class TUIChatConfig_Classic: NSObject {
    public static let shared = TUIChatConfig_Classic()

    /**
     * The object that acts as the delegate of the TUIChatMessageConfig_Minimalist.
     */
    public weak var delegate: TUIChatConfigDelegate_Classic?

    /**
     * Customize the backgroud color of message list interface.
     * This configuration takes effect in all message list interfaces.
     */
    public var backgroundColor: UIColor? {
        get {
            return TUIChatConfig.shared.backgroudColor
        }
        set {
            TUIChatConfig.shared.backgroudColor = newValue ?? UIColor()
        }
    }

    /**
     * Customize the backgroud image of message list interface.
     * This configuration takes effect in all message list interfaces.
     */
    public var backgroundImage: UIImage? {
        get {
            return TUIChatConfig.shared.backgroudImage
        }
        set {
            TUIChatConfig.shared.backgroudImage = newValue ?? UIImage()
        }
    }

    /**
     *  Customize the style of avatar.
     *  The default value is TUIAvatarStyleCircle.
     *  This configuration takes effect in all avatars.
     */
    public var avatarStyle: TUIAvatarStyle_Classic {
        get {
            return TUIAvatarStyle_Classic(rawValue: TUIConfig.default().avatarType.rawValue)!
        }
        set {
            TUIConfig.default().avatarType = TUIKitAvatarType(rawValue: newValue.rawValue)!
        }
    }

    /**
     *  Customize the corner radius of the avatar.
     *  This configuration takes effect in all avatars.
     */
    public var avatarCornerRadius: CGFloat {
        get {
            return TUIConfig.default().avatarCornerRadius
        }
        set {
            TUIConfig.default().avatarCornerRadius = newValue
        }
    }

    /**
     * Display the group avatar in the nine-square grid style.
     * The default value is YES.
     * This configuration takes effect in all groups.
     */
    public var enableGroupGridAvatar: Bool {
        get {
            return TUIConfig.default().enableGroupGridAvatar
        }
        set {
            TUIConfig.default().enableGroupGridAvatar = newValue
        }
    }

    /**
     *  Default avatar image.
     *  This configuration takes effect in all avatars.
     */
    public var defaultAvatarImage: UIImage? {
        get {
            return TUIConfig.default().defaultAvatarImage
        }
        set {
            TUIConfig.default().defaultAvatarImage = newValue
        }
    }

    /**
     *  Enable the display "Alice is typing..." on one-to-one chat interface.
     *  The default value is YES.
     *  This configuration takes effect in all one-to-one chat message list interfaces.
     */
    public var enableTypingIndicator: Bool {
        get {
            return TUIChatConfig.shared.enableTypingStatus
        }
        set {
            TUIChatConfig.shared.enableTypingStatus = newValue
        }
    }

    /**
     *  When sending a message, set this flag to require message read receipt.
     *  The default value is NO.
     *  This configuration takes effect in all chat message list interfaces.
     */
    public var isMessageReadReceiptNeeded: Bool {
        get {
            return TUIChatConfig.shared.msgNeedReadReceipt
        }
        set {
            TUIChatConfig.shared.msgNeedReadReceipt = newValue
        }
    }

    /**
     *  Hide the "Video Call" button in the message list header.
     *  The default value is NO.
     */
    public var hideVideoCallButton: Bool {
        get {
            return !TUIChatConfig.shared.enableVideoCall
        }
        set {
            TUIChatConfig.shared.enableVideoCall = !newValue
        }
    }

    /**
     *  Hide the "Audio Call" button in the message list header.
     *  The default value is NO.
     */
    public var hideAudioCallButton: Bool {
        get {
            return !TUIChatConfig.shared.enableAudioCall
        }
        set {
            TUIChatConfig.shared.enableAudioCall = !newValue
        }
    }

    /**
     * Turn on audio and video call floating windows,
     * The default value is YES.
     */
    public var enableFloatWindowForCall: Bool {
        get {
            return TUIChatConfig.shared.enableFloatWindowForCall
        }
        set {
            TUIChatConfig.shared.enableFloatWindowForCall = newValue
        }
    }

    /**
     * Enable multi-terminal login function for audio and video calls
     * The default value is NO.
     */
    public var enableMultiDeviceForCall: Bool {
        get {
            return TUIChatConfig.shared.enableMultiDeviceForCall
        }
        set {
            TUIChatConfig.shared.enableMultiDeviceForCall = newValue
        }
    }

    /**
     * Set this parameter when the sender sends a message, and the receiver will not update the unread count after receiving the message.
     * The default value is NO.
     */
    public var isExcludedFromUnreadCount: Bool {
        get {
            return TUIConfig.default().isExcludedFromUnreadCount
        }
        set {
            TUIConfig.default().isExcludedFromUnreadCount = newValue
        }
    }

    /**
     * Set this parameter when the sender sends a message, and the receiver will not update the last message of the conversation after receiving the message.
     * The default value is NO.
     */
    public var isExcludedFromLastMessage: Bool {
        get {
            return TUIConfig.default().isExcludedFromLastMessage
        }
        set {
            TUIConfig.default().isExcludedFromLastMessage = newValue
        }
    }

    /**
     * Time interval within which a message can be recalled after being sent.
     * The default value is 120 seconds.
     * If you want to adjust this configuration, please modify the setting on Chat Console synchronously: https://trtc.io/document/34419?platform=web&product=chat&menulabel=uikit#message-recall-settings
     */
    public var timeIntervalForAllowedMessageRecall: UInt {
        get {
            return TUIChatConfig.shared.timeIntervalForMessageRecall
        }
        set {
            TUIChatConfig.shared.timeIntervalForMessageRecall = newValue
        }
    }

    /**
     * Maximum audio recording duration, no more than 60s.
     * The default value is 60 seconds.
     */
    public var maxAudioRecordDuration: TimeInterval {
        get {
            return TUIChatConfig.shared.maxAudioRecordDuration
        }
        set {
            TUIChatConfig.shared.maxAudioRecordDuration = newValue
        }
    }

    /**
     * Maximum video recording duration, no more than 15s.
     * The default value is 15 seconds.
     */
    public var maxVideoRecordDuration: TimeInterval {
        get {
            return TUIChatConfig.shared.maxVideoRecordDuration
        }
        set {
            TUIChatConfig.shared.maxVideoRecordDuration = newValue
        }
    }

    /**
     * Enable custom ringtone.
     * This config takes effect only for Android devices.
     */
    public var enableAndroidCustomRing: Bool {
        get {
            return TUIConfig.default().enableCustomRing
        }
        set {
            TUIConfig.default().enableCustomRing = newValue
        }
    }

    /**
     * Hide the items in the pop-up menu when user presses the message.
     */
    public static func hideItemsWhenLongPressMessage(_ items: TUIChatItemWhenLongPressMessage_Classic) {
        let value = items.rawValue
        TUIChatConfig.shared.enablePopMenuReplyAction = (value & TUIChatItemWhenLongPressMessage_Classic.reply.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuEmojiReactAction = (value & TUIChatItemWhenLongPressMessage_Classic.emojiReaction.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuReferenceAction = (value & TUIChatItemWhenLongPressMessage_Classic.quote.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuPinAction = (value & TUIChatItemWhenLongPressMessage_Classic.pin.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuRecallAction = (value & TUIChatItemWhenLongPressMessage_Classic.recall.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuTranslateAction = (value & TUIChatItemWhenLongPressMessage_Classic.translate.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuConvertAction = (value & TUIChatItemWhenLongPressMessage_Classic.convert.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuForwardAction = (value & TUIChatItemWhenLongPressMessage_Classic.forward.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuSelectAction = (value & TUIChatItemWhenLongPressMessage_Classic.select.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuCopyAction = (value & TUIChatItemWhenLongPressMessage_Classic.copy.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuDeleteAction = (value & TUIChatItemWhenLongPressMessage_Classic.delete.rawValue) == 0
        TUIChatConfig.shared.enablePopMenuInfoAction = (value & TUIChatItemWhenLongPressMessage_Classic.info.rawValue) == 0
    }

    /**
     * Call this method to use speakers instead of handsets by default when playing voice messages.
     */
    public static func setPlayingSoundMessageViaSpeakerByDefault() {
        if TUIVoiceMessageCellData.getAudioplaybackStyle() == .handset {
            TUIVoiceMessageCellData.changeAudioPlaybackStyle()
        }
    }

    /**
     * Add a custom view at the top of the chat interface.
     * This view will be displayed at the top of the message list and will not slide up.
     */
    public static func setCustomTopView(_ view: UIView) {
        TUIBaseChatViewController.customTopView = view
    }

    /**
     * Register custom message.
     * - Parameters:
     *   - businessID: Customized message‘s businessID, which is unique.
     *   - messageCellClassName: Customized message's MessagCell class name.
     *   - messageCellDataClassName: Customized message's MessagCellData class name.
     */
    public func registerCustomMessage(businessID: String, messageCellClassName: String, messageCellDataClassName: String) {
        TUIChatConfig.shared.registerCustomMessage(businessID: businessID, messageCellClassName: messageCellClassName, messageCellDataClassName: messageCellDataClassName, styleType: .classic)
    }

    // MARK: - Message Style

    public enum UIMessageCellLayoutType: Int {
        case text
        case image
        case video
        case voice
        case other
        case system
    }

    /**
     * The color of send text message.
     */
    public var sendTextMessageColor: UIColor? {
        get {
            return TUITextMessageCell.outgoingTextColor
        }
        set {
            TUITextMessageCell.outgoingTextColor = newValue
        }
    }

    /**
     * The font of send text message.
     */
    public var sendTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell.outgoingTextFont
        }
        set {
            TUITextMessageCell.outgoingTextFont = newValue
        }
    }
    
    /**
     * The color of receive text message.
     */
    public var receiveTextMessageColor: UIColor? {
        get {
            return TUITextMessageCell.incommingTextColor
        }
        set {
            TUITextMessageCell.incommingTextColor = newValue
        }
    }

    /**
     * The font of receive text message.
     */
    public var receiveTextMessageFont: UIFont? {
        get {
            return TUITextMessageCell.incommingTextFont
        }
        set {
            TUITextMessageCell.incommingTextFont = newValue
        }
    }

    /**
     * The text color of system message.
     */
    public var systemMessageTextColor: UIColor? {
        get {
            return TUISystemMessageCellData.textColor
        }
        set {
            TUISystemMessageCellData.textColor = newValue
        }
    }

    /**
     * The font of system message.
     */
    public var systemMessageTextFont: UIFont? {
        get {
            return TUISystemMessageCellData.textFont
        }
        set {
            TUISystemMessageCellData.textFont = newValue
        }
    }

    /**
     * The background color of system message.
     */
    public var systemMessageBackgroundColor: UIColor? {
        get {
            return TUISystemMessageCellData.textBackgroundColor
        }
        set {
            TUISystemMessageCellData.textBackgroundColor = newValue
        }
    }

    /**
     * The font of user's nickname of received messages.
     */
    public var receiveNicknameFont: UIFont? {
        get {
            return TUIMessageCell.incommingNameFont
        }
        set {
            TUIMessageCell.incommingNameFont = newValue
        }
    }

    /**
     * The color of user's nickname of received messages.
     */
    public var receiveNicknameColor: UIColor? {
        get {
            return TUIMessageCell.incommingNameColor
        }
        set {
            TUIMessageCell.incommingNameColor = newValue
        }
    }

    // MARK: - Message Layout

    /**
     * Text message cell layout of my sent message.
     */
    public func sendTextMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: true)
    }

    /**
     * Text message cell layout of my received message.
     */
    public func receiveTextMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .text, isSender: false)
    }

    /**
     * Image message cell layout of my sent message.
     */
    public func sendImageMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: true)
    }

    /**
     * Image message cell layout of my received message.
     */
    public func receiveImageMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .image, isSender: false)
    }

    /**
     * Voice message cell layout of my sent message.
     */
    public func sendVoiceMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: true)
    }

    /**
     * Voice message cell layout of my received message.
     */
    public func receiveVoiceMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .voice, isSender: false)
    }

    /**
     * Video message cell layout of my sent message.
     */
    public func sendVideoMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: true)
    }

    /**
     * Video message cell layout of my received message.
     */
    public func receiveVideoMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .video, isSender: false)
    }

    /**
     * Other message cell layout of my sent message.
     */
    public func sendMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: true)
    }

    /**
     * Other message cell layout of my received message.
     */
    public func receiveMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .other, isSender: false)
    }

    /**
     * System message cell layout.
     */
    public func systemMessageLayout() -> TUIMessageCellLayout {
        return getMessageLayout(ofType: .system, isSender: false)
    }

    private func getMessageLayout(ofType type: UIMessageCellLayoutType, isSender: Bool) -> TUIMessageCellLayout {
        switch type {
        case .text:
            return isSender ? TUIMessageCellLayout.outgoingTextMessageLayout : TUIMessageCellLayout.incomingTextMessageLayout
        case .image:
            return isSender ? TUIMessageCellLayout.outgoingImageMessageLayout : TUIMessageCellLayout.incomingImageMessageLayout
        case .video:
            return isSender ? TUIMessageCellLayout.outgoingVideoMessageLayout : TUIMessageCellLayout.incomingVideoMessageLayout
        case .voice:
            return isSender ? TUIMessageCellLayout.outgoingVoiceMessageLayout : TUIMessageCellLayout.incomingVoiceMessageLayout
        case .other:
            return isSender ? TUIMessageCellLayout.outgoingMessageLayout : TUIMessageCellLayout.incomingMessageLayout
        case .system:
            return TUIMessageCellLayout.systemMessageLayout
        }
    }

    // MARK: - Message Bubble

    /**
     * Enable the message display in the bubble style.
     * The default value is YES.
     */
    public var enableMessageBubbleStyle: Bool {
        get {
            return TIMConfig.shared.enableMessageBubble
        }
        set {
            TIMConfig.shared.enableMessageBubble = newValue
        }
    }

    /**
     * Set the background image of the sent message bubble in consecutive message.
     */
    public var sendBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingBubble = image
            }
        }
    }

    /**
     * Set the background image of the sent message bubble in highlight status.
     */
    public var sendHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingHighlightedBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingHighlightedBubble = image
            }
        }
    }

    /**
     * Set the light background image when the sent message bubble needs to flicker.
     */
    public var sendAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha20
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha20 = image
            }
        }
    }

    /**
     * Set the dark background image when the sent message bubble needs to flicker.
     */
    public var sendAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha50
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.outgoingAnimatedHighlightedAlpha50 = image
            }
        }
    }

    /**
     * Set the background image of the sent error message bubble.
     */
    public var sendErrorBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.outgoingErrorBubble
        }
        set {
            TUIBubbleMessageCell.outgoingErrorBubble = newValue
        }
    }

    /**
     * Set the background image of the received message bubble in consecutive message.
     */
    public var receiveBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingBubble = image
            }
        }
    }

    /**
     * Set the background image of the received message bubble in highlight status.
     */
    public var receiveHighlightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingHighlightedBubble
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingHighlightedBubble = image
            }
        }
    }

    /**
     * Set the light background image when the received message bubble needs to flicker.
     */
    public var receiveAnimateLightBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha20
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha20 = image
            }
        }
    }

    /**
     * Set the dark background image when the received message bubble needs to flicker.
     */
    public var receiveAnimateDarkBubbleBackgroundImage: UIImage? {
        get {
            return TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha50
        }
        set {
            if let image = newValue {
                TUIBubbleMessageCell.incommingAnimatedHighlightedAlpha50 = image
            }
        }
    }

    /**
     * Set the background image of the received error message bubble.
     */
    public var receiveErrorBubbleBackgroundImage: UIImage? {
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

    /**
     *  DataSource for inputBar.
     */
    public var inputBarDataSource: TUIChatInputBarConfigDataSource? {
        get {
            return TUIChatConfig.shared.inputBarDataSource
        }
        set {
            TUIChatConfig.shared.inputBarDataSource = newValue
        }
    }

    /**
     *  DataSource for shortcutView above inputBar.
     */
    public var shortcutViewDataSource: TUIChatShortcutViewDataSource? {
        get {
            return TUIChatConfig.shared.shortcutViewDataSource
        }
        set {
            TUIChatConfig.shared.shortcutViewDataSource = newValue
        }
    }

    /**
     *  Show the input bar in the message list interface.
     *  The default value is YES.
     */
    public var showInputBar: Bool {
        get {
            return !TUIChatConfig.shared.enableMainPageInputBar
        }
        set {
            TUIChatConfig.shared.enableMainPageInputBar = !newValue
        }
    }

    /**
     *  Hide items in more menu.
     */
    public static func hideItemsInMoreMenu(_ items: TUIChatInputBarMoreMenuItem) {
        let value = items.rawValue
        TUIChatConfig.shared.enableWelcomeCustomMessage = (value & TUIChatInputBarMoreMenuItem.customMessage.rawValue) == 0
        TUIChatConfig.shared.showRecordVideoButton = (value & TUIChatInputBarMoreMenuItem.recordVideo.rawValue) == 0
        TUIChatConfig.shared.showTakePhotoButton = (value & TUIChatInputBarMoreMenuItem.takePhoto.rawValue) == 0
        TUIChatConfig.shared.showAlbumButton = (value & TUIChatInputBarMoreMenuItem.album.rawValue) == 0
        TUIChatConfig.shared.showFileButton = (value & TUIChatInputBarMoreMenuItem.file.rawValue) == 0
    }

    /**
     * Add sticker group.
     */
    public func addStickerGroup(_ group: TUIFaceGroup) {
        if let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self) {
            service.appendFaceGroup(group)
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
