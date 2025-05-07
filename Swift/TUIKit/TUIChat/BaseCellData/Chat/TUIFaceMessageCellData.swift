import Foundation
import TIMCommon

class TUIFaceMessageCellData: TUIBubbleMessageCellData {
    var groupIndex: Int32 = 0
    var path: String?
    var faceName: String?

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.faceElem else { return TUIFaceMessageCellData(direction: .incoming) }
        let faceData = TUIFaceMessageCellData(direction: message.isSelf ? .outgoing : .incoming)
        faceData.groupIndex = elem.index
        if let data = elem.data {
            faceData.faceName = String(data: data, encoding: .utf8)
        }

        if let groups = TIMConfig.shared.faceGroups {
            for group in groups {
                if group.groupIndex == faceData.groupIndex {
                    if let url = URL(string: group.groupPath ?? "") {
                        let path = url.appendingPathComponent(faceData.faceName ?? "").path
                        faceData.path = path
                    }
                    break
                }
            }
        }

        faceData.reuseId = "TFaceMessageCell"
        return faceData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIKitMessageTypeAnimateEmoji")
    }
}
