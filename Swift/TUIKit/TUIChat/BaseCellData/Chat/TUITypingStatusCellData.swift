import Foundation
import TIMCommon

class TUITypingStatusCellData: TUIMessageCellData {
    var typingStatus: Int = 0

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUITypingStatusCellData(direction: .incoming)
        }

        let cellData = TUITypingStatusCellData(direction: message.isSelf ? .outgoing : .incoming)
        cellData.msgID = message.msgID

        if let typingStatus = param["typingStatus"] as? Int {
            cellData.typingStatus = typingStatus
        }

        return cellData
    }
}
