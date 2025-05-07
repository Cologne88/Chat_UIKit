import Foundation
import ImSDK_Plus
import TIMCommon

protocol TUIBaseMessageControllerDelegate: NSObjectProtocol {
    func didTap(_ controller: TUIBaseMessageController)
    func didHideMenu(_ controller: TUIBaseMessageController)
    func willShowMenu(_ controller: TUIBaseMessageController, inCell cell: TUIMessageCell) -> Bool
    func onNewMessage(_ controller: TUIBaseMessageController?, message: V2TIMMessage) -> TUIMessageCellData?
    func onShowMessageData(_ controller: TUIBaseMessageController?, data: TUIMessageCellData) -> TUIMessageCell?
    func willDisplayCell(_ controller: TUIBaseMessageController, cell: TUIMessageCell, withData cellData: TUIMessageCellData)
    func onSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell)
    func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell)
    func onSelectMessageContent(_ controller: TUIBaseMessageController?, cell: TUIMessageCell)
    func onSelectMessageMenu(_ controller: TUIBaseMessageController, menuType: NSInteger, withData data: TUIMessageCellData?)
    func onRelyMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    func onReferenceMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    func onReEditMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?)
    func onForwardText(_ controller: TUIBaseMessageController, text: String)
    func getTopMarginByCustomView() -> CGFloat
}

extension TUIBaseMessageControllerDelegate {
    func didTap(_ controller: TUIBaseMessageController) {}
    func didHideMenu(_ controller: TUIBaseMessageController) {}
    func willShowMenu(_ controller: TUIBaseMessageController, inCell cell: TUIMessageCell) -> Bool { return true }
    func onNewMessage(_ controller: TUIBaseMessageController?, message: V2TIMMessage) -> TUIMessageCellData? { return nil }
    func onShowMessageData(_ controller: TUIBaseMessageController?, data: TUIMessageCellData) -> TUIMessageCell? { return nil }
    func willDisplayCell(_ controller: TUIBaseMessageController, cell: TUIMessageCell, withData cellData: TUIMessageCellData) {}
    func onSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell) {}
    func onLongSelectMessageAvatar(_ controller: TUIBaseMessageController, cell: TUIMessageCell) {}
    func onSelectMessageContent(_ controller: TUIBaseMessageController?, cell: TUIMessageCell) {}
    func onSelectMessageMenu(_ controller: TUIBaseMessageController, menuType: NSInteger, withData data: TUIMessageCellData?) {}
    func onRelyMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?) {}
    func onReferenceMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?) {}
    func onReEditMessage(_ controller: TUIBaseMessageController, data: TUIMessageCellData?) {}
    func onForwardText(_ controller: TUIBaseMessageController, text: String) {}
    func getTopMarginByCustomView() -> CGFloat { return 0.0 }
}
