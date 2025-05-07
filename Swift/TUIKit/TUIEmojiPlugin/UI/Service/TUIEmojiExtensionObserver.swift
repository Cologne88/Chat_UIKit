//
//  TUIEmojiExtensionObserver.swift
//  TUIEmojiPlugin
//
//  Created by cologne on 2023/11/22.
//

import Foundation
import TIMCommon
import TUIChat
import UIKit

public class TUIEmojiExtensionObserver: NSObject, TUIExtensionProtocol {
    weak var navVC: UINavigationController?
    weak var cellData: TUICommonTextCellData?
    
    @objc public class func swiftLoad() {
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatPopMenuReactRecentView_ClassicExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatPopMenuReactRecentView_MinimalistExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
        
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatPopMenuReactDetailView_ClassicExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatPopMenuReactDetailView_MinimalistExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
        
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatMessageReactPreview_ClassicExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
        TUICore.registerExtension("TUICore_TUIChatExtension_ChatMessageReactPreview_MinimalistExtensionID",
                                  object: TUIEmojiExtensionObserver.shared)
    }
    
    @objc static let shared: TUIEmojiExtensionObserver = .init()
    
    override init() {
        super.init()
        setupNotify()
    }
    
    @objc func setupNotify() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fetchReactListByCellDatas(notification:)),
                                               name: NSNotification.Name("TUIKitFetchReactNotification"),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLoginSucceeded),
                                               name: NSNotification.Name("TUILoginSuccessNotification"),
                                               object: nil)
    }
    
    // MARK: - TUIKitFetchReactNotification

    @objc func fetchReactListByCellDatas(notification: Notification) {
        guard let uiMsgs = notification.object as? [TUIMessageCellData] else { return }
        let preLoadProvider = TUIEmojiMessageReactPreLoadProvider()
        let batchSize = 20
        let totalBatches = (uiMsgs.count + batchSize - 1) / batchSize
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let count = min(batchSize, uiMsgs.count - startIndex)
            let batchMsgs = Array(uiMsgs[startIndex..<startIndex + count])
            preLoadProvider.getMessageReactions(cellDataList: batchMsgs,
                                                maxUserCountPerReaction: 5,
                                                succ: {
                                                    for cellData in batchMsgs {
                                                        if let msgID = cellData.msgID {
                                                            if let reactCallback = cellData.reactValueChangedCallback {
                                                                reactCallback(cellData.reactdataProvider?.reactArray ?? [TUIReactModel]())
                                                            }
                                                        }
                                                    }
                                                },
                                                fail: { code, desc in
                                                    NSLog("Error fetching reactions for batch \(batchIndex): \(code) - \(desc)")
                                                })
        }
    }
    
    // MARK: - TUIExtensionProtocol

    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        // Classic: ReactRecentView
        if extensionID == "TUICore_TUIChatExtension_ChatPopMenuReactRecentView_ClassicExtensionID" {
            let emojiRecentView = TUIReactPopRecentView(frame: .zero)
            parentView.addSubview(emojiRecentView)
            emojiRecentView.frame = CGRect(x: 0, y: 0, width: parentView.mm_w, height: 44)
            emojiRecentView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_menu_bg_color", defaultColor: "#FFFFFF")
            emojiRecentView.needShowbottomLine = true
            if let delegateView = param?["TUICore_TUIChatExtension_ChatPopMenuReactRecentView_Delegate"] as? TUIChatPopMenu {
                emojiRecentView.delegateView = delegateView
            }
            return true
        }
        // Classic: ReactDetailView
        else if extensionID == "TUICore_TUIChatExtension_ChatPopMenuReactDetailView_ClassicExtensionID" {
            let emojiAdvanceView = TUIReactPopEmojiView(frame: CGRect(x: 0,
                                                                      y: 44 - 0.5,
                                                                      width: parentView.mm_w,
                                                                      height: TChatEmojiView_CollectionHeight + 10 + TChatEmojiView_Page_Height))
            parentView.addSubview(emojiAdvanceView)
            emojiAdvanceView.setData(TIMConfig.shared.chatPopDetailGroups ?? [TUIFaceGroup]())
            if let delegateView = param?["TUICore_TUIChatExtension_ChatPopMenuReactRecentView_Delegate"] as? TUIChatPopMenu {
                emojiAdvanceView.delegateView = delegateView
            }
            emojiAdvanceView.alpha = 0
            emojiAdvanceView.faceCollectionView.isScrollEnabled = true
            emojiAdvanceView.faceCollectionView.delaysContentTouches = false
            emojiAdvanceView.backgroundColor = TUISwift.tuiChatDynamicColor("chat_pop_menu_bg_color", defaultColor: "#FFFFFF")
            emojiAdvanceView.faceCollectionView.backgroundColor = emojiAdvanceView.backgroundColor
            return true
        }
        // Classic: ChatMessageReactPreview
        else if extensionID == "TUICore_TUIChatExtension_ChatMessageReactPreview_ClassicExtensionID" {
            guard let delegateView = param?["TUICore_TUIChatExtension_ChatMessageReactPreview_Delegate"] as? TUIMessageCell else {
                return false
            }
            
            let cacheMap = (parentView.tui_extValueObj as? NSMutableDictionary) ?? NSMutableDictionary(capacity: 3)
            let key = NSStringFromClass(TUIReactPreview.self)
            if let cacheView = cacheMap[key] as? TUIReactPreview {
                cacheView.removeFromSuperview()
                cacheMap.removeObject(forKey: key)
            }
            
            let tagView = TUIReactPreview()
            parentView.addSubview(tagView)
            cacheMap[key] = tagView
            parentView.tui_extValueObj = cacheMap
            
            weak var weakSelf = self
            weak var weakTagView = tagView
            
            tagView.delegateCell = delegateView
            if delegateView.messageData?.reactdataProvider == nil {
                delegateView.messageData?.setupReactDataProvider()
            }
            delegateView.messageData?.reactValueChangedCallback = { tagsArray in
                if let weakTagView = weakTagView {
                    weakTagView.refreshByArray(tagsArray)
                }
            }
            
            if delegateView.messageData?.reactdataProvider?.reactArray.count ?? 0 > 0 {
                tagView.listArrM = delegateView.messageData?.reactdataProvider?.reactArray ?? [TUIReactModel]()
                tagView.updateView()
                if delegateView.messageData?.messageContainerAppendSize != .zero {
                    delegateView.messageData?.messageContainerAppendSize = tagView.frame.size
                    tagView.snp.remakeConstraints { make in
                        make.bottom.equalTo(parentView)
                        make.leading.equalTo(parentView)
                        make.width.equalTo(parentView)
                        make.height.equalTo(delegateView.messageData?.messageContainerAppendSize ?? .zero)
                    }
                } else {
                    delegateView.messageData?.messageContainerAppendSize = tagView.frame.size
                    tagView.notifyReactionChanged()
                }
            } else {
                // When invisible, if the height changes, reset the height
                if delegateView.messageData?.messageContainerAppendSize != .zero {
                    delegateView.messageData?.messageContainerAppendSize = .zero
                    tagView.notifyReactionChanged()
                }
            }
            
            tagView.emojiClickCallback = { _ in
                weakSelf?.emojiClick(view: parentView,
                                     reactMessage: delegateView.messageData ?? TUIMessageCellData(direction: .incoming),
                                     faceList: weakTagView?.listArrM ?? [])
            }
            tagView.userClickCallback = { _ in
                weakSelf?.emojiClick(view: parentView,
                                     reactMessage: delegateView.messageData ?? TUIMessageCellData(direction: .incoming),
                                     faceList: weakTagView?.listArrM ?? [])
            }
            
            return true
        }
        // Minimalist: ReactRecentView
        else if extensionID == "TUICore_TUIChatExtension_ChatPopMenuReactRecentView_MinimalistExtensionID" {
            if !TUIChatConfig.shared.enablePopMenuEmojiReactAction {
                return false
            }
            
            let emojiRecentView = TUIReactPopContextRecentView(frame: .zero)
            parentView.addSubview(emojiRecentView)
            emojiRecentView.frame = CGRect(x: 0,
                                           y: 0,
                                           width: max(kTIMDefaultEmojiSize.width * 8, parentView.mm_w),
                                           height: parentView.mm_h)
            emojiRecentView.backgroundColor = UIColor.white
            emojiRecentView.needShowbottomLine = true
            if let delegateVC = param?["TUICore_TUIChatExtension_ChatPopMenuReactRecentView_Delegate"] as? TUIChatPopContextController {
                emojiRecentView.delegateVC = delegateVC
            }
            return true
        }
        // Minimalist: ChatMessageReactPreview
        else if extensionID == "TUICore_TUIChatExtension_ChatMessageReactPreview_MinimalistExtensionID" {
            guard let delegateView = param?["TUICore_TUIChatExtension_ChatMessageReactPreview_Delegate"] as? TUIMessageCell else {
                return false
            }
            
            let cacheMap = (parentView.tui_extValueObj as? NSMutableDictionary) ?? NSMutableDictionary(capacity: 3)
            let key = NSStringFromClass(TUIReactPreview_Minimalist.self)
            if let cacheView = cacheMap[key] as? TUIReactPreview_Minimalist {
                cacheView.removeFromSuperview()
                cacheMap.removeObject(forKey: key)
            }
            let tagView = TUIReactPreview_Minimalist()
            parentView.addSubview(tagView)
            cacheMap[key] = tagView
            parentView.tui_extValueObj = cacheMap
            
            weak var weakSelf = self
            weak var weakTagView = tagView
            
            tagView.delegateCell = delegateView
            if delegateView.messageData?.reactdataProvider == nil {
                delegateView.messageData?.setupReactDataProvider()
            }
            delegateView.messageData?.reactValueChangedCallback = { tagsArray in
                weakTagView?.refreshByArray(tagsArray)
            }
            
            if delegateView.messageData?.reactdataProvider?.reactArray.count ?? 0 > 0 {
                tagView.reactlistArr = delegateView.messageData?.reactdataProvider?.reactArray ?? [TUIReactModel]()
                tagView.updateView()
                tagView.snp.remakeConstraints { make in
                    if delegateView.messageData?.direction == .incoming {
                        make.leading.greaterThanOrEqualTo(delegateView.container).offset(TUISwift.kScale390(16))
                    } else {
                        make.trailing.lessThanOrEqualTo(delegateView.container).offset(-TUISwift.kScale390(16))
                    }
                    make.width.equalTo(delegateView.container)
                    make.top.equalTo(delegateView.container.snp.bottom).offset(-4)
                    make.height.equalTo(20)
                }
                if delegateView.messageData?.messageContainerAppendSize == .zero {
                    weakTagView?.refreshByArray(delegateView.messageData?.reactdataProvider?.reactArray)
                }
            } else {
                if delegateView.messageData?.messageContainerAppendSize != .zero {
                    delegateView.messageData?.messageContainerAppendSize = .zero
                    weakTagView?.notifyReactionChanged()
                }
            }
            
            tagView.emojiClickCallback = { _ in
                weakSelf?.emojiClick(view: parentView,
                                     reactMessage: delegateView.messageData ?? TUIMessageCellData(direction: .incoming),
                                     faceList: weakTagView?.reactlistArr ?? [])
            }
            return true
        }
        return false
    }
    
    @objc func emojiClick(view: UIView, reactMessage data: TUIMessageCellData, faceList listModel: [TUIReactModel]) {
        let detailController = TUIReactMembersController()
        detailController.modalPresentationStyle = .custom
        detailController.tagsArray = listModel
        detailController.originData = data
        view.mm_viewController?.present(detailController, animated: true, completion: nil)
    }
    
    @objc func onLoginSucceeded() {
        TUIReactUtil.checkCommercialAbility()
    }
}
