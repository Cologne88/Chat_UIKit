import Foundation
import ImSDK_Plus
import TIMCommon

class TUIChatModifyMessageHelper: NSObject, V2TIMAdvancedMsgListener {
    public static let shared = TUIChatModifyMessageHelper()
    let timesControl = 3
    let retryMinTimeInMS = 500
    let retryMaxTimeInMS = 3000
    
    private var modifyMessageHelperMap: [String: TUIChatModifyMessageObject] = [:]
    private var queue: OperationQueue
    
    // MARK: - Init

    override private init() {
        self.queue = OperationQueue()
        super.init()
        queue.maxConcurrentOperationCount = 1
        registerTUIKitNotification()
    }
    
    private func registerTUIKitNotification() {
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
    }
    
    // MARK: - V2TIMAdvancedMsgListener

    func onRecvMessageModified(msg: V2TIMMessage) {
        if let msgID = msg.msgID, let obj = modifyMessageHelperMap[msgID] {
            obj.msg = msg
        }
    }
    
    // MARK: - Func

    func modifyMessage(_ msg: V2TIMMessage, reactEmoji emojiName: String) {
        modifyMessage(msg, reactEmoji: nil, simpleCurrentContent: nil, revokeMsgID: nil, timeControl: 0)
    }

    public func modifyMessage(_ msg: V2TIMMessage, simpleCurrentContent: [String: Any]?) {
        modifyMessage(msg, reactEmoji: nil, simpleCurrentContent: simpleCurrentContent, revokeMsgID: nil, timeControl: 0)
    }
    
    public func modifyMessage(_ msg: V2TIMMessage, revokeMsgID: String?) {
        modifyMessage(msg, reactEmoji: nil, simpleCurrentContent: nil, revokeMsgID: revokeMsgID, timeControl: 0)
    }
    
    private func modifyMessage(_ msg: V2TIMMessage, reactEmoji: String?, simpleCurrentContent: [String: Any]?, revokeMsgID: String?, timeControl: Int) {
        guard let msgID = msg.msgID, !msgID.isEmpty else { return }
        
        let modifyMsgObj = TUIChatModifyMessageObject()
        modifyMsgObj.msgID = msgID
        modifyMsgObj.msg = msg
        modifyMsgObj.time = timeControl
        
        if let content = simpleCurrentContent {
            modifyMsgObj.simpleCurrentContent = content
        }
        if let revokeID = revokeMsgID {
            modifyMsgObj.revokeMsgID = revokeID
        }
        
        modifyMessageHelperMap[msgID] = modifyMsgObj
        
        let modifyOperation = ModifyCustomOperation()
        modifyOperation.obj = modifyMsgObj
        modifyOperation.successBlock = { [weak self] in
            self?.modifyMessageHelperMap.removeValue(forKey: msgID)
        }
        
        modifyOperation.failedBlock = { [weak self] _, _, msg in
            guard let self = self else { return }
            if modifyMsgObj.time <= timesControl {
                let delay = self.getRandomNumber(from: retryMinTimeInMS, to: retryMaxTimeInMS)
                modifyMsgObj.msg = msg
                modifyMsgObj.time += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                    if let obj = self.modifyMessageHelperMap[msgID], let msg = obj.msg {
                        self.modifyMessage(msg, reactEmoji: nil, simpleCurrentContent: obj.simpleCurrentContent, revokeMsgID: obj.revokeMsgID, timeControl: obj.time)
                    }
                }
            } else {
                self.modifyMessageHelperMap.removeValue(forKey: msgID)
            }
        }
        
        if !modifyOperation.isCancelled {
            queue.addOperation(modifyOperation)
        }
    }
    
    private func getRandomNumber(from: Int, to: Int) -> Int {
        return Int.random(in: from ... to)
    }
}

private class TUIChatModifyMessageObject: NSObject {
    var time: Int = 0
    var msgID: String = ""
    var msg: V2TIMMessage?
    var simpleCurrentContent: [String: Any]?
    var revokeMsgID: String?
    
