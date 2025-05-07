// TUIGroupConversationListController_Minimalist.swift
// TUIContact

import UIKit
import TIMCommon

// 定义全局变量
let gConversationCell_ReuseId = "TConversationCell"

// 定义回调类型
typealias TUIGroupConversationListSelectCallback_Minimalist = (TUICommonContactCellData_Minimalist) -> Void

/**
 * 【模块名称】群组列表界面 (TUIGroupConversationListController)
 * 【功能说明】负责拉取用户的群组信息并在界面中显示。
 * 用户可以通过群组列表界面查看自己加入的所有群组。群组按群组名称的首字母顺序显示，带有特殊符号的群组名称显示在最后。
 */
class TUIGroupConversationListController_Minimalist: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {

    var tableView: UITableView!
    var onSelect: TUIGroupConversationListSelectCallback_Minimalist?
    private var isLoadFinishedObservation: NSKeyValueObservation?
    
    lazy var viewModel: TUIGroupConversationListViewDataProvider_Minimalist = {
        let viewModel = TUIGroupConversationListViewDataProvider_Minimalist()
        return viewModel
    }()
    
    private lazy var noDataTipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("nodata_tips_color", defaultColor: "#999999")
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.text = TUISwift.timCommonLocalizableString("TUIKitContactNoGroupChats")
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitContactsGroupChats")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()

        navigationItem.titleView = titleLabel
        view.backgroundColor = .white
        let rect = view.bounds
        tableView = UITableView(frame: rect, style: .plain)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .white
        tableView.backgroundColor = view.backgroundColor
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        let v = UIView(frame: .zero)
        tableView.tableFooterView = v
        tableView.separatorStyle = .none

        tableView.register(TUICommonContactCell_Minimalist.self, forCellReuseIdentifier: gConversationCell_ReuseId)

        updateConversations()

        isLoadFinishedObservation = viewModel.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self else { return }
            self.tableView.reloadData()
        }

        noDataTipsLabel.frame = CGRect(x: 10, y: 60, width: view.bounds.size.width - 20, height: 40)
        tableView.addSubview(noDataTipsLabel)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        isLoadFinishedObservation = nil
    }

    func updateConversations() {
        viewModel.loadConversation()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        noDataTipsLabel.isHidden = (viewModel.groupList.count != 0)
        return viewModel.groupList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.dataDict[viewModel.groupList[section]]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let data = viewModel.dataDict[viewModel.groupList[indexPath.section]]?[indexPath.row] else {
            return 0
        }
        return data.height(ofWidth: TUISwift.screen_Width())
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return TUISwift.timCommonLocalizableString("Delete")
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            if let data = viewModel.dataDict[viewModel.groupList[indexPath.section]]?[indexPath.row] {
                viewModel.removeData(data)
                tableView.deleteRows(at: [indexPath], with: .none)
            }
            tableView.endUpdates()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerViewId = "ContactDrawerView"
        var headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerViewId)
        if headerView == nil {
            headerView = UITableViewHeaderFooterView(reuseIdentifier: headerViewId)
            headerView?.contentView.backgroundColor = .white
            headerView?.backgroundColor = .white
            let textLabel = UILabel(frame: .zero)
            textLabel.tag = 1
            textLabel.textColor = UIColor.tui_color(withHex: "#000000")
            textLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
            textLabel.rtlAlignment = .leading
            headerView?.contentView.addSubview(textLabel)
            textLabel.snp.remakeConstraints { make in
                make.leading.equalTo(headerView!.snp.leading).offset(TUISwift.kScale390(16))
                make.top.bottom.trailing.equalTo(headerView!)
            }
            let clearBackgroundView = UIView()
            clearBackgroundView.mm__fill()
            headerView?.backgroundView = clearBackgroundView
        }
        if let label = headerView?.viewWithTag(1) as? UILabel {
            let formatiStr = "\(viewModel.groupList[section]) (\(viewModel.dataDict[viewModel.groupList[section]]?.count ?? 0))"
            label.text = formatiStr
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TUISwift.kScale390(28)
    }

    @objc func didSelectConversation(_ cell: TUICommonContactCell_Minimalist) {
        if let onSelect = onSelect, let data = cell.contactData {
            onSelect(data)
            return
        }

        let param: [String: Any] = [
            "TUICore_TUIChatObjectFactory_ChatViewController_Title": cell.contactData?.title ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": cell.contactData?.identifier ?? ""
        ]
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: gConversationCell_ReuseId, for: indexPath) as! TUICommonContactCell_Minimalist
        if let data = viewModel.dataDict[viewModel.groupList[indexPath.section]]?[indexPath.row] {
            if data.cselector == nil {
                data.cselector = #selector(didSelectConversation(_:))
            }
            cell.fill(with: data)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Implement selection logic if needed
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
