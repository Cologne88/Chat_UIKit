import TIMCommon
import TUICore
import UIKit

let gConversationCell_ReuseId: String = "TConversationCell"

@objc protocol TUIConversationTableViewDelegate: NSObjectProtocol {
    @objc optional func tableViewDidScroll(_ offsetY: CGFloat)
    @objc optional func tableViewDidSelectCell(_ data: TUIConversationCellData)
    @objc optional func tableViewDidShowAlert(_ ac: UIAlertController)
}

class TUIConversationTableView: UITableView, UITableViewDelegate, UITableViewDataSource, TUIConversationListDataProviderDelegate {
    weak var convDelegate: TUIConversationTableViewDelegate?
    var _dataProvider: TUIConversationListBaseDataProvider?
    var unreadCountChanged: ((Int, Int) -> Void)?
    var tipsMsgWhenNoConversation: String?
    var disableMoreActionExtension = false
    
    private var hideMarkReadAction = false
    private var hideDeleteAction = false
    private var hideHideAction = false
    private var customizedItems: [UIAlertAction] = []
    
    lazy var tipsView: UIImageView = {
        let tipsView = UIImageView()
        tipsView.image = TUISwift.tuiConversationDynamicImage("no_conversation_img", defaultImage: UIImage(named: TUISwift.tuiConversationImagePath("no_conversation")))
        tipsView.isHidden = true
        return tipsView
    }()
    
