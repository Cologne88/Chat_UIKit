import Foundation
import TIMCommon

class TUITypingStatusCellData: TUIMessageCellData {
    var typingStatus: Int = 0

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUITypingStatusCellData(direction: .MsgDirectionIncoming)
        }

        let cellData = TUITypingStatusCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        cellData.msgID = message.msgID.safeValue

        if let typingStatus = param["typingStatus"] as? Int {
            cellData.typingStatus = typingStatus
        }

        return cellData
    }
}
