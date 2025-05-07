//
//  TUIEmojiMessageReactPreLoadProvider.swift
//  TUIEmojiPlugin
//
//  Created by cologne on 2023/11/27.
//  Copyright © 2023 Tencent. All rights reserved.
//

import UIKit
import TIMCommon

typealias TUIReactValueChangedCallback = ([TUIReactModel]) -> Void

private struct AssociatedKeys {
    static var reactdataProvider: UInt8 = 0
    static var reactValueChangedCallback: UInt8 = 0
}

extension TUIMessageCellData {
    var reactdataProvider: TUIEmojiReactDataProvider? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.reactdataProvider) as? TUIEmojiReactDataProvider
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.reactdataProvider, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var reactValueChangedCallback: TUIReactValueChangedCallback? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.reactValueChangedCallback) as? TUIReactValueChangedCallback
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.reactValueChangedCallback, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    func setupReactDataProvider() {
        if self.status == TMsgStatus.fail {
            return
        }
        let provider = TUIEmojiReactDataProvider()
        provider.msgId = self.innerMessage?.msgID
        provider.changed = { [weak self] (tagsArray: [TUIReactModel], tagsMap: [AnyHashable: Any]) in
            guard let self = self,
                  let callback = self.reactValueChangedCallback else {
                return
            }
            callback(tagsArray)
        }
        self.reactdataProvider = provider
    }
    
    func addReactModel(_ model: TUIReactModel) {
        self.addReactByEmojiKey(model.emojiKey)
    }
    
    func delReactModel(_ model: TUIReactModel) {
        self.delReactByEmojiKey(model.emojiKey)
    }
    
    func addReactByEmojiKey(_ emojiKey: String) {
        guard let provider = self.reactdataProvider, let innerMessage = self.innerMessage else { return }
        provider.addMessageReaction(v2Message: innerMessage, reactionID: emojiKey) {
            // do nothing
        } fail: { code, desc in
            let errMsg = TUITool.convertIMError(Int(code), msg: desc)
            TUITool.makeToast(errMsg)
        }
    }
    
    func delReactByEmojiKey(_ emojiKey: String) {
        guard let provider = self.reactdataProvider, let innerMessage = self.innerMessage else { return }
        provider.removeMessageReaction(v2Message: innerMessage, reactionID: emojiKey, succ: {
            // do nothing
        }, fail: { code, desc in
            let errMsg = TUITool.convertIMError(Int(code), msg: desc)
            TUITool.makeToast(errMsg)
        })
    }
    
    func updateReactClick(_ faceName: String) {
        guard let provider = self.reactdataProvider else { return }
        if let targetModel = provider.getCurrentReactionIDInMap(faceName) {
            if targetModel.reactedByMyself {
                //del
                self.delReactByEmojiKey(targetModel.emojiKey)
            } else {
                //add
                self.addReactByEmojiKey(targetModel.emojiKey)
            }
        } else {
            // new model
            self.addReactByEmojiKey(faceName)
        }
    }
}
