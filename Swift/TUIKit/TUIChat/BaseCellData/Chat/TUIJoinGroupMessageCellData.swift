import Foundation
import TIMCommon

class TUIJoinGroupMessageCellData: TUISystemMessageCellData {
    var opUserName: String?
    var userNameList: [String]?
    var opUserID: String?
    var userIDList: [String]?

    init(direction: TMsgDirection, opUserName: String = "", opUserID: String = "") {
        self.opUserName = opUserName
        self.opUserID = opUserID
        self.userNameList = []
        self.userIDList = []
        super.init(direction: direction)
    }

    required init() {
        fatalError("init() has not been implemented")
    }
}
