import Foundation
import TIMCommon

@objc protocol TUIBaseMessageControllerDelegate_Minimalist: NSObjectProtocol {
    @objc optional func didTap(_ controller: TUIBaseMessageController_Minimalist)
    @objc optional func didHideMenu(_ controller: TUIBaseMessageController_Minimalist)
    @objc optional func willShowMenu(_ controller: TUIBaseMessageController_Minimalist, inCell cell: TUIMessageCell) -> Bool
    @objc optional func onNewMessage(_ controller: TUIBaseMessageController_Minimalist?, message: V2TIMMessage) -> TUIMessageCellData?
    @objc optional func onShowMessageData(_ controller: TUIBaseMessageController_Minimalist?, data: TUIMessageCellData) -> TUIMessageCell?
    @objc optional func willDisplayCell(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell, withData cellData: TUIMessageCellData)
    @objc optional func onSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell)
    @objc optional func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell)
    @objc optional func onSelectMessageContent(_ controller: TUIBaseMessageController_Minimalist?, cell: TUIMessageCell)
    @objc optional func onSelectMessageMenu(_ controller: TUIBaseMessageController_Minimalist, menuType: NSInteger, withData data: TUIMessageCellData?)
    @objc optional func onRelyMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    @objc optional func onReferenceMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    @objc optional func onReEditMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    @objc optional func getTopMarginByCustomView() -> CGFloat
    @objc optional func onSelectMessageWhenMultiCheckboxAppear(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    @objc optional func onForwardText(_ controller: TUIBaseMessageController_Minimalist, text: String)
}
