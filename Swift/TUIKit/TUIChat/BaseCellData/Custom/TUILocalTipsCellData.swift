import Foundation
import TIMCommon
import UIKit

class TUILocalTipsCellData: TUISystemMessageCellData {
    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUILocalTipsCellData(direction: .incoming)
        }
  
        let cellData = TUILocalTipsCellData(direction: .incoming)
        cellData.innerMessage = message
        cellData.msgID = message.msgID
        if let content = param["content"] as? String {
            cellData.content = content
        }
        cellData.reuseId = TSystemMessageCell_ReuseId
        return cellData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return ""
        }
        return param["content"] as? String ?? ""
    }
}
