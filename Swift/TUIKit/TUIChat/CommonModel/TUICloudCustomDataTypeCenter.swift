import Foundation
import ImSDK_Plus
import TIMCommon

typealias TUICustomType = String

let messageFeature: TUICustomType = "messageFeature"

public struct TUICloudCustomDataType: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = TUICloudCustomDataType(rawValue: 1 << 0)
    public static let messageReply = TUICloudCustomDataType(rawValue: 1 << 1)
    public static let messageReplies = TUICloudCustomDataType(rawValue: 1 << 3)
    public static let messageReference = TUICloudCustomDataType(rawValue: 1 << 4)
}

extension V2TIMMessage {
    func doThingsInContainsCloudCustom(of type: TUICloudCustomDataType, callback: @escaping (Bool, Any?) -> Void) {
        guard let cloudCustomData = self.cloudCustomData else {
            callback(false, nil)
            return
        }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: cloudCustomData, options: []) as? [String: Any],
               let typeStr = TUICloudCustomDataTypeCenter.convertType2String(type),
               !typeStr.isEmpty,
               dict.keys.contains(typeStr)
            {
                if type == .messageReply {
                    if let reply = dict[typeStr] as? [String: Any],
                       let version = reply["version"] as? Int,
                       version <= kMessageReplyVersion
                    {
                        callback(true, reply)
                    } else {
                        callback(false, nil)
                    }
                } else if type == .messageReference {
                    if let reply = dict[typeStr] as? [String: Any],
                       let version = reply["version"] as? Int,
                       version <= kMessageReplyVersion,
                       !reply.keys.contains("messageRootID")
                    {
                        callback(true, reply)
                    } else {
                        callback(false, nil)
                    }
                } else if type == .messageReplies {
                    if let messageReplies = dict[typeStr] as? [String: Any],
                       let replies = messageReplies["replies"] as? [[String: Any]],
                       !replies.isEmpty
                    {
                        callback(true, dict)
                    } else {
                        callback(false, nil)
                    }
                }
            } else {
                callback(false, nil)
            }
        } catch {
            callback(false, nil)
        }
    }
    
    func isContainsCloudCustom(of type: TUICloudCustomDataType) -> Bool {
        guard let cloudCustomData = self.cloudCustomData else {
            return false
        }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: cloudCustomData, options: []) as? [String: Any],
               let typeStr = TUICloudCustomDataTypeCenter.convertType2String(type),
               !typeStr.isEmpty,
               dict.keys.contains(typeStr)
            {
                if type == .messageReply {
                    if let reply = dict[typeStr] as? [String: Any],
                       let version = reply["version"] as? Int,
                       version <= kMessageReplyVersion,
                       reply.keys.contains("messageRootID")
                    {
                        return true
                    }
                } else if type == .messageReference {
                    if let reply = dict[typeStr] as? [String: Any],
                       let version = reply["version"] as? Int,
                       version <= kMessageReplyVersion,
                       !reply.keys.contains("messageRootID")
                    {
                        return true
                    }
                } else if type == .messageReplies {
                    if let messageReplies = dict[typeStr] as? [String: Any],
                       let replies = messageReplies["replies"] as? [[String: Any]],
                       !replies.isEmpty
                    {
                        return true
                    }
                }
            }
        } catch {
            return false
        }
        
        return false
    }
    
    func parseCloudCustomData(_ customType: TUICustomType) -> Any? {
        guard let cloudCustomData = self.cloudCustomData, !customType.isEmpty else {
            return nil
        }
        
        do {
            if let dict = try JSONSerialization.jsonObject(with: cloudCustomData, options: []) as? [String: Any],
               dict.keys.contains(customType)
            {
                return dict[customType]
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    func setCloudCustomData(_ jsonData: Any, forType customType: TUICustomType) {
        guard !customType.isEmpty else {
            return
        }
        
        var dict: [String: Any] = [:]
        
        if let cloudCustomData = self.cloudCustomData {
            do {
                if let existingDict = try JSONSerialization.jsonObject(with: cloudCustomData, options: []) as? [String: Any] {
                    dict = existingDict
                }
            } catch {
                dict = [:]
            }
        }
        
        dict[customType] = jsonData
        
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            self.cloudCustomData = data
        }
    }
    
    func modifyIfNeeded(callback: @escaping V2TIMMessageModifyCompletion) {
       V2TIMManager.sharedInstance().modifyMessage(msg: self, completion: callback)
    }
}

class TUICloudCustomDataTypeCenter {
    static func convertType2String(_ type: TUICloudCustomDataType) -> String? {
        switch type {
        case .messageReply, .messageReference:
            return "messageReply"
        case .messageReplies:
            return "messageReplies"
        default:
            return nil
        }
    }
}
