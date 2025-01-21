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

public let kEnableMsgReadStatus_mini = "TUIKitDemo_EnableMsgReadStatus"
public let kEnableOnlineStatus_mini = "TUIKitDemo_EnableOnlineStatus"
public let kEnableCallsRecord_mini = "TUIKitDemo_EnableCallsRecord_mini"

public class SettingController_Minimalist: UIViewController, TUISettingControllerDelegate_Minimalist, V2TIMSDKListener, UIActionSheetDelegate {
    private let titleView = TUINaviBarIndicatorView()
    public var lastLoginUser: String?
    var setting: Observable<TUISettingController_Minimalist?> = Observable(TUISettingController_Minimalist(style: .plain))
    var showLeftBarButtonItems: Observable<[UIBarButtonItem]> = Observable([])
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

    private func navBackColor() -> UIColor {
        return .white
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = nil
            appearance.backgroundEffect = nil
            appearance.backgroundColor = navBackColor()
            let navigationBar = navigationController?.navigationBar
            navigationBar?.backgroundColor = navBackColor()
            navigationBar?.barTintColor = navBackColor()
            navigationBar?.shadowImage = UIImage()
            navigationBar?.standardAppearance = appearance
            navigationBar?.scrollEdgeAppearance = appearance
        } else {
            let navigationBar = navigationController?.navigationBar
            navigationBar?.backgroundColor = navBackColor()
            navigationBar?.barTintColor = navBackColor()
            navigationBar?.shadowImage = UIImage()
        }
        viewWillAppearClosure?(true)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillAppearClosure?(false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapTest(_:)))
        tap.numberOfTapsRequired = 5
        parent?.view.addGestureRecognizer(tap)

        setting.value?.lastLoginUser = lastLoginUser
        setting.value?.delegate = self
        setting.value?.aboutIMCellText = TUISwift.timCommonLocalizableString("TIMAppMeAbout")
        setting.value?.showPersonalCell = showPersonalCell
        setting.value?.showSelectStyleCell = showSelectStyleCell
        setting.value?.showChangeThemeCell = showChangeThemeCell
        setting.value?.showAboutIMCell = showAboutIMCell
        setting.value?.showLoginOutCell = showLoginOutCell
        setting.value?.showCallsRecordCell = showCallsRecordCell
        if setting.value?.view.frame.size.width == 0 {
            setting.value?.view.frame = view.bounds
        }
        addChild(setting.value!)
        view.addSubview(setting.value!.view)

        TUIChatConfig.shared.msgNeedReadReceipt = msgReadStatus()
        TUIConfig.default().displayOnlineStatusIcon = onlineStatus()
        setting.value?.displayCallsRecord = UserDefaults.standard.bool(forKey: kEnableCallsRecord_mini)
        setting.value?.msgNeedReadReceipt = TUIChatConfig.shared.msgNeedReadReceipt
    }

    private func setupNavigation() {
        titleView.label.font = UIFont.boldSystemFont(ofSize: 34)
        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppTabBarItemSettingText_mini"))
        titleView.label.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")

        let leftTitleItem = UIBarButtonItem(customView: titleView)
        let leftSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        leftSpaceItem.width = TUISwift.kScale390(13)
        showLeftBarButtonItems.value = [leftSpaceItem, leftTitleItem]

        navigationItem.title = ""
        navigationItem.leftBarButtonItems = showLeftBarButtonItems.value
    }

    @objc private func onTapTest(_ recognizer: UIGestureRecognizer) {
        // PRIVATEMARK
    }

    // MARK: TUISettingControllerDelegate_Minimalist

    public func onSwitchMsgReadStatus(_ isOn: Bool) {
        TUIChatConfig.shared.msgNeedReadReceipt = isOn
        UserDefaults.standard.set(isOn, forKey: kEnableMsgReadStatus_mini)
        UserDefaults.standard.synchronize()
    }

    private func msgReadStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kEnableMsgReadStatus_mini)
    }

    public func onSwitchOnlineStatus(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: kEnableOnlineStatus_mini)
        UserDefaults.standard.synchronize()
    }

    private func onlineStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: kEnableOnlineStatus_mini)
    }

    public func onSwitchCallsRecord(_ isOn: Bool) {
        UserDefaults.standard.set(isOn, forKey: kEnableCallsRecord_mini)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(kEnableCallsRecord_mini), object: isOn)
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
        alert.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TIMAppCancel"), style: .default, handler: nil))
        alert.tuitheme_addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("TIMAppConfirm"), style: .destructive, handler: { [weak self] _ in
            self?.didConfirmLogout()
        }))
        present(alert, animated: true, completion: nil)
    }

    private func didConfirmLogout() {
        confirmLogout?()
    }
}
