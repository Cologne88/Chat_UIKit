import TIMCommon
import UIKit

class TUISearchResultListController: UIViewController, UITableViewDelegate, UITableViewDataSource, TUISearchBarDelegate, TUISearchResultDelegate {
    private var results = [TUISearchResultCellModel]()
    private var keyword: String?
    private var module: TUISearchResultModule
    private var param: [TUISearchParamKey: Any]?
    private var dataProvider: TUISearchDataProvider
    
    private var searchBar: TUISearchBar!
    private var tableView: UITableView!
    
    private var allowPageRequest = false
    private var pageIndex: UInt = 0
    
    init(results: [TUISearchResultCellModel]?, keyword: String?, module: TUISearchResultModule, param: [TUISearchParamKey: Any]?) {
        self.results = (module == .chatHistory) ? [] : (results ?? [])
        self.keyword = keyword
        self.module = module
        self.dataProvider = TUISearchDataProvider()
        self.param = param
        self.allowPageRequest = (module == .chatHistory)
        self.pageIndex = 0
        super.init(nibName: nil, bundle: nil)
        dataProvider.delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.backgroundColor = .groupTableViewBackground
        navigationController?.navigationBar.setBackgroundImage(imageWithColor(.groupTableViewBackground), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        view.backgroundColor = .groupTableViewBackground
        
        let image = UIImage.safeImage(TUISwift.timCommonImagePath("nav_back")).withRenderingMode(.alwaysOriginal).rtlImageFlippedForRightToLeftLayoutDirection()
        let back = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(back))
        navigationItem.leftBarButtonItems = [back]
        navigationItem.leftItemsSupplementBackButton = false
        
        searchBar = TUISearchBar()
        searchBar.setEntrance(false)
        searchBar.delegate = self
        searchBar.searchBar.text = keyword
        navigationItem.titleView = searchBar
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .groupTableViewBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = 60.0
        tableView.register(TUISearchResultCell.self, forCellReuseIdentifier: "cell")
        tableView.register(TUISearchResultHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "HFId")
        view.addSubview(tableView)
        
        if let text = searchBar.searchBar.text, module == .chatHistory {
            dataProvider.searchForKeyword(text, forModules: module, param: param)
        }
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = view.bounds
        searchBar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.backgroundColor = .groupTableViewBackground
        navigationController?.navigationBar.setBackgroundImage(imageWithColor(.groupTableViewBackground), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.backgroundColor = nil
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
    
    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TUISearchResultCell
        if indexPath.row < results.count {
            cell.fillWithData(results[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row < results.count {
            let cellModel = results[indexPath.row]
            onSelectModel(cellModel, module: module)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return results.isEmpty ? 0 : 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HFId") as! TUISearchResultHeaderFooterView
        headerView.isFooter = false
        headerView.title = titleForModule(module, isHeader: true)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
        searchBar.endEditing(true)
        
        if allowPageRequest && scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height {
            allowPageRequest = false
            var param = self.param ?? [:]
            param[TUISearchChatHistoryParamKeyPage] = pageIndex
            param[TUISearchChatHistoryParamKeyCount] = TUISearchDefaultPageSize
            self.param = param
            if let text = searchBar.searchBar.text {
                dataProvider.searchForKeyword(text, forModules: module, param: self.param)
            }
        }
    }
    
    private func onSelectModel(_ cellModel: TUISearchResultCellModel, module: TUISearchResultModule) {
        searchBar.endEditing(true)
        if module == .chatHistory {
            if let context = cellModel.context as? [String: Any] {
                let conversationId = context[kSearchChatHistoryConversationId] as? String
                let conversation = context[kSearchChatHistoryConverationInfo] as? V2TIMConversation
                let msgs = context[kSearchChatHistoryConversationMsgs] as? [V2TIMMessage]
                if msgs?.count == 1 {
                    let title = cellModel.title ?? cellModel.titleAttributeString?.string
                    let param: [String: Any] = [
                        "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_UserID": conversation?.userID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": conversation?.groupID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_HighlightKeyword": searchBar.searchBar.text ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_LocateMessage": msgs?.first ?? ""
                    ]
                    navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Classic", param: param, forResult: nil)
                    return
                }
                
                var results = [TUISearchResultCellModel]()
                for message in msgs ?? [] {
                    let model = TUISearchResultCellModel()
                    model.title = message.nickName ?? message.sender
                    let desc = TUISearchDataProvider.matchedText(forMessage: message, withKey: searchBar.searchBar.text ?? "")
                    model.detailsAttributeString = TUISearchDataProvider.attributeString(withText: desc, key: searchBar.searchBar.text ?? "")
                    model.avatarUrl = message.faceURL
                    model.groupType = conversation?.groupID
                    model.avatarImage = conversation?.type == .C2C ? TUISwift.defaultAvatarImage() : TUISwift.defaultGroupAvatarImage(byGroupType: conversation?.groupType)
                    model.context = message
                    results.append(model)
                }
                let vc = TUISearchResultListController(results: results, keyword: searchBar.searchBar.text, module: module, param: [TUISearchChatHistoryParamKeyConversationId: conversationId ?? ""])
                navigationController?.pushViewController(vc, animated: true)
                return
            } else {
                if let message = cellModel.context as? V2TIMMessage {
                    var title = message.userID ?? ""
                    if let cellTitle = cellModel.title, !cellTitle.isEmpty {
                        title = cellTitle
                    }
                    
                    let param: [String: Any] = [
                        "TUICore_TUIChatObjectFactory_ChatViewController_Title": title,
                        "TUICore_TUIChatObjectFactory_ChatViewController_UserID": message.userID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": message.groupID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_HighlightKeyword": searchBar.searchBar.text ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_LocateMessage": message
                    ]
                    
                    navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Classic", param: param, forResult: nil)
                    return
                }
            }
        }
        
        var param: [String: Any]?
        let title = cellModel.title ?? cellModel.titleAttributeString?.string
        if module == .contact, let friend = cellModel.context as? V2TIMFriendInfo {
            param = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_UserID": friend.userID ?? ""
            ]
        }
        
        if module == .group, let group = cellModel.context as? V2TIMGroupInfo {
            param = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": group.groupID ?? ""
            ]
        }
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Classic", param: param, forResult: nil)
    }
    
    // MARK: - TUISearchBarDelegate

    func searchBarDidCancelClicked(_ searchBar: TUISearchBar) {
        dismiss(animated: false, completion: nil)
    }
    
    func searchBar(_ searchBar: TUISearchBar, searchText key: String) {
        results.removeAll()
        allowPageRequest = true
        pageIndex = 0
        var param = self.param ?? [:]
        param[TUISearchChatHistoryParamKeyPage] = pageIndex
        self.param = param
        
        dataProvider.searchForKeyword(key, forModules: module, param: self.param)
    }

    func onSearchError(_ errMsg: String) {
        print("search error: \(errMsg)")
    }
    
    // MARK: - TUISearchResultDelegate

    func onSearchResults(_ results: [Int: [TUISearchResultCellModel]], forModules modules: TUISearchResultModule) {
        let arrayM = results[modules.rawValue] ?? []
        self.results.append(contentsOf: arrayM)
        tableView.reloadData()
        
        allowPageRequest = (arrayM.count >= TUISearchDefaultPageSize)
        pageIndex = (arrayM.count < TUISearchDefaultPageSize) ? pageIndex : pageIndex + 1
    }
    
    func searchBarDidEnterSearch(_ searchBar: TUISearchBar) {}
        
    private func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
