//  ContactsController_Minimalist.m
//  TIMAppKit

import TIMCommon
import TUIContact
import UIKit

public class ContactsController_Minimalist: UIViewController, TUIPopViewDelegate {
    private let titleView = TUINaviBarIndicatorView()
    public var contact: Observable<TUIContactController_Minimalist?> = Observable(TUIContactController_Minimalist())
    public var showLeftBarButtonItems: Observable<[UIBarButtonItem]> = Observable([])
    public var showRightBarButtonItems: Observable<[UIBarButtonItem]> = Observable([])
    var viewWillAppearClosure: ((Bool) -> Void)?

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        if let contact = contact.value {
            addChild(contact)
            view.addSubview(contact.view)
        }
    }

    private func navBackColor() -> UIColor {
        return .white
    }

    private func setupNavigation() {
        titleView.label.font = UIFont.boldSystemFont(ofSize: 34)
        titleView.maxLabelLength = TUISwift.screen_Width()
        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppTabBarItemContactText_mini"))
        titleView.label.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")

        let leftTitleItem = UIBarButtonItem(customView: titleView)
        let leftSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        leftSpaceItem.width = TUISwift.kScale390(13)
        showLeftBarButtonItems.value = [leftSpaceItem, leftTitleItem]

        navigationItem.title = ""
        navigationItem.leftBarButtonItems = showLeftBarButtonItems.value

        let moreButton = UIButton(type: .custom)
        moreButton.setImage(UIImage.safeImage(TUISwift.tuiConversationImagePath_Minimalist("nav_add")), for: .normal)
        moreButton.addTarget(self, action: #selector(onRightItem(_:)), for: .touchUpInside)
        moreButton.imageView?.contentMode = .scaleAspectFit
        moreButton.frame = CGRect(x: 0, y: 0, width: 26, height: 26)

        let moreItem = UIBarButtonItem(customView: moreButton)
        showRightBarButtonItems.value = [moreItem]
        navigationItem.rightBarButtonItems = showRightBarButtonItems.value
    }

    @objc private func onRightItem(_ rightBarButton: UIButton) {
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
        if let frameInNaviView = rightBarButton.superview?.convert(rightBarButton.frame, to: navigationController?.view) {
            popView.arrowPoint = CGPoint(x: frameInNaviView.origin.x + frameInNaviView.size.width * 0.5, y: orginY)
        }
        popView.delegate = self
        popView.setData(menus)
        if let window = view.window {
            popView.showInWindow(window)
        }
    }

    public func popView(_ popView: TUIPopView, didSelectRowAt index: Int) {
        if index == 0 {
            contact.value?.addToContacts()
        } else {
            contact.value?.addGroups()
        }
    }
}
