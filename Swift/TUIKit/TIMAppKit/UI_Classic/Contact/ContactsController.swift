//
//  ContactsController.m
//  TUIKitDemo
//
//  Created by annidyfeng on 2019/3/25.
//  Copyright © 2019 kennethmiao. All rights reserved.
//

import TIMCommon
import TUIContact
import TUICore
import UIKit

public class ContactsController: UIViewController, TUIPopViewDelegate {
    var viewWillAppear: ((Bool) -> Void)?
    var contactVC: TUIContactController?
    var titleView: TUINaviBarIndicatorView?

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewWillAppear?(true)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillAppear?(false)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        moreButton.setImage(TUISwift.tuiCoreDynamicImage("nav_more_img", defaultImage: UIImage.safeImage(TUISwift.tuiCoreImagePath("more"))), for: .normal)
        moreButton.addTarget(self, action: #selector(onRightItem(_:)), for: .touchUpInside)
        moreButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        moreButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let moreItem = UIBarButtonItem(customView: moreButton)
        navigationItem.rightBarButtonItem = moreItem

        titleView = TUINaviBarIndicatorView()
        titleView?.setTitle(TUISwift.timCommonLocalizableString("TIMAppTabBarItemContactText"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        contactVC = TUIContactController()
        if let contactVC = contactVC {
            addChild(contactVC)
            view.addSubview(contactVC.view)
        }
    }

    @objc func onRightItem(_ rightBarButton: UIButton) {
        var menus = [TUIPopCellData]()
        let friend = TUIPopCellData()
        friend.image = TUISwift.tuiContactDynamicImage("pop_icon_add_friend_img", defaultImage: UIImage.safeImage(TUISwift.tuiContactImagePath("add_friend")))
        friend.title = TUISwift.timCommonLocalizableString("ContactsAddFriends")
        menus.append(friend)

        let group = TUIPopCellData()
        group.image = TUISwift.tuiContactDynamicImage("pop_icon_add_group_img", defaultImage: UIImage.safeImage(TUISwift.tuiContactImagePath("add_group")))
        group.title = TUISwift.timCommonLocalizableString("ContactsJoinGroup")
        menus.append(group)

        let height = TUIPopCell.getHeight() * CGFloat(menus.count) + TUISwift.tuiPopView_Arrow_Size().height
        let orginY = TUISwift.statusBar_Height() + TUISwift.navBar_Height()
        var orginX = TUISwift.screen_Width() - 140
        if TUISwift.isRTL() {
            orginX = 10
        }
        let popView = TUIPopView(frame: CGRect(x: orginX, y: orginY, width: 130, height: height))
        if let frameInNaviView = navigationController?.view.convert(rightBarButton.frame, from: rightBarButton.superview) {
            popView.arrowPoint = CGPoint(x: frameInNaviView.origin.x + frameInNaviView.size.width * 0.5, y: orginY)
        }
        popView.delegate = self
        popView.setData(menus)
        if let window = view.window {
            popView.showInWindow(window)
        }
    }

    public func popView(_ popView: TUIPopView, didSelectRowAt index: Int) {
        contactVC?.addToContactsOrGroups(type: index == 0 ? TUIFindContactType.c2c : TUIFindContactType.group)
    }
}
