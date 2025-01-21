//  AppDelegate+Redpoint.swift
//  TUIKitDemo

import Foundation
import ImSDK_Plus
import ReactiveObjC
import TIMAppKit
import TIMCommon
import TUICore
import UIKit

var _markUnreadCount: Int = 0
var _markHideUnreadCount: Int = 0
private var markUnreadMapKey: UInt8 = 0

extension AppDelegateLoader {
    @objc class func swiftLoad() {
        AppDelegate.sharedInstance.swiftLoad()
    }
}

extension AppDelegate {
    var markUnreadMap: [String: Any]? {
        get {
            return objc_getAssociatedObject(self, &markUnreadMapKey) as? [String: Any]
        }
        set {
            objc_setAssociatedObject(self, &markUnreadMapKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func swiftLoad() {
        // The Processing of unread count
        // - 1. Hooking the callback of entering foreground and background in AppDelegate to set the application's badge number.
        // - 2. Hooking the event of onTotalUnreadMessageCountChanged: in AppDelegate to set the application's badge number and update the _unReadCount parameter.

        let appDidEnterBackGroundBlock: @convention(block) (AspectInfo, UIApplication) -> Void = { _, application in
            if let app = application.delegate as? AppDelegate {
                application.applicationIconBadgeNumber = Int(app.unReadCount)
                print("[Redpoint] applicationDidEnterBackground, unReadCount:\(app.unReadCount)")
            }
        }

        do {
            try AppDelegate.aspect_hook(#selector(UIApplicationDelegate.applicationDidEnterBackground(_:)),
                                        with: [],
                                        usingBlock: appDidEnterBackGroundBlock)
        } catch {
            print("Error occurred: \(error)")
        }

        let appWillEnterForegroupBlock: @convention(block) (AspectInfo, UIApplication) -> Void = { _, application in
            if let app = application.delegate as? AppDelegate {
                application.applicationIconBadgeNumber = Int(app.unReadCount)
                print("[Redpoint] applicationWillEnterForeground, unReadCount:\(app.unReadCount)")
            }
        }

        do {
            try AppDelegate.aspect_hook(#selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
                                        with: [],
                                        usingBlock: appWillEnterForegroupBlock)
        } catch {
            print("Error occurred: \(error)")
        }

        let onTotalUnreadMessageChangedBlock: @convention(block) (AspectInfo, UInt64) -> Void = { _, totalUnreadCount in
            if let app = UIApplication.shared.delegate as? AppDelegate {
                let unreadCalculationResults = AppDelegate.caculateRealResultAboutSDKTotalCount(totalCount: totalUnreadCount, markUnreadCount: _markUnreadCount, markHideUnreadCount: _markHideUnreadCount)
                app.onTotalUnreadCountChanged(UInt64(unreadCalculationResults))
                print("[Redpoint] onTotalUnreadMessageCountChanged, unReadCount:\(app.unReadCount)")
            }
        }

        do {
            try AppDelegate.aspect_hook(#selector(onTotalUnreadMessageCountChanged(_:)),
                                        with: [],
                                        usingBlock: onTotalUnreadMessageChangedBlock)
        } catch {
            print("Error occurred: \(error)")
        }

        // Listen for unread clearing notifications
        NotificationCenter.default.addObserver(self, selector: #selector(redpoint_clearUnreadMessage), name: NSNotification.Name("redpoint_clearUnreadMessage"), object: nil)
    }

    @objc func redpoint_setupTotalUnreadCount() {
        print("[Redpoint] \(#function)")
        // Getting total unread count
        V2TIMManager.sharedInstance().getTotalUnreadMessageCount { [weak self] totalCount in
            self?.onTotalUnreadCountChanged(totalCount)
        } fail: { _, _ in
            // Handle failure
        }

        // Getting the count of friends application
        pendencyCntObservation = contactDataProvider.observe(\.pendencyCnt, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let cnt = change.newValue else { return }
            self.onFriendApplicationCountChanged(Int(cnt))
        }

        contactDataProvider.loadFriendApplication()
    }

    func onTotalUnreadCountChanged(_ totalUnreadCount: UInt64) {
        print("[Redpoint] \(#function), \(totalUnreadCount)")

        let total = totalUnreadCount

        guard let tab = TUITool.applicationKeywindow()?.rootViewController as? TUITabBarController else {
            return
        }
        let item = tab.tabBarItems.first as? TUITabBarItem
        item?.badgeView?.title = total > 0 ? (total > 99 ? "99+" : "\(total)") : ""
        unReadCount = total
    }

    @objc func redpoint_clearUnreadMessage() {
        print("[Redpoint] \(#function)")
        V2TIMManager.sharedInstance().cleanConversationUnreadMessageCount("", cleanTimestamp: 0, cleanSequence: 0) { [weak self] in
            TUITool.makeToast(NSLocalizedString("MarkAllMessageAsReadSucc", comment: ""))
            self?.onTotalUnreadCountChanged(0)
        } fail: { [weak self] code, desc in
            TUITool.makeToast(String(format: NSLocalizedString("MarkAllMessageAsReadErrFormat", comment: ""), code, desc ?? ""))
            self?.onTotalUnreadCountChanged(self?.unReadCount ?? 0)
        }

        if let conversations = markUnreadMap?.keys {
            V2TIMManager.sharedInstance().markConversation(Array(conversations), markType: NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_UNREAD.rawValue), enableMark: false, succ: nil, fail: nil)
        }
    }

    func onFriendApplicationCountChanged(_ applicationCount: Int) {
        print("[Redpoint] \(#function), \(applicationCount)")
        guard let tab = TUITool.applicationKeywindow()?.rootViewController as? TUITabBarController else {
            return
        }
        guard tab.tabBarItems.count >= 2 else {
            return
        }
        var contactItem: TUITabBarItem?
        for item in tab.tabBarItems {
            if (item as TUITabBarItem).identity == "contactItem" {
                contactItem = item as? TUITabBarItem
                break
            }
        }
        contactItem?.badgeView?.title = applicationCount == 0 ? "" : "\(applicationCount)"
    }

    @objc func updateMarkUnreadCount(_ note: Notification) {
        guard let userInfo = note.userInfo else { return }
        let markUnreadCount = userInfo[TUIKitNotification_onConversationMarkUnreadCountChanged_MarkUnreadCount] as? Int ?? 0
        let markHideUnreadCount = userInfo[TUIKitNotification_onConversationMarkUnreadCountChanged_MarkHideUnreadCount] as? Int ?? 0
        _markUnreadCount = markUnreadCount
        _markHideUnreadCount = markHideUnreadCount
        if let markUnreadMap = userInfo[TUIKitNotification_onConversationMarkUnreadCountChanged_MarkUnreadMap] as? [String: Any] {
            self.markUnreadMap = markUnreadMap
        }
        V2TIMManager.sharedInstance().getTotalUnreadMessageCount { [weak self] totalCount in
            let unreadCalculationResults = AppDelegate.caculateRealResultAboutSDKTotalCount(totalCount: totalCount, markUnreadCount: markUnreadCount, markHideUnreadCount: markHideUnreadCount)
            self?.onTotalUnreadCountChanged(UInt64(unreadCalculationResults))
        } fail: { _, _ in
            // Handle failure
        }
    }

    static func caculateRealResultAboutSDKTotalCount(totalCount: UInt64, markUnreadCount: Int, markHideUnreadCount: Int) -> Int {
        var unreadCalculationResults = Int(totalCount) + markUnreadCount - markHideUnreadCount
        if unreadCalculationResults < 0 {
            // error protect
            unreadCalculationResults = 0
        }
        return unreadCalculationResults
    }

    func onSetAPPUnreadCount() -> UInt32 {
        return UInt32(unReadCount) // test
    }
}
