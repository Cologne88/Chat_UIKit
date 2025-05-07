import TIMCommon
import TUICore
import UIKit

typealias TUIGroupConversationListSelectCallback = (TUICommonContactCellData) -> Void

class TUIGroupConversationListController: UIViewController, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    private let gConversationCell_ReuseId = "TConversationCell"
    var tableView: UITableView!
    var viewModel: TUIGroupConversationListViewDataProvider!
    var onSelect: TUIGroupConversationListSelectCallback?
    var isLoadFinishedObservation: NSKeyValueObservation?

    lazy var noDataTipsLabel: UILabel = {
        let noDataTipsLabel = UILabel()
        noDataTipsLabel.textColor = TUISwift.timCommonDynamicColor("nodata_tips_color", defaultColor: "#999999")
        noDataTipsLabel.font = UIFont.systemFont(ofSize: 14.0)
        noDataTipsLabel.textAlignment = .center
        noDataTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitContactNoGroupChats")
        return noDataTipsLabel
    }()

    deinit {
        isLoadFinishedObservation = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = TUIGroupConversationListViewDataProvider()

        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitContactsGroupChats")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()

        navigationItem.titleView = titleLabel

        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        let rect = view.bounds
        tableView = UITableView(frame: rect, style: .plain)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.darkGray
        tableView.backgroundColor = view.backgroundColor
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        let view = UIView(frame: .zero)
        tableView.tableFooterView = view
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 58, bottom: 0, right: 0)
        tableView.register(TUICommonContactCell.self, forCellReuseIdentifier: gConversationCell_ReuseId)

        updateConversations()
        isLoadFinishedObservation = viewModel.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }

        noDataTipsLabel.frame = CGRect(x: 10, y: 60, width: view.bounds.size.width - 20, height: 40)
        tableView.addSubview(noDataTipsLabel)
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
            let textLabel = UILabel(frame: .zero)
            textLabel.tag = 1
            textLabel.textColor = TUISwift.rgb(0x80, g: 0x80, b: 0x80)
            textLabel.rtlAlignment = .leading
            headerView?.addSubview(textLabel)
            textLabel.snp.remakeConstraints { make in
                make.leading.equalTo(headerView!.snp.leading).offset(12)
                make.top.bottom.trailing.equalTo(headerView!)
            }
            textLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
        if let label = headerView?.viewWithTag(1) as? UILabel {
            label.text = viewModel.groupList[section]
        }
        headerView?.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        headerView?.contentView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }

    @objc func didSelectConversation(_ cell: TUICommonContactCell) {
        if let onSelect = onSelect, let data = cell.contactData {
            onSelect(data)
            return
        }

        let param: [String: Any] = [
            "TUICore_TUIChatObjectFactory_ChatViewController_Title": cell.contactData?.title ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": cell.contactData?.identifier ?? ""
        ]
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Classic", param: param, forResult: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: gConversationCell_ReuseId, for: indexPath) as! TUICommonContactCell
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
