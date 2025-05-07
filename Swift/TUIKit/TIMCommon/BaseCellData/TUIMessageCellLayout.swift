import UIKit

public class TUIMessageCellLayout {
    public var messageInsets: UIEdgeInsets
    public var bubbleInsets: UIEdgeInsets
    public var avatarInsets: UIEdgeInsets
    public var avatarSize: CGSize
    
    public init(isIncoming: Bool) {
        self.avatarSize = CGSize(width: 40, height: 40)
        if isIncoming {
            self.avatarInsets = UIEdgeInsets(top: 3, left: 8, bottom: 1, right: 0)
            self.messageInsets = UIEdgeInsets(top: 3, left: 8, bottom: 17, right: 0)
        } else {
            self.avatarInsets = UIEdgeInsets(top: 3, left: 0, bottom: 1, right: 8)
            self.messageInsets = UIEdgeInsets(top: 3, left: 0, bottom: 17, right: 8)
        }
        self.bubbleInsets = UIEdgeInsets.zero
    }
    
    public static var incomingMessageLayout: TUIMessageCellLayout = .init(isIncoming: true)
    
    public static var outgoingMessageLayout: TUIMessageCellLayout = .init(isIncoming: false)
    
    public static var incomingTextMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: true)
        layout.bubbleInsets = UIEdgeInsets(top: 10.5, left: 16, bottom: 10.5, right: 16)
        return layout
    }()
    
    public static var outgoingTextMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: false)
        layout.bubbleInsets = UIEdgeInsets(top: 10.5, left: 16, bottom: 10.5, right: 16)
        return layout
    }()
    
    public static var incomingVoiceMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: true)
        layout.bubbleInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return layout
    }()
    
    public static var outgoingVoiceMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: false)
        layout.bubbleInsets = UIEdgeInsets(top: 14, left: 22, bottom: 20, right: 20)
        return layout
    }()
    
    public static var systemMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: true)
        layout.messageInsets = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        return layout
    }()
    
    public static var incomingImageMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: true)
        layout.bubbleInsets = UIEdgeInsets.zero
        return layout
    }()
    
    public static var outgoingImageMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: false)
        layout.bubbleInsets = UIEdgeInsets.zero
        return layout
    }()
    
    public static var incomingVideoMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: true)
        layout.bubbleInsets = UIEdgeInsets.zero
        return layout
    }()
    
    public static var outgoingVideoMessageLayout: TUIMessageCellLayout = {
        let layout = TUIMessageCellLayout(isIncoming: false)
        layout.bubbleInsets = UIEdgeInsets.zero
        return layout
    }()
}
