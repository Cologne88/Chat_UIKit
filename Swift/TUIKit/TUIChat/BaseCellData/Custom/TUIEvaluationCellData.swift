import Foundation
import TIMCommon
import UIKit

class TUIEvaluationCellData: TUIBubbleMessageCellData {
    var score: Int = 0
    var desc: String = ""
    var comment: String = ""

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUIEvaluationCellData(direction: .MsgDirectionIncoming)
        }

        let cellData = TUIEvaluationCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        cellData.innerMessage = message
        cellData.desc = message.customElem?.desc ?? ""
        cellData.score = param["score"] as? Int ?? 0
        cellData.comment = param["comment"] as? String ?? ""
        return cellData
    }

    static func getDisplayString(message: V2TIMMessage) -> String {
        return message.customElem?.desc ?? ""
    }

    func contentSize() -> CGSize {
        let rect = comment.boundingRect(
            with: CGSize(width: 215, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.systemFont(ofSize: 15)],
            context: nil
        )
        var size = CGSize(width: 245, height: ceil(rect.height))
        size.height += comment.isEmpty ? 50 : 88
        return size
    }
}
