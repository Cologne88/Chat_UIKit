import TIMCommon
import TUICore
import UIKit

class TUISearchResultListController_Minimalist: UIViewController, UITableViewDelegate, UITableViewDataSource, TUISearchBarDelegate_Minimalist, TUISearchResultDelegate {
    var headerConversationShowName: String?
    var headerConversationURL: String?
    var headerConversationAvatar: UIImage?
    
    private var results: [TUISearchResultCellModel] = []
    private var keyword: String?
    private var module: TUISearchResultModule
    private var param: [TUISearchParamKey: Any]?
    private var dataProvider: TUISearchDataProvider
    
    private var searchBar: TUISearchBar_Minimalist!
    private var tableView: UITableView!
    private var noDataEmptyView: TUISearchEmptyView_Minimalist!
    
    private var allowPageRequest: Bool = false
    private var pageIndex: Int = 0
    
    private static let cellId = "cell"
    private static let headerFooterId = "HFId"
    private static let historyHeaderFooterId = "HistoryHFId"
    
    init(results: [TUISearchResultCellModel]?, keyword: String?, module: TUISearchResultModule, param: [TUISearchParamKey: Any]?) {
        self.results = (module == .chatHistory) ? [] : results ?? []
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
        
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(imageWithColor(.white), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        view.backgroundColor = .white
        
        let image = UIImage.safeImage(TUISwift.timCommonImagePath("nav_back")).withRenderingMode(.alwaysOriginal).imageFlippedForRightToLeftLayoutDirection()
        let back = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(back))
        navigationItem.leftBarButtonItems = [back]
        navigationItem.leftItemsSupplementBackButton = false
        
        searchBar = TUISearchBar_Minimalist()
        searchBar.setEntrance(false)
        searchBar.delegate = self
        searchBar.searchBar.text = keyword
        navigationItem.titleView = searchBar
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.rowHeight = 60.0
        tableView.register(TUISearchResultCell_Minimalist.self, forCellReuseIdentifier: TUISearchResultListController_Minimalist.cellId)
        tableView.register(TUISearchResultHeaderFooterView_Minimalist.self, forHeaderFooterViewReuseIdentifier: TUISearchResultListController_Minimalist.headerFooterId)
        tableView.register(TUISearchChatHistoryResultHeaderView_Minimalist.self, forHeaderFooterViewReuseIdentifier: TUISearchResultListController_Minimalist.historyHeaderFooterId)
        view.addSubview(tableView)
        
        noDataEmptyView = TUISearchEmptyView_Minimalist(image: TUISwift.tuiSearchBundleThemeImage("", defaultImage: "search_not_found_icon"), text: TUISwift.timCommonLocalizableString("TUIKitSearchNoResultLists"))
        noDataEmptyView.isHidden = true
        noDataEmptyView.frame = CGRect(x: 0, y: TUISwift.kScale390(42), width: view.bounds.size.width - 20, height: 200)
        tableView.addSubview(noDataEmptyView)
        
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
        searchBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.setBackgroundImage(imageWithColor(.white), for: .default)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: TUISearchResultListController_Minimalist.cellId, for: indexPath) as! TUISearchResultCell_Minimalist
        if indexPath.row >= results.count {
            return cell
        }
        let model = results[indexPath.row]
        model.avatarType = .TAvatarTypeRadiusCorner
        cell.fillWithData(model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row >= results.count {
            return
        }
        let cellModel = results[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! TUISearchResultCell_Minimalist
        
        if module == .chatHistory {
            cellModel.avatarImage = headerConversationAvatar ?? cell.avatarView.image
            cellModel.title = headerConversationShowName ?? cell.title_label.text
        } else {
            cellModel.avatarImage = cell.avatarView.image
            cellModel.title = cell.title_label.text
        }
        onSelectModel(cellModel, module: module)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if module == .chatHistory {
            if results.isEmpty {
                return 0
            } else {
                let cellModel = results[0]
                if cellModel.context is NSDictionary {
                    return 0
                } else {
                    return TUISwift.kScale390(64)
                }
            }
        } else {
            return results.isEmpty ? 0 : 30
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if module == .chatHistory {
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TUISearchResultListController_Minimalist.historyHeaderFooterId) as! TUISearchChatHistoryResultHeaderView_Minimalist
            let cellModel = results[0]
            headerView.configPlaceHolderImage(headerConversationAvatar ?? UIImage(), imgUrl: headerConversationURL ?? "", text: headerConversationShowName ?? "")
            headerView.onTap = { [weak self] in
                self?.headerViewJump2ChatViewController(cellModel)
            }
            return headerView
        } else {
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TUISearchResultListController_Minimalist.headerFooterId) as! TUISearchResultHeaderFooterView_Minimalist
            headerView.showMoreBtn = false
            headerView.title = titleForModule(module, isHeader: true)
            headerView.isFooter = false
            return headerView
        }
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
                dataProvider.searchForKeyword(text, forModules: module, param: param)
            }
        }
    }
    
    private func headerViewJump2ChatViewController(_ cellModel: TUISearchResultCellModel) {
        if let message = cellModel.context as? V2TIMMessage {
            var title = message.userID
            if let name = headerConversationShowName, !name.isEmpty {
                title = headerConversationShowName
            }
            let param: [String: Any] = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_UserID": message.userID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": message.groupID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": headerConversationAvatar ?? UIImage(),
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": headerConversationURL ?? ""
            ]
            navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
        } else if let convInfo = cellModel.context as? NSDictionary {
            let conversation = convInfo[kSearchChatHistoryConverationInfo] as! V2TIMConversation
            var title = cellModel.title ?? cellModel.titleAttributeString?.string
            if let name = headerConversationShowName, !name.isEmpty {
                title = headerConversationShowName
            }
            let param: [String: Any] = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_UserID": conversation.userID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": conversation.groupID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": headerConversationAvatar ?? UIImage(),
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": headerConversationURL ?? ""
            ]
            navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
        }
    }
    
    private func onSelectModel(_ cellModel: TUISearchResultCellModel, module: TUISearchResultModule) {
        searchBar.endEditing(true)
        if module == .chatHistory {
            if !(cellModel.context is NSDictionary) {
                if let message = cellModel.context as? V2TIMMessage {
                    var title = message.userID
                    if let modelTitle = cellModel.title, !modelTitle.isEmpty {
                        title = modelTitle
                    }
                    let param: [String: Any] = [
                        "TUICore_TUIChatObjectFactory_ChatViewController_Title": title ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_UserID": message.userID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": message.groupID ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": cellModel.avatarImage ?? UIImage(),
                        "TUICore_TUIChatObjectFactory_ChatViewController_HighlightKeyword": searchBar.searchBar.text ?? "",
                        "TUICore_TUIChatObjectFactory_ChatViewController_LocateMessage": message
                    ]
                    navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
                    return
                }
                return
            }
            let convInfo = cellModel.context as! NSDictionary
            let conversationId = convInfo[kSearchChatHistoryConversationId] as! String
            let conversation = convInfo[kSearchChatHistoryConverationInfo] as! V2TIMConversation
            let msgs = convInfo[kSearchChatHistoryConversationMsgs] as! [V2TIMMessage]
            
            var results: [TUISearchResultCellModel] = []
            for message in msgs {
                let model = TUISearchResultCellModel()
                model.title = message.nickName ?? message.sender
                if let text = searchBar.searchBar.text {
                    let desc = TUISearchDataProvider.matchedText(forMessage: message, withKey: text)
                    model.detailsAttributeString = TUISearchDataProvider.attributeString(withText: desc, key: text)
                }
             
                model.avatarUrl = message.faceURL
                model.groupType = conversation.groupID
                model.avatarImage = conversation.type == .C2C ? TUISwift.defaultAvatarImage() : TUISwift.defaultGroupAvatarImage(byGroupType: conversation.groupType)
                model.context = message
                results.append(model)
            }
            let vc = TUISearchResultListController_Minimalist(results: results, keyword: searchBar.searchBar.text, module: module, param: [TUISearchChatHistoryParamKeyConversationId: conversationId])
            vc.headerConversationAvatar = cellModel.avatarImage
            vc.headerConversationShowName = cellModel.title
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        var param: [String: Any]? = nil
        let title = cellModel.title ?? cellModel.titleAttributeString?.string ?? ""
        if module == .contact, let friend = cellModel.context as? V2TIMFriendInfo {
            param = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title,
                "TUICore_TUIChatObjectFactory_ChatViewController_UserID": friend.userID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": cellModel.avatarImage ?? UIImage()
            ]
        }
        
        if module == .group, let group = cellModel.context as? V2TIMGroupInfo {
            param = [
                "TUICore_TUIChatObjectFactory_ChatViewController_Title": title,
                "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": group.groupID ?? "",
                "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": cellModel.avatarImage ?? UIImage()
            ]
        }
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
    }
    
    // MARK: - TUISearchBarDelegate

    func searchBarDidCancelClicked(_ searchBar: TUISearchBar_Minimalist) {
        dismiss(animated: false, completion: nil)
    }
    
    func searchBar(_ searchBar: TUISearchBar_Minimalist, searchText key: String) {
        results.removeAll()
        allowPageRequest = true
        pageIndex = 0
        var param = self.param ?? [:]
        param[TUISearchChatHistoryParamKeyPage] = pageIndex
        self.param = param
        
        dataProvider.searchForKeyword(key, forModules: module, param: param)
    }
    
    func searchBarDidEnterSearch(_ searchBar: TUISearchBar_Minimalist) {}
        
    // MARK: - TUISearchResultDelegate

    func onSearchResults(_ results: [Int: [TUISearchResultCellModel]], forModules modules: TUISearchResultModule) {
        let arrayM = results[modules.rawValue] ?? []
        noDataEmptyView.isHidden = true
        if arrayM.isEmpty && self.results.isEmpty {
            noDataEmptyView.isHidden = false
            if searchBar.searchBar.text?.isEmpty ?? true {
                noDataEmptyView.isHidden = true
            }
        }
        
        self.results.append(contentsOf: arrayM)
        tableView.reloadData()
        
        allowPageRequest = (arrayM.count >= TUISearchDefaultPageSize)
        pageIndex = (arrayM.count < TUISearchDefaultPageSize) ? pageIndex : pageIndex + 1
    }
    
    func onSearchError(_ errMsg: String) {
        print("search error: \(errMsg)")
    }
    
    private func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
}
