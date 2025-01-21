import TIMCommon
import UIKit

class TUIGroupPendencyController: UITableViewController {
    var viewModel: TUIGroupPendencyDataProvider?
    var cellClickBlock: ((TUIGroupPendencyCell) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TUIGroupPendencyCell.self, forCellReuseIdentifier: "PendencyCell")
        tableView.tableFooterView = UIView()
        title = TUISwift.timCommonLocalizableString("TUIKitGroupApplicant")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.dataList.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PendencyCell", for: indexPath) as? TUIGroupPendencyCell, let data = viewModel?.dataList[indexPath.row] as? TUIGroupPendencyCellData else {
            return UITableViewCell()
        }

        data.cselector = #selector(cellClick(_:))
        data.cbuttonSelector = #selector(btnClick(_:))
        cell.fill(with: data)
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            if let data = viewModel?.dataList[indexPath.row] as? TUIGroupPendencyCellData {
                viewModel?.removeData(data)
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
    }

    @objc private func btnClick(_ cell: TUIGroupPendencyCell) {
        viewModel?.acceptData(cell.pendencyData)
        tableView.reloadData()
    }

    @objc private func cellClick(_ cell: TUIGroupPendencyCell) {
        cellClickBlock?(cell)
    }
}
