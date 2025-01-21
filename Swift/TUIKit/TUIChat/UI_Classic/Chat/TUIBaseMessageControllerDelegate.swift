import Foundation
import ImSDK_Plus
import TIMCommon

@objc protocol TUIBaseMessageControllerDelegate: NSObjectProtocol {
    @objc optional func didTap(_ controller: TUIBaseMessageController)
    @objc optional func didHideMenu(_ controller: TUIBaseMessageController)
    @objc optional func willShowMenu(_ controller: TUIBaseMessageController, inCell cell: TUIMessageCell) -> Bool
    @objc optional func onNewMessage(_ controller: TUIBaseMessageController?, message: V2TIMMessage) -> TUIMessageCellData?
    @objc optional func onShowMessageData(_ controller: TUIBaseMessageController?, data: TUIMessageCellData) -> TUIMessageCell?
    @objc optional func willDisplayCell(_ controller: TUIBaseMessageController, cell: TUIMessageCell, withData cellData: TUIMessageCellData)
    @objc optional func onSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell)
    @objc optional func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell)
    @objc optional func onSelectMessageContent(_ controller: TUIBaseMessageController?, cell: TUIMessageCell)
    @objc optional func onSelectMessageMenu(_ controller: TUIBaseMessageController, menuType: NSInteger, withData data: TUIMessageCellData?)
    @objc optional func onRelyMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    @objc optional func onReferenceMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    @objc optional func onReEditMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    @objc optional func onForwardText(_ controller: TUIBaseMessageController, text: String)
    @objc optional func getTopMarginByCustomView() -> CGFloat
}
