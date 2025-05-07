//
//  TUIEmojiMessageReactPreLoadProvider.swift
//  TUIEmojiPlugin
//
//  Created by cologne on 2023/12/26.
//

import Foundation
import ImSDK_Plus
import TIMCommon

class TUIEmojiMessageReactPreLoadProvider: NSObject {
    func getMessageReactions(cellDataList: [TUIMessageCellData],
                             maxUserCountPerReaction: UInt32,
                             succ: V2TIMSucc?,
                             fail: V2TIMFail?)
    {
        var messageList = [V2TIMMessage]()
        var cellDataMap = [String: TUIMessageCellData]()

        for cellData in cellDataList {
            if let innerMessage = cellData.innerMessage {
                if innerMessage.status != .MSG_STATUS_SEND_FAIL {
                    messageList.append(innerMessage)
                }
                if let msgID = cellData.msgID {
                    cellDataMap[msgID] = cellData
                }
            }
            if cellData.reactdataProvider == nil {
                cellData.setupReactDataProvider()
            }
        }

        V2TIMManager.sharedInstance().getMessageReactions(messageList: messageList, maxUserCountPerReaction: maxUserCountPerReaction) { (resultList: [V2TIMMessageReactionResult]?) in
            guard let resultList = resultList else {
                succ?()
                return
            }
            for result in resultList {
                if let reactionList = result.reactionList {
                    for reaction in reactionList {
                        let model = TUIReactModel.createTagsModelByReaction(reaction)
                        if let msgID = result.msgID, let cellData = cellDataMap[msgID] {
                            cellData.reactdataProvider?.isFirsLoad = true
                            cellData.reactdataProvider?.reactMap[model.emojiKey] = model
                            cellData.reactdataProvider?.reactArray.append(model)
                        }
                    }
                }
            }
            succ?()
        } fail: { code, desc in
            fail?(code, desc)
        }
    }
}
