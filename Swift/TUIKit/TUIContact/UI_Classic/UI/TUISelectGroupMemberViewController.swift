import TIMCommon
import UIKit

let kUserBorder = 44.0
let kUserSpacing = 2.0
let kUserPanelLeftSpacing = 15.0

class TUISelectGroupMemberViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    var groupId: String?
    var name: String?
    var selectedFinished: (([TUIUserModel]) -> Void)?
    var optionalStyle: TUISelectMemberOptionalStyle = .none
    var selectedUserIDList: [String]?
    var userData: String?
    
    private var cancelBtn: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        button.setTitleColor(TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000"), for: .normal)
        return button
    }()
    
    private var doneBtn: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setTitle(TUISwift.timCommonLocalizableString("Done"), for: .normal)
        button.alpha = 0.5
        button.setTitleColor(TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000"), for: .normal)
        return button
    }()
    
    private lazy var userPanel: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TUIMemberPanelCell.self, forCellWithReuseIdentifier: "TUIMemberPanelCell")
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = true
        } else {
            // Fallback on earlier versions
        }
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentMode = .scaleAspectFit
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var selectTable: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(TUISelectGroupMemberCell.self, forCellReuseIdentifier: "TUISelectGroupMemberCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private var indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var selectedUsers: [TUIUserModel] = []
    private var memberList: [TUIUserModel] = []
    private var pageIndex: Int = 0
    private var isNoData: Bool = false
    
    private var topStartPosition: CGFloat = 0
    
    deinit {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getMembers()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = name ?? TUISwift.timCommonLocalizableString("Make_a_call")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelBtn)
        doneBtn.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: doneBtn)
        
        var topPadding: CGFloat = 44.0
        if #available(iOS 11.0, *) {
            topPadding = TUITool.applicationKeywindow()?.safeAreaInsets.top ?? 44.0
        }
        
        topPadding = max(26, topPadding)
        let navBarHeight = navigationController?.navigationBar.bounds.size.height ?? 44.0
        topStartPosition = topPadding + navBarHeight
        
        view.addSubview(userPanel)
        view.addSubview(selectTable)
        selectTable.mm_width(view.mm_w).mm_top(topStartPosition + 10).mm_flexToBottom(0)
        
        // Layout userPanel and selectTable
        userPanel.translatesAutoresizingMaskIntoConstraints = false
        selectTable.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userPanel.topAnchor.constraint(equalTo: view.topAnchor, constant: topStartPosition),
            userPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            userPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            userPanel.heightAnchor.constraint(equalToConstant: userPanelHeight),
            
            selectTable.topAnchor.constraint(equalTo: userPanel.bottomAnchor),
            selectTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            selectTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            selectTable.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func onNext() {
        guard !selectedUsers.isEmpty else {
            return
        }
        var users: [TUIUserModel] = []
        for model in selectedUsers {
            users.append(model.copy() as! TUIUserModel)
        }
        if let selectedFinished = selectedFinished {
            cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                selectedFinished(users)
            }
        }
        if optionalStyle == .transferOwner {
            cancel()
            return
        }
        cancel()
        
        if navigateValueCallback != nil {
            navigateValueCallback!(["TUICore_TUIContactObjectFactory_SelectGroupMemberVC_ResultUserList": users])
        }
    }
    
    @objc private func cancel() {
        if isModal {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private var isModal: Bool {
        if let navigationController = navigationController {
            let viewControllers = navigationController.viewControllers
            if viewControllers.count > 1 && viewControllers.last == self {
                return false
            }
        }
        return true
    }
    
    private func getMembers() {
        getMembersWithOptionalStyle()
        loadData { [weak self] success, _, datas in
            guard let self = self else { return }
            if success {
                self.memberList.append(contentsOf: datas)
                self.selectTable.reloadData()
            }
        }
    }
    
    private func loadData(completion: @escaping (Bool, String?, [TUIUserModel]) -> Void) {
        if isNoData {
            completion(true, "there is no more data", [])
            return
        }
        guard let groupId = groupId else { return }
        V2TIMManager.sharedInstance().getGroupMemberList(groupId, filter: UInt32(V2TIMGroupMemberFilter.GROUP_MEMBER_FILTER_ALL.rawValue), nextSeq: UInt64(pageIndex)) { [weak self] nextSeq, memberList in
            guard let self = self, let memberList = memberList else { return }
            self.pageIndex = Int(nextSeq)
            self.isNoData = (nextSeq == 0)
            var arrayM: [TUIUserModel] = []
            for info in memberList {
                if info.userID == V2TIMManager.sharedInstance().getLoginUser() {
                    continue
                }
                if self.optionalStyle.contains(.publicMan) {
                    let isSuper = (info.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue))
                    let isAdmin = (info.role == UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_ADMIN.rawValue))
                    if isSuper || isAdmin {
                        continue
                    }
                }
                
                if let selectedUserIDList = self.selectedUserIDList,
                   let userID = info.userID,
                   selectedUserIDList.contains(userID)
                {
                    continue
                }
                
                let model = TUIUserModel()
                model.userId = info.userID ?? ""
                model.name = info.nameCard ?? info.friendRemark ?? info.nickName ?? info.userID ?? ""
                model.avatar = info.faceURL ?? ""
                arrayM.append(model)
            }
            completion(true, nil, arrayM)
        } fail: { _, desc in
            completion(false, desc, [])
        }
    }
    
    private func getMembersWithOptionalStyle() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.getMembersWithOptionalStyle()
            }
            return
        }
        
        if optionalStyle == .none {
            return
        }
        
        if optionalStyle.contains(.atAll) {
            let model = TUIUserModel()
            model.userId = kImSDK_MesssageAtALL
            model.name = TUISwift.timCommonLocalizableString("All")
            memberList.append(model)
        }
    }
    
    private func isUserSelected(_ user: TUIUserModel) -> Bool {
        return selectedUsers.contains { $0.userId == user.userId && $0.userId != V2TIMManager.sharedInstance().getLoginUser() }
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TUISelectGroupMemberCell", for: indexPath) as! TUISelectGroupMemberCell
        if indexPath.row < memberList.count {
            let model = memberList[indexPath.row]
            let isSelect = isUserSelected(model)
            cell.fill(with: model, isSelect: isSelect)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let footer = view as? UITableViewHeaderFooterView {
            footer.textLabel?.textColor = UIColor.d_systemGray()
            footer.textLabel?.font = UIFont.systemFont(ofSize: 14)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return TUISwift.timCommonLocalizableString("TUIKitGroupProfileMember")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var isSelected = false
        var userSelected = TUIUserModel()
        if indexPath.row < memberList.count {
            let user = memberList[indexPath.row]
            isSelected = isUserSelected(user)
            userSelected = user.copy() as! TUIUserModel
        }
        
        if userSelected.userId.isEmpty {
            return
        }
        
        if userSelected.userId == kImSDK_MesssageAtALL {
            selectedUsers.removeAll()
            selectedUsers.append(userSelected)
            onNext()
            return
        }
        
        if optionalStyle == .transferOwner {
            selectedUsers.removeAll()
        }
        
        if isSelected {
            selectedUsers.removeAll { $0.userId == userSelected.userId }
        } else {
            selectedUsers.append(userSelected)
        }
        updateUserPanel()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && (scrollView.contentOffset.y >= scrollView.bounds.origin.y) {
            if indicatorView.isAnimating {
                return
            }
            indicatorView.startAnimating()
            
            loadData { [weak self] success, _, datas in
                guard let self = self else { return }
                self.indicatorView.stopAnimating()
                if !success {
                    return
                }
                self.memberList.append(contentsOf: datas)
                self.selectTable.reloadData()
                self.selectTable.layoutIfNeeded()
                if datas.isEmpty {
                    self.selectTable.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - CGFloat(TMessageController_Header_Height)), animated: true)
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDelegate & UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TUIMemberPanelCell", for: indexPath) as! TUIMemberPanelCell
        if indexPath.row < selectedUsers.count {
            cell.fillWithData(selectedUsers[indexPath.row])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: kUserBorder, height: kUserBorder)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if indexPath.row < selectedUsers.count {
            // to do
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateUserPanel() {
        userPanel.mm_height(userPanelHeight).mm_left(CGFloat(kUserPanelLeftSpacing)).mm_flexToRight(0).mm_top(topStartPosition)
        selectTable.mm_width(view.mm_w).mm_top(userPanel.mm_maxY).mm_flexToBottom(0)
        
        userPanel.performBatchUpdates({
            self.userPanel.reloadSections(IndexSet(integer: 0))
        }, completion: nil)
        
        selectTable.reloadData()
        doneBtn.alpha = (selectedUsers.count == 0 ? 0.5 : 1)
    }
    
    private var userPanelColumnCount: Int {
        guard !selectedUsers.isEmpty else { return 0 }
        let totalWidth = view.frame.width - kUserPanelLeftSpacing
        return Int(totalWidth / (kUserBorder + kUserSpacing))
    }
    
    private var realSpacing: CGFloat {
        let totalWidth = view.frame.width - kUserPanelLeftSpacing
        guard userPanelColumnCount > 1 else { return 0 }
        return (totalWidth - CGFloat(userPanelColumnCount) * kUserBorder) / CGFloat(userPanelColumnCount - 1)
    }
    
    private var userPanelRowCount: Int {
        let userCount = selectedUsers.count
        let columnCount = max(userPanelColumnCount, 1)
        var rowCount = userCount / columnCount
        if userCount % columnCount != 0 {
            rowCount += 1
        }
        return rowCount
    }
    
    private var userPanelWidth: CGFloat {
        return CGFloat(userPanelColumnCount) * kUserBorder + (CGFloat(userPanelColumnCount) - 1) * realSpacing
    }

    private var userPanelHeight: CGFloat {
        return CGFloat(userPanelRowCount) * kUserBorder + (CGFloat(userPanelRowCount) - 1) * realSpacing
    }
}
