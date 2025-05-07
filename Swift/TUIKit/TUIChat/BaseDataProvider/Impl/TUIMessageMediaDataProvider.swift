import Foundation
import ImSDK_Plus
import TIMCommon

class TUIMessageMediaDataProvider: TUIMessageBaseMediaDataProvider {
    override class func getMediaCellData(_ message: V2TIMMessage) -> TUIMessageCellData? {
        if message.status == .MSG_STATUS_HAS_DELETED || message.status == .MSG_STATUS_LOCAL_REVOKED {
            return nil
        }
        var data: TUIMessageCellData?
        if message.elemType == .ELEM_TYPE_IMAGE {
            data = TUIImageMessageCellData.getCellData(message: message)
        } else if message.elemType == .ELEM_TYPE_VIDEO {
            data = TUIVideoMessageCellData.getCellData(message: message)
        }
        if let data = data {
            data.innerMessage = message
        }
        return data
    }
}
