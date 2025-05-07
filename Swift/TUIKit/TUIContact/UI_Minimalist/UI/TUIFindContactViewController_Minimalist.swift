// TUIFindContactViewController_Minimalist.swift
// TUIContact

import TIMCommon
import TUICore
import UIKit

class TUIFindContactViewController_Minimalist: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, TUIFloatSubViewControllerProtocol {
    var floatDataSourceChanged: (([Any]) -> Void)?
    
    var type: TUIFindContactType_Minimalist = .C2C_Minimalist
    var onSelect: ((TUIFindContactCellModel_Minimalist) -> Void)?

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9")
        searchBar.placeholder = (type == .C2C_Minimalist ? TUISwift.timCommonLocalizableString("TUIKitSearchUserID") : TUISwift.timCommonLocalizableString("TUIKitSearchGroupID"))
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.searchTextField.textAlignment = TUISwift.isRTL() ? .right : .left
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9")
        }
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("Search")
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TUIFindContactCell_Minimalist.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.rowHeight = (type == .C2C_Minimalist ? TUISwift.kScale390(63) : TUISwift.kScale390(93))
        return tableView
    }()

    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.tuiContactDynamicColor("contact_add_contact_tips_text_color", defaultColor: "#444444")
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var noDataEmptyView: TUIContactEmptyView_Minimalist = {
        let view = TUIContactEmptyView_Minimalist(
            image: UIImage.safeImage(TUISwift.tuiContactImagePath_Minimalist("contact_not_found_icon")),
            text: type == .C2C_Minimalist ? TUISwift.timCommonLocalizableString("TUIKitAddUserNoDataTips") : TUISwift.timCommonLocalizableString("TUIKitAddGroupNoDataTips")
        )
        view.isHidden = true
        return view
    }()

    private lazy var provider: TUIFindContactViewDataProvider_Minimalist = .init()

    deinit {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("Cancel")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        let tipsLabelText = provider.getMyUserIDDescription()
        tipsLabel.text = (type == .Group_Minimalist ? "" : tipsLabelText)
    }

    private func setupView() {
        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true

        let titleLabel = UILabel()
        titleLabel.text = (type == .C2C_Minimalist ? TUISwift.timCommonLocalizableString("TUIKitAddFriend") : TUISwift.timCommonLocalizableString("TUIKitAddGroup"))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        view.backgroundColor = .white

        searchBar.frame = CGRect(x: 10, y: 0, width: view.bounds.size.width - 20, height: TUISwift.kScale390(38))
        searchBar.layer.cornerRadius = TUISwift.kScale390(10)
        searchBar.layer.masksToBounds = true
        view.addSubview(searchBar)

        tableView.frame = CGRect(x: 0, y: 60, width: view.bounds.size.width, height: view.bounds.size.height - 60)
        view.addSubview(tableView)

        tipsLabel.frame = CGRect(x: 10, y: 10, width: view.bounds.size.width - 20, height: 40)
        tableView.addSubview(tipsLabel)

        noDataEmptyView.frame = CGRect(x: 0, y: TUISwift.kScale390(42), width: view.bounds.size.width - 20, height: 200)
        tableView.addSubview(noDataEmptyView)
    }

    // MARK: - UITableViewDelegate/UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (type == .C2C_Minimalist ? provider.users.count : provider.groups.count)
        noDataEmptyView.isHidden = !tipsLabel.isHidden || count > 0 || searchBar.text?.isEmpty == true
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TUIFindContactCell_Minimalist
        let result = (type == .C2C_Minimalist ? provider.users : provider.groups)
        let cellModel = result[indexPath.row]
        cell.data = cellModel
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let result = (type == .C2C_Minimalist ? provider.users : provider.groups)
        let cellModel = result[indexPath.row]
        onSelectCellModel(cellModel)
    }

    private func onSelectCellModel(_ cellModel: TUIFindContactCellModel_Minimalist) {
        onSelect?(cellModel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    // MARK: - UISearchBarDelegate

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        doSearch(withKeyword: searchBar.text)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            provider.clear()
            tableView.reloadData()
        }
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        tipsLabel.isHidden = true
        return true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        doSearch(withKeyword: searchBar.text)
    }

    private func doSearch(withKeyword keyword: String?) {
        guard let keyword = keyword else { return }
        if type == .C2C_Minimalist {
            provider.findUser(userID: keyword) { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        } else {
            provider.findGroup(groupID: keyword) { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
    }
}
