import TIMCommon
import UIKit

typealias TUIFindContactViewControllerCallback = (TUIFindContactCellModel) -> Void

class TUIFindContactViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    var type: TUIFindContactType = .c2c
    var onSelect: TUIFindContactViewControllerCallback?

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "F3F4F5")
        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.textAlignment = TUISwift.isRTL() ? .right : .left
        if let searchField = searchBar.value(forKey: "searchField") as? UITextField {
            searchField.backgroundColor = TUISwift.timCommonDynamicColor("search_textfield_bg_color", defaultColor: "#FEFEFE")
        }
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("Search")
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "F3F4F5")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TUIFindContactCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.rowHeight = self.type == .c2c ? 72 : 94
        return tableView
    }()

    private let tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("contact_add_contact_tips_text_color", defaultColor: "#444444")
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textAlignment = .center
        return label
    }()

    private let noDataTipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("contact_add_contact_nodata_tips_text_color", defaultColor: "#999999")
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()

    private let provider = TUIFindContactViewDataProvider()

    deinit {
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("Cancel")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        var tipsLabelText = provider.getMyUserIDDescription()
        if type == .group {
            tipsLabelText = ""
        }
        tipsLabel.text = tipsLabelText
    }

    private func setupView() {
        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true

        let titleLabel = UILabel()
        titleLabel.text = (type == .c2c ? TUISwift.timCommonLocalizableString("TUIKitAddFriend") : TUISwift.timCommonLocalizableString("TUIKitAddGroup"))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        view.backgroundColor = searchBar.backgroundColor

        searchBar.delegate = self
        searchBar.frame = CGRect(x: 10, y: 0, width: view.bounds.size.width - 20, height: 60)
        searchBar.placeholder = type == .c2c ? TUISwift.timCommonLocalizableString("TUIKitSearchUserID") : TUISwift.timCommonLocalizableString("TUIKitSearchGroupID")
        view.addSubview(searchBar)

        tableView.frame = CGRect(x: 0, y: 60, width: view.bounds.size.width, height: view.bounds.size.height - 60)
        view.addSubview(tableView)

        tipsLabel.frame = CGRect(x: 10, y: 10, width: view.bounds.size.width - 20, height: 40)
        tableView.addSubview(tipsLabel)

        noDataTipsLabel.frame = CGRect(x: 10, y: 60, width: view.bounds.size.width - 20, height: 40)
        tableView.addSubview(noDataTipsLabel)
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = (type == .c2c ? provider.users.count : provider.groups.count)
        noDataTipsLabel.isHidden = !tipsLabel.isHidden || count > 0 || searchBar.text?.isEmpty == true
        noDataTipsLabel.text = (type == .c2c ? TUISwift.timCommonLocalizableString("TUIKitAddUserNoDataTips") : TUISwift.timCommonLocalizableString("TUIKitAddGroupNoDataTips"))
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TUIFindContactCell
        let result = (type == .c2c ? provider.users : provider.groups)
        let cellModel = result[indexPath.row]
        cell.data = cellModel
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let result = (type == .c2c ? provider.users : provider.groups)
        let cellModel = result[indexPath.row]
        onSelectCellModel(cellModel)
    }

    private func onSelectCellModel(_ cellModel: TUIFindContactCellModel) {
        onSelect?(cellModel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    // MARK: UISearchBarDelegate

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
        if type == .c2c{
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
