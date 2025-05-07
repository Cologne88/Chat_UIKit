//
//  TUIEmojiReactDataProvider.swift
//  TUIEmojiPlugin
//
//  Created by cologne on 2023/11/23.
//

import Foundation
import ImSDK_Plus
import TIMCommon

typealias TUIEmojiReactGetMessageReactionsSucc = (_ tagsArray: [TUIReactModel], _ tagsMap: [String: TUIReactModel]) -> Void
typealias TUIEmojiReactMessageReactionsChanged = (_ tagsArray: [TUIReactModel], _ tagsMap: [String: TUIReactModel]) -> Void

class TUIEmojiReactDataProvider: NSObject, V2TIMAdvancedMsgListener {
    var msgId: String?
    var changed: TUIEmojiReactMessageReactionsChanged?
    var isFirsLoad: Bool = false
    
    private var _reactMap: [String: TUIReactModel]?
    var reactMap: [String: TUIReactModel] {
        get {
            if let map = _reactMap {
                return map
            } else {
                let map = [String: TUIReactModel]()
                self._reactMap = map
                return map
            }
        }
        set {
            self._reactMap = newValue
        }
    }
    
    private var _reactArray: [TUIReactModel]?
    var reactArray: [TUIReactModel] {
        get {
            if let array = _reactArray {
                return array
            } else {
                let array = [TUIReactModel]()
                self._reactArray = array
                return array
            }
        }
        set {
            self._reactArray = newValue
        }
    }
    
    override init() {
        super.init()
        self.setupNotify()
    }
    
    func setupNotify() {
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
    }
    
    func addMessageReaction(v2Message: V2TIMMessage, reactionID: String, succ: V2TIMSucc?, fail: V2TIMFail?) {
        V2TIMManager.sharedInstance().addMessageReaction(message: v2Message, reactionID: reactionID, succ: {
            succ?()
        }, fail: { code, desc in
            fail?(code, desc)
        })
    }
    
    func removeMessageReaction(v2Message: V2TIMMessage, reactionID: String, succ: V2TIMSucc?, fail: V2TIMFail?) {
        V2TIMManager.sharedInstance().removeMessageReaction(message: v2Message, reactionID: reactionID, succ: {
            succ?()
        }, fail: { code, desc in
            fail?(code, desc)
        })
    }
    
    func getMessageReactions(messageList: [V2TIMMessage], maxUserCountPerReaction: UInt32, succ: TUIEmojiReactGetMessageReactionsSucc?, fail: V2TIMFail?) {
        self.isFirsLoad = true
        V2TIMManager.sharedInstance().getMessageReactions(messageList: messageList, maxUserCountPerReaction: maxUserCountPerReaction, succ: { [weak self] resultList in
            guard let self = self, let resultList = resultList else { return }
            var modifyUserMap = [String: TUIReactModel]()
            var reactArray = [TUIReactModel]()
            for result in resultList {
                if let reactionList = result.reactionList {
                    for reaction in reactionList {
                        let model = TUIReactModel.createTagsModelByReaction(reaction)
                        modifyUserMap[model.emojiKey] = model
                        reactArray.append(model)
                    }
                }
            }
            self.reactMap = modifyUserMap
            self.reactArray = reactArray
            succ?(reactArray, modifyUserMap)
        }, fail: { code, desc in
            fail?(code, desc)
        })
    }
    
    func onRecvMessageReactionsChanged(changeList: [V2TIMMessageReactionChangeInfo]) {
        let changedReactMap = NSMutableDictionary(capacity: 3)
        let changedReactArray = NSMutableArray(capacity: 3)
        for changeInfo in changeList {
            guard let currentMsgId = self.msgId,
                  changeInfo.msgID == currentMsgId
            else {
                return
            }
            if let reactionList = changeInfo.reactionList {
                for reaction in reactionList {
                    let model = TUIReactModel.createTagsModelByReaction(reaction)
                    changedReactMap[model.emojiKey] = model
                    changedReactArray.add(model)
                }
            }
        }
        
        var sortedReactMap = self.reactMap
        var sortedReactArray = self.reactArray
        
        for (key, changedValue) in changedReactMap {
            guard let _ = key as? String,
                  let changedObj = changedValue as? TUIReactModel
            else {
                continue
            }
            var inOrigin = false
            for originObj in self.reactArray {
                if originObj.emojiKey == changedObj.emojiKey {
                    inOrigin = true
                    if changedObj.totalUserCount != 0 {
                        sortedReactMap[originObj.emojiKey] = changedObj
                        sortedReactArray.removeAll(where: { $0 == originObj })
                        sortedReactArray.append(changedObj)
                    } else {
                        sortedReactMap.removeValue(forKey: originObj.emojiKey)
                        sortedReactArray.removeAll(where: { $0 == originObj })
                    }
                }
            }
            if !inOrigin {
                sortedReactArray.append(changedObj)
                sortedReactMap[changedObj.emojiKey] = changedObj
            }
        }
        
        self.reactArray = sortedReactArray
        self.reactMap = sortedReactMap
        
        if let changedClosure = self.changed {
            changedClosure(sortedReactArray, sortedReactMap)
        }
    }
    
    func getCurrentReactionIDInMap(_ reactionID: String) -> TUIReactModel? {
        if let model = self.reactMap[reactionID] {
            return model
        }
        return nil
    }
}
