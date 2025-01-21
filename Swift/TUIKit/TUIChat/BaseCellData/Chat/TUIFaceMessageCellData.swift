import Foundation
import TIMCommon

class TUIFaceMessageCellData: TUIBubbleMessageCellData {
    var groupIndex: Int32 = 0
    var path: String?
    var faceName: String?

    override class func getCellData(_ message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.faceElem else { return TUIFaceMessageCellData(direction: .MsgDirectionIncoming) }
        let faceData = TUIFaceMessageCellData(direction: message.isSelf ? .MsgDirectionOutgoing : .MsgDirectionIncoming)
        faceData.groupIndex = elem.index
        if let data = elem.data {
            faceData.faceName = String(data: data, encoding: .utf8)
        }

        for group in TIMConfig.default().faceGroups {
            if group.groupIndex == faceData.groupIndex {
                if let url = URL(string: group.groupPath) {
                    let path = url.appendingPathComponent(faceData.faceName ?? "").path
                    faceData.path = path
                }
                break
            }
        }

        faceData.reuseId = TFaceMessageCell_ReuseId
        return faceData
    }

    override class func getDisplayString(_ message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIKitMessageTypeAnimateEmoji")
    }
}
