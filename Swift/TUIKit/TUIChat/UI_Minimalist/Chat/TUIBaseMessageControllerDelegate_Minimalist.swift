import Foundation
import TIMCommon

protocol TUIBaseMessageControllerDelegate_Minimalist: AnyObject {
    func didTap(_ controller: TUIBaseMessageController_Minimalist)
    func didHideMenu(_ controller: TUIBaseMessageController_Minimalist)
    func willShowMenu(_ controller: TUIBaseMessageController_Minimalist, inCell cell: TUIMessageCell) -> Bool
    func onNewMessage(_ controller: TUIBaseMessageController_Minimalist?, message: V2TIMMessage) -> TUIMessageCellData?
    func onShowMessageData(_ controller: TUIBaseMessageController_Minimalist?, data: TUIMessageCellData) -> TUIMessageCell?
    func willDisplayCell(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell, withData cellData: TUIMessageCellData)
    func onSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell)
    func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell)
    func onSelectMessageContent(_ controller: TUIBaseMessageController_Minimalist?, cell: TUIMessageCell)
    func onSelectMessageMenu(_ controller: TUIBaseMessageController_Minimalist, menuType: NSInteger, withData data: TUIMessageCellData?)
    func onRelyMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    func onReferenceMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    func onReEditMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    func getTopMarginByCustomView() -> CGFloat
    func onSelectMessageWhenMultiCheckboxAppear(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?)
    func onForwardText(_ controller: TUIBaseMessageController_Minimalist, text: String)
}

extension TUIBaseMessageControllerDelegate_Minimalist {
    func didTap(_ controller: TUIBaseMessageController_Minimalist) {}
    func didHideMenu(_ controller: TUIBaseMessageController_Minimalist) {}
    func willShowMenu(_ controller: TUIBaseMessageController_Minimalist, inCell cell: TUIMessageCell) -> Bool { return false }
    func onNewMessage(_ controller: TUIBaseMessageController_Minimalist?, message: V2TIMMessage) -> TUIMessageCellData? { return TUIMessageCellData(direction: .incoming) }
    func onShowMessageData(_ controller: TUIBaseMessageController_Minimalist?, data: TUIMessageCellData) -> TUIMessageCell? { return TUIMessageCell() }
    func willDisplayCell(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell, withData cellData: TUIMessageCellData) {}
    func onSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell) {}
    func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController_Minimalist, cell: TUIMessageCell) {}
    func onSelectMessageContent(_ controller: TUIBaseMessageController_Minimalist?, cell: TUIMessageCell) {}
    func onSelectMessageMenu(_ controller: TUIBaseMessageController_Minimalist, menuType: NSInteger, withData data: TUIMessageCellData?) {}
    func onRelyMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {}
    func onReferenceMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {}
    func onReEditMessage(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {}
    func getTopMarginByCustomView() -> CGFloat { return 0.0 }
    func onSelectMessageWhenMultiCheckboxAppear(_ controller: TUIBaseMessageController_Minimalist, data: TUIMessageCellData?) {}
    func onForwardText(_ controller: TUIBaseMessageController_Minimalist, text: String) {}
}
