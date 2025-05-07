//
//  TUITabBarController.m
//  TUIKit
//
//  Created by kennethmiao on 2018/11/13.
//  Copyright © 2018 Tencent. All rights reserved.
//

import TIMCommon
import TUICore
import UIKit

public class TUITabBarItem {
    public init() {}
    public var normalImage: UIImage?
    public var selectedImage: UIImage?
    public var title: String?
    public var controller: UIViewController?
    public var badgeView: TUIBadgeView?
    public var identity: String?
}

public class TUITabBarController: UITabBarController {
    public var tabBarItems: [TUITabBarItem] = []

    override public func viewDidLoad() {
        super.viewDidLoad()

        TUITool.applicationKeywindow()?.backgroundColor = UIColor.white

        tabBar.backgroundColor = backgroudColor
        tabBar.backgroundImage = UIImage()
        tabBar.tintColor = selectTextColor
        tabBar.barTintColor = backgroudColor
        tabBar.shadowImage = UIImage()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            NotificationCenter.default.post(name: NSNotification.Name("TUITabBarControllerViewDidLoad"), object: nil)
        }
    }

    public func setTabBarItems(_ tabBarItems: [TUITabBarItem]) {
        self.tabBarItems = tabBarItems
        var controllers: [UIViewController] = []
        for item in tabBarItems {
            if let controller = item.controller {
                controller.tabBarItem = UITabBarItem(
                    title: item.title,
                    image: item.normalImage?.withRenderingMode(.alwaysOriginal),
                    selectedImage: item.selectedImage?.withRenderingMode(.alwaysOriginal)
                )
                controller.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -4)
                controllers.append(controller)
            }
        }
        viewControllers = controllers
    }

    var backgroudColor: UIColor {
        return TUISwift.tuiDemoDynamicColor("tab_bg_color", defaultColor: "#EBF0F6")
    }

    var selectTextColor: UIColor {
        return TUISwift.tuiDemoDynamicColor("tab_title_text_select_color", defaultColor: "#147AFF")
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // tabbar
        // Cause of increasing tabbar height
        let height = TUISwift.tabBar_Height() + 8
        let newFrame = CGRect(x: 0, y: view.frame.size.height - height, width: view.frame.size.width, height: height)
        tabBar.frame = newFrame
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for item in tabBarItems {
            if let tabItemView = getTabBarContentView(item.controller?.tabBarItem) {
                let frame = tabBar.convert(tabItemView.frame, from: tabItemView.superview)
                if TUISwift.isRTL() {
                    item.badgeView?.center = CGPoint(x: frame.minX, y: frame.origin.y)
                } else {
                    item.badgeView?.center = CGPoint(x: frame.maxX, y: frame.origin.y)
                }
                if let badgeView = item.badgeView {
                    tabBar.addSubview(badgeView)
                }
            }
        }
    }

    public func layoutBadgeViewIfNeeded() {
        weak var weakSelf = self
        DispatchQueue.main.async {
            guard let strongSelf = weakSelf else { return }
            for item in strongSelf.tabBarItems {
                if let tabItemView = strongSelf.getTabBarContentView(item.controller?.tabBarItem) {
                    let frame = strongSelf.tabBar.convert(tabItemView.frame, from: tabItemView.superview)
                    if TUISwift.isRTL() {
                        item.badgeView?.center = CGPoint(x: frame.minX, y: frame.origin.y)
                    } else {
                        item.badgeView?.center = CGPoint(x: frame.maxX, y: frame.origin.y)
                    }
                    item.badgeView?.removeFromSuperview()
                    if let badgeView = item.badgeView {
                        strongSelf.tabBar.addSubview(badgeView)
                    }
                }
            }
        }
    }

    func getTabBarContentView(_ tabBarItem: UITabBarItem?) -> UIView? {
        guard let bottomView = tabBarItem?.value(forKeyPath: "_view") as? UIView else { return nil }
        var contentView = bottomView
        for subview in bottomView.subviews {
            if subview.isKind(of: NSClassFromString("UITabBarSwappableImageView")!) {
                contentView = subview
                break
            }
        }
        return contentView
    }
}
