import TIMCommon
import TUICore
import UIKit

@objc protocol TUIContactControllerListener: NSObjectProtocol {
    @objc optional func onSelectFriend(_ cell: TUICommonContactCell)
    @objc optional func onAddNewFriend(_ cell: TUICommonTableViewCell)
    @objc optional func onGroupConversation(_ cell: TUICommonTableViewCell)
}

let kContactCellReuseId = "ContactCellReuseId"
let kContactActionCellReuseId = "ContactActionCellReuseId"

public class TUIContactController: UIViewController, UITableViewDelegate, UITableViewDataSource, V2TIMFriendshipListener, TUIPopViewDelegate {
    weak var delegate: TUIContactControllerListener?
    var tableView: UITableView?
    private var firstGroupData: [TUIContactActionCellData] = []
    var isLoadFinishedObservation: NSKeyValueObservation?
    var pendencyCntObservation: NSKeyValueObservation?

    lazy var viewModel: TUIContactViewDataProvider = {
        let viewModel = TUIContactViewDataProvider()
        viewModel.loadContacts()
        return viewModel
    }()

    deinit {
        isLoadFinishedObservation = nil
        pendencyCntObservation = nil
        NotificationCenter.default.removeObserver(self)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        var list: [TUIContactActionCellData] = []
        list.append({
            let data = TUIContactActionCellData()
            data.icon = TUISwift.tuiContactDynamicImage("contact_new_friend_img", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("new_friend")))
            data.title = TUISwift.timCommonLocalizableString("TUIKitContactsNewFriends")
            data.cselector = #selector(onAddNewFriend(_:))
            return data
        }())
        list.append({
            let data = TUIContactActionCellData()
            data.icon = TUISwift.tuiContactDynamicImage("contact_public_group_img", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("public_group")))
            data.title = TUISwift.timCommonLocalizableString("TUIKitContactsGroupChats")
            data.cselector = #selector(onGroupConversation(_:))
            return data
        }())
        list.append({
            let data = TUIContactActionCellData()
            data.icon = TUISwift.tuiContactDynamicImage("contact_blacklist_img", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("blacklist")))
            data.title = TUISwift.timCommonLocalizableString("TUIKitContactsBlackList")
            data.cselector = #selector(onBlackList(_:))
            return data
        }())

        addExtensionsToList(list: &list)
        firstGroupData = list

        setupNavigator()
        setupViews()

        NotificationCenter.default.addObserver(self, selector: #selector(onLoginSucceeded), name: NSNotification.Name(NSNotification.Name.TUILoginSuccess.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFriendInfoChanged), name: NSNotification.Name("FriendInfoChangedNotification"), object: nil)
    }

    private func addExtensionsToList(list: inout [TUIContactActionCellData]) {
        let param: [String: Any] = [TUICore_TUIContactExtension_ContactMenu_Nav: navigationController as Any]
        let extensionList = TUICore.getExtensionList(TUICore_TUIContactExtension_ContactMenu_ClassicExtensionID, param: param)
        let sortedExtensionList = extensionList.sorted { $0.weight > $1.weight }
        for info in sortedExtensionList {
            list.append({
                let data = TUIContactActionCellData()
                data.icon = info.icon
                data.title = info.text ?? ""
                data.cselector = #selector(onExtensionClicked(_:))
                data.onClicked = { param in
                    info.onClicked?(param ?? [:])
                }
                return data
            }())
        }
    }

    @objc private func onLoginSucceeded() {
        viewModel.loadContacts()
    }

    @objc private func onFriendInfoChanged() {
        viewModel.loadContacts()
    }

    private func setupNavigator() {
        let moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        moreButton.setImage(TUISwift.timCommonDynamicImage("nav_more_img", defaultImage: UIImage(named: TUISwift.timCommonImagePath("more"))), for: .normal)
        moreButton.addTarget(self, action: #selector(onRightItem(_:)), for: .touchUpInside)
        moreButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        moreButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let moreItem = UIBarButtonItem(customView: moreButton)
        navigationItem.rightBarButtonItem = moreItem

        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func setupViews() {
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        let rect = view.bounds
        tableView = UITableView(frame: rect, style: .plain)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.sectionIndexBackgroundColor = .clear
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView?.sectionIndexColor = .darkGray
        tableView?.backgroundColor = view.backgroundColor

        tableView?.delaysContentTouches = false
        if #available(iOS 15.0, *) {
            tableView?.sectionHeaderTopPadding = 0
        }
        view.addSubview(tableView!)

        let v = UIView(frame: .zero)
        tableView?.tableFooterView = v
        tableView?.separatorInset = UIEdgeInsets(top: 0, left: 58, bottom: 0, right: 0)
        tableView?.register(TUICommonContactCell.self, forCellReuseIdentifier: kContactCellReuseId)
        tableView?.register(TUIContactActionCell.self, forCellReuseIdentifier: kContactActionCellReuseId)

        isLoadFinishedObservation = viewModel.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let finished = change.newValue else { return }
            if finished {
                self.tableView?.reloadData()
            }
        }
        pendencyCntObservation = viewModel.observe(\.pendencyCnt, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let cnt = change.newValue else { return }
            self.firstGroupData[0].readNum = Int(cnt)
        }
    }

    @objc private func onRightItem(_ rightBarButton: UIButton) {
        var menus: [TUIPopCellData] = []
        let friend = TUIPopCellData()
        friend.image = TUISwift.tuiDemoDynamicImage("pop_icon_add_friend_img", defaultImage: UIImage(named: TUISwift.tuiDemoImagePath("add_friend")))
        friend.title = TUISwift.timCommonLocalizableString("ContactsAddFriends")
        menus.append(friend)

        let group = TUIPopCellData()
        group.image = TUISwift.tuiDemoDynamicImage("pop_icon_add_group_img", defaultImage: UIImage(named: TUISwift.tuiDemoImagePath("add_group")))
        group.title = TUISwift.timCommonLocalizableString("ContactsJoinGroup")
        menus.append(group)

        let height = TUIPopCell.getHeight() * CGFloat(menus.count) + TUISwift.tuiPopView_Arrow_Size().height
        let orginY = TUISwift.statusBar_Height() + TUISwift.navBar_Height()
        var orginX = TUISwift.screen_Width() - 140
        if TUISwift.isRTL() {
            orginX = 10
        }
        let popView = TUIPopView(frame: CGRect(x: orginX, y: orginY, width: 130, height: height))
        let frameInNaviView = navigationController?.view.convert(rightBarButton.frame, from: rightBarButton.superview)
        popView.arrowPoint = CGPoint(x: frameInNaviView?.origin.x ?? 0 + (frameInNaviView?.size.width ?? 0) * 0.5, y: orginY)
        popView.delegate = self
        popView.setData(menus as! NSMutableArray)
        popView.show(in: view.window!)
    }

    public func popView(_ popView: TUIPopView, didSelectRowAt index: Int) {
        addToContactsOrGroups(type: index == 0 ? .c2c : .group)
    }

    public func addToContactsOrGroups(type: TUIFindContactType) {
        let add = TUIFindContactViewController()
        add.type = type
        add.onSelect = { [weak self] cellModel in
            guard let self = self else { return }
            if cellModel.type == .c2c {
                let frc = TUIFriendRequestViewController()
                frc.profile = cellModel.userInfo
                self.navigationController?.popViewController(animated: false)
                self.navigationController?.pushViewController(frc, animated: true)
            } else {
                let param: [String: Any] = [TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod_GroupInfoKey: cellModel.groupInfo as Any]
                if let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetGroupRequestViewControllerMethod, param: param) as? UIViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        navigationController?.pushViewController(add, animated: true)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.groupList.count + 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return firstGroupData.count
        } else {
            let group = viewModel.groupList[section - 1]
            if let list = viewModel.dataDict[group] {
                return list.count
            }
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return nil }

        let headerViewId = "ContactDrawerView"
        var headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerViewId)
        if headerView == nil {
            headerView = UITableViewHeaderFooterView(reuseIdentifier: headerViewId)
            let textLabel = UILabel(frame: .zero)
            textLabel.tag = 1
            textLabel.font = UIFont.systemFont(ofSize: 16)
            textLabel.textColor = TUISwift.rgb(0x80, green: 0x80, blue: 0x80)
            textLabel.rtlAlignment = .leading
            headerView?.addSubview(textLabel)
            textLabel.snp.remakeConstraints { make in
                make.leading.equalTo(headerView!.snp.leading).offset(12)
                make.top.bottom.trailing.equalTo(headerView!)
            }
        }
        let label = headerView?.viewWithTag(1) as? UILabel
        label?.text = viewModel.groupList[section - 1]
        headerView?.contentView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        return headerView
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 33
    }

    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var array = [""]
        array.append(contentsOf: viewModel.groupList)
        return array
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactActionCellReuseId, for: indexPath) as! TUIContactActionCell
            cell.fill(withData: firstGroupData[indexPath.row])
            cell.changeColorWhenTouched = true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactCellReuseId, for: indexPath) as! TUICommonContactCell
            let group = viewModel.groupList[indexPath.section - 1]
            let list = viewModel.dataDict[group] ?? []
            let data = list[indexPath.row]
            data.cselector = #selector(onSelectFriend(_:))
            cell.fill(with: data)
            cell.changeColorWhenTouched = true
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Implement selection logic if needed
    }

    @objc private func onSelectFriend(_ cell: TUICommonContactCell) {
        if let delegate = delegate, delegate.responds(to: #selector(TUIContactControllerListener.onSelectFriend(_:))) {
            delegate.onSelectFriend?(cell)
            return
        }
        let data = cell.contactData
        let vc = TUIFriendProfileController(style: .grouped)
        vc.friendProfile = data?.friendProfile
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onAddNewFriend(_ cell: TUICommonTableViewCell) {
        if let delegate = delegate, delegate.responds(to: #selector(TUIContactControllerListener.onAddNewFriend(_:))) {
            delegate.onAddNewFriend?(cell)
            return
        }
        let vc = TUINewFriendViewController()
        vc.cellClickBlock = { [weak self] cell in
            guard let self = self else { return }
            let controller = TUIUserProfileController(style: .grouped)
            if let pendencyData = cell.pendencyData {
                V2TIMManager.sharedInstance().getUsersInfo([pendencyData.identifier]) { [weak self] profiles in
                    guard let self = self else { return }
                    guard let profiles = profiles else { return }
                    controller.userFullInfo = profiles.first
                    controller.pendency = cell.pendencyData
                    controller.actionType = .PCA_PENDENDY_CONFIRM
                    self.navigationController?.pushViewController(controller, animated: true)
                } fail: { _, _ in }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
        viewModel.clearApplicationCnt()
    }

    @objc private func onGroupConversation(_ cell: TUICommonTableViewCell) {
        if let delegate = delegate, delegate.responds(to: #selector(TUIContactControllerListener.onGroupConversation(_:))) {
            delegate.onGroupConversation?(cell)
            return
        }
        let vc = TUIGroupConversationListController()
        vc.onSelect = { [weak self] cellData in
            guard let self = self else { return }
            let param: [String: Any] = [TUICore_TUIChatObjectFactory_ChatViewController_GroupID: cellData.identifier ?? ""]
            self.navigationController?.push(TUICore_TUIChatObjectFactory_ChatViewController_Classic, param: param, forResult: nil)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onBlackList(_ cell: TUICommonContactCell) {
        let vc = TUIBlackListController()
        vc.didSelectCellBlock = { [weak self] cell in
            guard let self = self else { return }
            self.onSelectFriend(cell)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onExtensionClicked(_ cell: TUIContactActionCell) {
        cell.actionData?.onClicked?(nil)
    }

    private func runSelector(_ selector: Selector, withObject object: Any?) {
        if responds(to: selector) {
            perform(selector, with: object)
        }
    }
}

class IUContactView: UIView {
    var view: UIView

    override init(frame: CGRect) {
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        super.init(frame: frame)
        addSubview(view)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
