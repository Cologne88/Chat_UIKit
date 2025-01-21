//
//  SettingController.m
//  TUIKitDemo
//
//  Created by kennethmiao on 2018/10/19.
//  Copyright © 2018 Tencent. All rights reserved.
//

import TIMCommon
import TUIChat
import TUIContact
import TUICore
import UIKit

public let kEnableMsgReadStatus = "TUIKitDemo_EnableMsgReadStatus"
public let kEnableOnlineStatus = "TUIKitDemo_EnableOnlineStatus"
public let kEnableCallsRecord = "TUIKitDemo_EnableCallsRecord"

public class SettingController: UIViewController, TUISettingControllerDelegate, V2TIMSDKListener, UIActionSheetDelegate {
    private let titleView = TUINaviBarIndicatorView()
    public var lastLoginUser: String?
    var changeStyle: (() -> Void)?
    var changeTheme: (() -> Void)?
    public var confirmLogout: (() -> Void)?
    var viewWillAppearClosure: ((Bool) -> Void)?
    var showPersonalCell = true
    var showSelectStyleCell = false
    var showChangeThemeCell = false
    var showAboutIMCell = true
    var showLoginOutCell = true
    var showCallsRecordCell = true

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.showPersonalCell = true
        self.showAboutIMCell = true
        self.showLoginOutCell = true
        self.showCallsRecordCell = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewWillAppearClosure?(true)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillAppearClosure?(false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppTabBarItemMeText"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapTest(_:)))
        tap.numberOfTapsRequired = 5
        parent?.view.addGestureRecognizer(tap)

        let vc = TUISettingController()
        vc.lastLoginUser = lastLoginUser
        vc.delegate = self
        vc.aboutIMCellText = TUISwift.timCommonLocalizableString("TIMAppMeAbout")
        vc.showPersonalCell = showPersonalCell
        vc.showSelectStyleCell = showSelectStyleCell
        vc.showChangeThemeCell = showChangeThemeCell
        vc.showAboutIMCell = showAboutIMCell
        vc.showLoginOutCell = showLoginOutCell
        vc.showCallsRecordCell = showCallsRecordCell
        vc.view.frame = view.bounds
        addChild(vc)
        view.addSubview(vc.view)

        TUIChatConfig.shared.msgNeedReadReceipt = msgReadStatus()
        TUIConfig.default().displayOnlineStatusIcon = onlineStatus()
        vc.displayCallsRecord = UserDefaults.standard.bool(forKey: kEnableCallsRecord)
        vc.msgNeedReadReceipt = TUIChatConfig.shared.msgNeedReadReceipt
    }

    @objc func onTapTest(_ recognizer: UIGestureRecognizer) {
        // PRIVATEMARK
    }

    // MARK: TUISettingControllerDelegate

    public func onSwitchMsgReadStatus(_ isOn: Bool) {
        TUIChatConfig.shared.msgNeedReadReceipt = isOn
        UserDefaults.standard.set(isOn, forKey: kEnableMsgReadStatus)
        UserDefaults.standard.synchronize()
    }

    func msgReadStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kEnableMsgReadStatus)
    }

    public func onSwitchOnlineStatus(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: kEnableOnlineStatus)
        UserDefaults.standard.synchronize()
    }

    func onlineStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kEnableOnlineStatus)
    }

    public func onSwitchCallsRecord(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: kEnableCallsRecord)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(kEnableCallsRecord), object: isOn)
    }

    public func onClickAboutIM() {
        let vc = TUIAboutUsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    public func onChangeStyle() {
        changeStyle?()
    }

    public func onChangeTheme() {
        changeTheme?()
    }

    public func onClickLogout() {
        let alert = UIAlertController(title: TUISwift.timCommonLocalizableString("TIMAppConfirmLogout"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TIMAppCancel"), style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TIMAppConfirm"), style: .destructive, handler: { _ in
            self.didConfirmLogout()
        }))
        present(alert, animated: true, completion: nil)
    }

    func didConfirmLogout() {
        confirmLogout?()
    }
}