    // MARK: - Func

    func resolveOriginCloudCustomData(_ rootMsg: V2TIMMessage) -> V2TIMMessage {
        if let content = simpleCurrentContent {
            return TUIChatModifyMessageObject.resolveOriginCloudCustomData(rootMsg, simpleCurrentContent: content)
        }
        if let revokeID = revokeMsgID {
            return TUIChatModifyMessageObject.resolveOriginCloudCustomData(rootMsg, revokeMsgID: revokeID)
        }
        return rootMsg
    }
    
    static func resolveOriginCloudCustomData(_ rootMsg: V2TIMMessage, simpleCurrentContent: [String: Any]) -> V2TIMMessage {
        var mudic: [String: Any] = [:]
        var replies: [[String: Any]] = []
        var messageReplies: [String: Any] = [:]
        
        if let cloudData = rootMsg.cloudCustomData, let originDic = TUITool.jsonData2Dictionary(cloudData) as? [String: Any] {
            messageReplies.merge(originDic) { _, new in new }
            if let messageRepliesArray = originDic["messageReplies"] as? [String: Any],
               let repliesArray = messageRepliesArray["replies"] as? [[String: Any]]
            {
                replies.append(contentsOf: repliesArray)
            }
        }
        
        replies.append(simpleCurrentContent)
        mudic["replies"] = replies
        messageReplies["messageReplies"] = mudic
        messageReplies["version"] = "1"
        
        if let data = TUITool.dictionary2JsonData(messageReplies) {
            rootMsg.cloudCustomData = data
        }
        
        return rootMsg
    }
    
    static func resolveOriginCloudCustomData(_ rootMsg: V2TIMMessage, revokeMsgID: String) -> V2TIMMessage {
        var mudic: [String: Any] = [:]
        var replies: [[String: Any]] = []
        var messageReplies: [String: Any] = [:]
        
        if let cloudData = rootMsg.cloudCustomData, let originDic = TUITool.jsonData2Dictionary(cloudData) as? [String: Any] {
            messageReplies.merge(originDic) { _, new in new }
            if let messageRepliesArray = originDic["messageReplies"] as? [String: Any],
               let repliesArray = messageRepliesArray["replies"] as? [[String: Any]]
            {
                replies.append(contentsOf: repliesArray)
            }
        }
        
        let filterReplies = replies.filter { dic in
            if let messageID = dic["messageID"] as? String {
                return messageID != revokeMsgID
            }
            return false
        }
        
        mudic["replies"] = filterReplies
        messageReplies["messageReplies"] = mudic
        messageReplies["version"] = "1"
        
        if let data = TUITool.dictionary2JsonData(messageReplies) {
            rootMsg.cloudCustomData = data
        }
        
        return rootMsg
    }
}

private class ModifyCustomOperation: Operation, @unchecked Sendable {
    var obj: TUIChatModifyMessageObject?
    var successBlock: (() -> Void)?
    var failedBlock: ((Int32, String?, V2TIMMessage?) -> Void)?
    
    private var _executing: Bool = false
    private var _finished: Bool = false
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override func start() {
        if isCancelled {
            completeOperation()
            return
        }
        
        guard let obj = obj else {
            completeOperation()
            return
        }
        
        _executing = true
        
        let resolveMsg = obj.resolveOriginCloudCustomData(obj.msg!)
        
        V2TIMManager.sharedInstance().modifyMessage(msg: resolveMsg, completion: { [weak self] code, desc, msg in
            guard let self = self else { return }
            if code != 0 {
                self.failedBlock?(Int32(code), desc, msg)
            } else {
                self.successBlock?()
            }
            self.completeOperation()
        })
    }
    
    override func cancel() {
        super.cancel()
        completeOperation()
    }
    
    private func completeOperation() {
        willChangeValue(forKey: "isExecuting")
        _executing = false
        didChangeValue(forKey: "isExecuting")
        
        willChangeValue(forKey: "isFinished")
        _finished = true
        didChangeValue(forKey: "isFinished")
    }
}
