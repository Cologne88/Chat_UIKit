import Foundation

public protocol TIMPopActionProtocol: AnyObject {
    func onDelete(_ sender: Any?)
    func onCopyMsg(_ sender: Any?)
    func onRevoke(_ sender: Any?)
    func onReSend(_ sender: Any?)
    func onMulitSelect(_ sender: Any?)
    func onForward(_ sender: Any?)
    func onReply(_ sender: Any?)
    func onReference(_ sender: Any?)
}
