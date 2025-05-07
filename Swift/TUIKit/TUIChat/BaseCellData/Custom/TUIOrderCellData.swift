import Foundation
import TIMCommon
import UIKit

class TUIOrderCellData: TUIBubbleMessageCellData {
    var title: String? = ""
    var desc: String? = ""
    var price: String? = ""
    var imageUrl: String? = ""
    var link: String? = ""

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUIOrderCellData(direction: .incoming)
        }

        let cellData = TUIOrderCellData(direction: message.isSelf ? .outgoing : .incoming)
        cellData.innerMessage = message
        cellData.msgID = message.msgID
        cellData.title = param["title"] as? String ?? ""
        cellData.desc = param["description"] as? String ?? ""
        cellData.imageUrl = param["imageUrl"] as? String ?? ""
        cellData.link = param["link"] as? String ?? ""
        cellData.price = param["price"] as? String ?? ""
        cellData.avatarUrl = URL(string: message.faceURL ?? "")
        return cellData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return ""
        }
        return param["title"] as? String ?? ""
    }

    func contentSize() -> CGSize {
        return CGSize(width: 245, height: 80)
    }
}