    lazy var tipsLabel: UILabel = {
        let tipsLabel = UILabel()
        tipsLabel.textColor = TUISwift.timCommonDynamicColor("nodata_tips_color", defaultColor: "#999999")
        tipsLabel.font = UIFont.systemFont(ofSize: 14.0)
        tipsLabel.textAlignment = .center
        tipsLabel.isHidden = true
        return tipsLabel
    }()
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTableView()
    }
    
    private func setupTableView() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = TUISwift.tuiConversationDynamicColor("conversation_bg_color", defaultColor: "#FFFFFF")
        tableFooterView = UIView()
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        register(TUIConversationCell.self, forCellReuseIdentifier: gConversationCell_ReuseId)
        estimatedRowHeight = TConversationCell_Height
        rowHeight = TConversationCell_Height
        delaysContentTouches = false
        separatorColor = TUISwift.tuiConversationDynamicColor("separator_color", defaultColor: "#DBDBDB")
        delegate = self
        dataSource = self
        addSubview(tipsView)
        addSubview(tipsLabel)
        disableMoreActionExtension = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(onFriendInfoChanged(_:)), name: NSNotification.Name("FriendInfoChangedNotification"), object: nil)
    }
    
    @objc private func onFriendInfoChanged(_ notice: Notification) {
        guard let friendInfo = notice.object as? V2TIMFriendInfo else { return }
        for cellData in dataProvider.conversationList {
            if cellData.userID == friendInfo.userID, let userFullInfo = friendInfo.userFullInfo {
                cellData.title.value = friendInfo.friendRemark ?? userFullInfo.nickName ?? friendInfo.userID ?? ""
                reloadData()
                break
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tipsView.mm_width()(128)!.mm_height()(109)!.mm__centerX()(mm_centerX)!.mm__centerY()(mm_centerY - 60)
        tipsLabel.mm_width()(300)!.mm_height()(20)!.mm__centerX()(mm_centerX)!.mm_top()(tipsView.mm_maxY + 18)
    }
    
    private func updateTipsViewStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.dataProvider.conversationList.count == 0 {
                self.tipsView.isHidden = false
                self.tipsLabel.isHidden = false
                self.tipsLabel.text = self.tipsMsgWhenNoConversation
            } else {
                self.tipsView.isHidden = true
                self.tipsLabel.isHidden = true
            }
        }
    }
    
    var dataProvider: TUIConversationListBaseDataProvider {
        get {
            return _dataProvider ?? TUIConversationListBaseDataProvider()
        }
        set {
            _dataProvider = newValue
            _dataProvider?.delegate = self
            _dataProvider?.loadNexPageConversations()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: TUIConversationListDataProviderDelegate

    func insertConversations(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.insertConversations(at: indexPaths)
            }
            return
        }
        UIView.performWithoutAnimation {
            self.insertRows(at: indexPaths, with: .none)
        }
    }
    
    func reloadConversations(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadConversations(at: indexPaths)
            }
            return
        }
        if isEditing {
            isEditing = false
        }
        UIView.performWithoutAnimation {
            self.reloadRows(at: indexPaths, with: .none)
        }
    }
    
    func deleteConversation(at indexPaths: [IndexPath]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.deleteConversation(at: indexPaths)
            }
            return
        }
        deleteRows(at: indexPaths, with: .none)
    }
    
    func reloadAllConversations() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.reloadAllConversations()
            }
            return
        }
        reloadData()
    }
    
    func updateMarkUnreadCount(_ markUnreadCount: Int, markHideUnreadCount: Int) {
        if let unreadCountChanged = unreadCountChanged {
            unreadCountChanged(markUnreadCount, markHideUnreadCount)
        }
    }
    
    func parseActionHiddenTagAndCustomizedItems(_ cellData: TUIConversationCellData) {
        guard let dataSource = TUIConversationConfig.sharedConfig.moreMenuDataSource else { return }
        if (dataSource.responds(to: Selector(("conversationShouldHideItemsInMoreMenu")))) != nil {
            let flag = dataSource.conversationShouldHideItemsInMoreMenu(cellData)
            hideDeleteAction = ((flag.rawValue & TUIConversationItemInMoreMenu.Delete.rawValue) != 0)
            hideMarkReadAction = ((flag.rawValue & TUIConversationItemInMoreMenu.MarkRead.rawValue) != 0)
            hideHideAction = ((flag.rawValue & TUIConversationItemInMoreMenu.Hide.rawValue) != 0)
        }
        if (dataSource.responds(to: Selector(("conversationShouldAddNewItemsToMoreMenu")))) != nil {
            if let items = dataSource.conversationShouldAddNewItemsToMoreMenu(cellData) as? [UIAlertAction], items.count > 0 {
                customizedItems = items
            }
        }
    }
    
    // MARK: - Table view data source

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dataProvider.loadNexPageConversations()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        if let convDelegate = convDelegate, convDelegate.responds(to: #selector(TUIConversationTableViewDelegate.tableViewDidScroll(_:))) {
            convDelegate.tableViewDidScroll!(offsetY)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateTipsViewStatus()
        return dataProvider.conversationList.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cellData = dataProvider.conversationList[indexPath.row]
        var rowActions: [UITableViewRowAction] = []
        parseActionHiddenTagAndCustomizedItems(cellData)
        
        if cellData.isLocalConversationFoldList {
            let markHideAction = UITableViewRowAction(style: .default, title: TUISwift.timCommonLocalizableString("MarkHide")) { _, _ in
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_HideFoldItem(true)
                }
            }
            markHideAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            if !hideHideAction {
                rowActions.append(markHideAction)
            }
            return rowActions
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: TUISwift.timCommonLocalizableString("Delete")) { _, _ in
            let cancelBtnInfo = TUISecondConfirmBtnInfo()
            cancelBtnInfo.tile = TUISwift.timCommonLocalizableString("Cancel")
            cancelBtnInfo.click = { [weak self] in
                guard let self = self else { return }
                self.isEditing = false
            }
            let confirmBtnInfo = TUISecondConfirmBtnInfo()
            confirmBtnInfo.tile = TUISwift.timCommonLocalizableString("Delete")
            confirmBtnInfo.click = { [weak self] in
                guard let self = self else { return }
                self.dataProvider.removeConversation(cellData)
                self.isEditing = false
            }
            TUISecondConfirm.show(TUISwift.timCommonLocalizableString("TUIKitConversationTipsDelete"), cancel: cancelBtnInfo, confirmBtnInfo: confirmBtnInfo)
        }
        deleteAction.backgroundColor = TUISwift.rgb(242, green: 77, blue: 76)
        if !hideDeleteAction {
            rowActions.append(deleteAction)
        }
        
        let markAsReadAction = UITableViewRowAction(style: .default, title: cellData.isMarkAsUnread || cellData.unreadCount > 0 ? TUISwift.timCommonLocalizableString("MarkAsRead") : TUISwift.timCommonLocalizableString("MarkAsUnRead")) { _, _ in
            if cellData.isMarkAsUnread || cellData.unreadCount > 0 {
                self.dataProvider.markConversationAsRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_FoldItemIsUnread(false)
                }
            } else {
                self.dataProvider.markConversationAsUnRead(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_FoldItemIsUnread(true)
                }
            }
        }
        markAsReadAction.backgroundColor = TUISwift.rgb(20, green: 122, blue: 255)
        if !hideMarkReadAction {
            rowActions.append(markAsReadAction)
        }
        
        let moreExtensionList = TUICore.getExtensionList(TUICore_TUIConversationExtension_ConversationCellMoreAction_ClassicExtensionID, param: [
            TUICore_TUIConversationExtension_ConversationCellAction_ConversationIDKey: cellData.conversationID ?? "",
            TUICore_TUIConversationExtension_ConversationCellAction_MarkListKey: cellData.conversationMarkList ?? [],
            TUICore_TUIConversationExtension_ConversationCellAction_GroupListKey: cellData.conversationGroupList ?? []
        ])
        if disableMoreActionExtension || moreExtensionList.count == 0 {
            let markAsHideAction = UITableViewRowAction(style: .destructive, title: TUISwift.timCommonLocalizableString("MarkHide")) { _, _ in
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_HideFoldItem(true)
                }
            }
            markAsHideAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            if !hideHideAction {
                rowActions.append(markAsHideAction)
            }
        } else {
            let moreAction = UITableViewRowAction(style: .destructive, title: TUISwift.timCommonLocalizableString("More")) { [weak self] _, _ in
                guard let self = self else { return }
                self.isEditing = false
                showMoreAction(cellData, extensionList: moreExtensionList)
            }
            moreAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            rowActions.append(moreAction)
        }
        return rowActions
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cellData = dataProvider.conversationList[indexPath.row]
        
        parseActionHiddenTagAndCustomizedItems(cellData)
        
        var arrayM: [UIContextualAction] = []
        
        if cellData.isLocalConversationFoldList && !hideHideAction {
            let markHideAction = UIContextualAction(style: .normal, title: TUISwift.timCommonLocalizableString("MarkHide")) { [weak self] _, _, completionHandler in
                guard let self = self else { return }
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_HideFoldItem(true)
                }
                completionHandler(true)
            }
            markHideAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            let configuration = UISwipeActionsConfiguration(actions: [markHideAction])
            configuration.performsFirstActionWithFullSwipe = false
            return configuration
        }
        
        if !hideDeleteAction {
            let deleteAction = UIContextualAction(style: .normal, title: TUISwift.timCommonLocalizableString("Delete")) { _, _, completionHandler in
                let cancelBtnInfo = TUISecondConfirmBtnInfo()
                cancelBtnInfo.tile = TUISwift.timCommonLocalizableString("Cancel")
                cancelBtnInfo.click = { [weak self] in
                    guard let self = self else { return }
                    self.isEditing = false
                }
                let confirmBtnInfo = TUISecondConfirmBtnInfo()
                confirmBtnInfo.tile = TUISwift.timCommonLocalizableString("Delete")
                confirmBtnInfo.click = { [weak self] in
                    guard let self = self else { return }
                    self.dataProvider.removeConversation(cellData)
                    self.isEditing = false
                }
                TUISecondConfirm.show(TUISwift.timCommonLocalizableString("TUIKitConversationTipsDelete"), cancel: cancelBtnInfo, confirmBtnInfo: confirmBtnInfo)
                completionHandler(true)
            }
            deleteAction.backgroundColor = TUISwift.rgb(242, green: 77, blue: 76)
            arrayM.append(deleteAction)
        }
        
        if !hideMarkReadAction {
            let markAsReadAction = UIContextualAction(style: .normal, title: cellData.isMarkAsUnread || cellData.unreadCount > 0 ? TUISwift.timCommonLocalizableString("MarkAsRead") : TUISwift.timCommonLocalizableString("MarkAsUnRead")) { [weak self] _, _, completionHandler in
                guard let self = self else { return }
                if cellData.isMarkAsUnread || cellData.unreadCount > 0 {
                    self.dataProvider.markConversationAsRead(cellData)
                    if cellData.isLocalConversationFoldList {
                        TUIConversationListDataProvider.cacheConversationFoldListSettings_FoldItemIsUnread(false)
                    }
                } else {
                    self.dataProvider.markConversationAsUnRead(cellData)
                    if cellData.isLocalConversationFoldList {
                        TUIConversationListDataProvider.cacheConversationFoldListSettings_FoldItemIsUnread(true)
                    }
                }
                completionHandler(true)
            }
            markAsReadAction.backgroundColor = TUISwift.rgb(20, green: 122, blue: 255)
            arrayM.append(markAsReadAction)
        }
        
        let moreExtensionList: [Any] = TUICore.getExtensionList(
            TUICore_TUIConversationExtension_ConversationCellMoreAction_ClassicExtensionID,
            param: [
                TUICore_TUIConversationExtension_ConversationCellAction_ConversationIDKey: cellData.conversationID ?? "",
                TUICore_TUIConversationExtension_ConversationCellAction_MarkListKey: cellData.conversationMarkList ?? [],
                TUICore_TUIConversationExtension_ConversationCellAction_GroupListKey: cellData.conversationGroupList ?? []
            ]
        )
        if disableMoreActionExtension || moreExtensionList.count == 0 {
            let markAsHideAction = UIContextualAction(style: .normal, title: TUISwift.timCommonLocalizableString("MarkHide")) { [weak self] _, _, _ in
                guard let self = self else { return }
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_HideFoldItem(true)
                }
            }
            markAsHideAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            if !hideHideAction {
                arrayM.append(markAsHideAction)
            }
        } else {
            let moreAction = UIContextualAction(style: .normal, title: TUISwift.timCommonLocalizableString("More")) { [weak self] _, _, completionHandler in
                guard let self = self else { return }
                self.isEditing = false
                showMoreAction(cellData, extensionList: moreExtensionList)
                completionHandler(true)
            }
            moreAction.backgroundColor = TUISwift.rgb(242, green: 147, blue: 64)
            arrayM.append(moreAction)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: arrayM)
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    // MARK: action

    private func showMoreAction(_ cellData: TUIConversationCellData, extensionList: [Any]) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for action in customizedItems {
            ac.addAction(action)
        }
        if !hideHideAction {
            ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("MarkHide"), style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.dataProvider.markConversationHide(cellData)
                if cellData.isLocalConversationFoldList {
                    TUIConversationListDataProvider.cacheConversationFoldListSettings_HideFoldItem(true)
                }
            })
        }
        addCustomAction(ac, cellData: cellData)
        ac.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .cancel, handler: nil))
        if let convDelegate = convDelegate, convDelegate.responds(to: #selector(TUIConversationTableViewDelegate.tableViewDidShowAlert(_:))) {
            convDelegate.tableViewDidShowAlert!(ac)
        }
    }
    
    func addCustomAction(_ ac: UIAlertController, cellData: TUIConversationCellData) {
        let extensionList = TUICore.getExtensionList(TUICore_TUIConversationExtension_ConversationCellMoreAction_ClassicExtensionID, param: [
            TUICore_TUIConversationExtension_ConversationCellAction_ConversationIDKey: cellData.conversationID ?? "",
            TUICore_TUIConversationExtension_ConversationCellAction_MarkListKey: cellData.conversationMarkList ?? [],
            TUICore_TUIConversationExtension_ConversationCellAction_GroupListKey: cellData.conversationGroupList ?? []
        ])
        for info in extensionList {
            let action = UIAlertAction(title: info.text, style: .default) { _ in
                info.onClicked?([:])
            }
            ac.addAction(action)
        }
    }
    
    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < dataProvider.conversationList.count else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: gConversationCell_ReuseId, for: indexPath) as? TUIConversationCell else { return UITableViewCell() }
        if indexPath.row < dataProvider.conversationList.count {
            let data = dataProvider.conversationList[indexPath.row]
            tableViewFillCell(cell, withData: data)
            let extensionList = TUICore.getExtensionList(TUICore_TUIConversationExtension_ConversationCellUpperRightCorner_ClassicExtensionID, param: [
                TUICore_TUIConversationExtension_ConversationCellUpperRightCorner_GroupListKey: data.conversationGroupList ?? [],
                TUICore_TUIConversationExtension_ConversationCellUpperRightCorner_MarkListKey: data.conversationMarkList ?? []
            ])
            if !extensionList.isEmpty {
                if let info = extensionList.first {
                    if let text = info.text {
                        cell.timeLabel.text = text
                    } else if let icon = info.icon {
                        let textAttachment = NSTextAttachment()
                        textAttachment.image = icon
                        let imageStr = NSAttributedString(attachment: textAttachment)
                        cell.timeLabel.attributedText = imageStr
                    }
                }
            }
        }
        return cell
    }
    
    func tableViewFillCell(_ cell: TUIConversationCell, withData data: TUIConversationCellData) {
        cell.fill(with: data)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = dataProvider.conversationList[indexPath.row]
        tableViewDidSelectCell(data)
    }
    
    func tableViewDidSelectCell(_ data: TUIConversationCellData) {
        if let convDelegate = convDelegate, convDelegate.responds(to: #selector(TUIConversationTableViewDelegate.tableViewDidSelectCell(_:))) {
            convDelegate.tableViewDidSelectCell!(data)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let needLastLineFromZeroToMax = false
        if cell.responds(to: #selector(setter: UITableViewCell.separatorInset)) {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 75, bottom: 0, right: 0)
            if needLastLineFromZeroToMax && indexPath.row == (dataProvider.conversationList.count) - 1 {
                cell.separatorInset = .zero
            }
        }
        if needLastLineFromZeroToMax && cell.responds(to: #selector(setter: UITableViewCell.preservesSuperviewLayoutMargins)) {
            cell.preservesSuperviewLayoutMargins = false
        }
        if needLastLineFromZeroToMax && cell.responds(to: #selector(setter: UITableViewCell.layoutMargins)) {
            cell.layoutMargins = .zero
        }
    }
}
