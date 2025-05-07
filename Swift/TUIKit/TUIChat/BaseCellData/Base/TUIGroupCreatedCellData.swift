import TIMCommon
import TUICore

class TUIGroupCreatedCellData: TUISystemMessageCellData {
    var opUser: String?
    var cmd: NSNumber?

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let data = message.customElem?.data,
              let param = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        else {
            return TUIGroupCreatedCellData(direction: .incoming)
        }

        let cellData = TUIGroupCreatedCellData(direction: message.isSelf ? .outgoing : .incoming)
        cellData.innerMessage = message
        cellData.msgID = message.msgID
        cellData.content = param["content"] as? String ?? ""
        cellData.opUser = getOpUserName(info: message) ?? param["opUser"] as? String
        cellData.cmd = param["cmd"] as? NSNumber
        return cellData
    }

    static func getOpUserName(info: V2TIMMessage) -> String? {
        if let nameCard = info.nameCard, !nameCard.isEmpty {
            return nameCard
        } else if let nickName = info.nickName, !nickName.isEmpty {
            return nickName
        } else {
            return info.userID
        }
    }

    override var attributedString: NSMutableAttributedString? {
        get {
            var localizableContent = content
            if let command = cmd?.intValue {
                if command == 1 {
                    localizableContent = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessage")
                } else {
                    localizableContent = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessage")
                }
            }
            let str = "\"\(opUser ?? "")\" \(localizableContent ?? "")"
            let rtlStr = rtlString(str)
            let attributeString = NSMutableAttributedString(string: rtlStr)
            let attributeDict: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.d_systemGray()]
            attributeString.setAttributes(attributeDict, range: NSRange(location: 0, length: attributeString.length))
            return attributeString
        }
        set {
            super.attributedString = newValue
        }
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        guard let data = message.customElem?.data, let param = TUITool.jsonData2Dictionary(data) else { return "" }

        guard let businessID = param["businessID"] as? String,
              businessID == "group_create" || param.keys.contains("group_create")
        else {
            return ""
        }

        var localizableContent = param["content"] as? String
        if let command = param["cmd"] as? NSNumber, command.intValue == 1 {
            localizableContent = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessage")
        } else {
            localizableContent = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessage")
        }
        let opUser = getOpUserName(info: message) ?? param["opUser"] as? String
        let str = "\"\(opUser ?? "")\" \(localizableContent ?? "")"
        return rtlString(str)
    }
}
