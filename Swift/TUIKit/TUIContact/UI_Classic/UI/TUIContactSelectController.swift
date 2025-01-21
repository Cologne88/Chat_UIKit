import TIMCommon
import TUICore
import UIKit

typealias ContactSelectFinishBlock = ([TUICommonContactSelectCellData]) -> Void
let gReuseIdentifier = "ContactSelectCell"

class TUIContactSelectController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var viewModel: TUIContactSelectViewDataProvider?
    var finishBlock: ContactSelectFinishBlock?
    var maxSelectCount: Int = 0
    var sourceIds: [String]?
    var disableIds: [String]?
    var displayNames: [String: String]?
    var navigationTitle: String?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIView(frame: .zero)
    private let pickerView = TUIContactListPicker(frame: .zero)
    private var selectArray = [TUICommonContactSelectCellData]()

    var isLoadFinishedObservation: NSKeyValueObservation?
    var groupListObservation: NSKeyValueObservation?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initData()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initData()
    }

    deinit {
        isLoadFinishedObservation = nil
        groupListObservation = nil
    }

    private func initData() {
        maxSelectCount = 0
        selectArray = []
        viewModel = TUIContactSelectViewDataProvider()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F3F5F9")
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .darkGray
        tableView.backgroundColor = view.backgroundColor
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 58, bottom: 0, right: 0)
        tableView.register(TUICommonContactSelectCell.self, forCellReuseIdentifier: gReuseIdentifier)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        view.addSubview(tableView)

        emptyView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(contactListNilLabelTapped(_:)))
        emptyView.addGestureRecognizer(tapGesture)
        view.addSubview(emptyView)

        let tipsLabel = UILabel(frame: .zero)
        tipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitTipsContactListNil")
        emptyView.addSubview(tipsLabel)

        pickerView.backgroundColor = .groupTableViewBackground
        pickerView.accessoryBtn.addTarget(self, action: #selector(finishTask), for: .touchUpInside)
        view.addSubview(pickerView)

        setupBinds()
        if let sourceIds = sourceIds {
            viewModel?.setSourceIds(sourceIds, displayNames: displayNames)
        } else {
            viewModel?.loadContacts()
        }

        view.backgroundColor = UIColor(red: 42/255, green: 42/255, blue: 40/255, alpha: 1)
        navigationItem.title = navigationTitle
    }

    private func setupBinds() {
        isLoadFinishedObservation = viewModel?.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let finished = change.newValue else { return }
            if finished {
                self.tableView.reloadData()
            }
        }
        groupListObservation = viewModel?.observe(\.groupList, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let list = change.newValue else { return }
            self.emptyView.isHidden = !list.isEmpty
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pickerView.frame = CGRect(x: 0, y: view.bounds.height - 60 - TUISwift.bottom_SafeHeight(), width: view.bounds.width, height: 60 + TUISwift.bottom_SafeHeight())
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - pickerView.frame.height)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.groupList.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let group = viewModel?.groupList[section] else { return 0 }
        return viewModel?.dataDict[group]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerViewId = "ContactDrawerView"
        var headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerViewId)
        if headerView == nil {
            headerView = UITableViewHeaderFooterView(reuseIdentifier: headerViewId)
            let textLabel = UILabel(frame: .zero)
            textLabel.tag = 1
            textLabel.font = UIFont.systemFont(ofSize: 16)
            textLabel.textColor = UIColor(red: 0x80/255, green: 0x80/255, blue: 0x80/255, alpha: 1)
            headerView?.addSubview(textLabel)
            textLabel.snp.remakeConstraints { make in
                make.leading.equalTo(headerView!.snp.leading).offset(12)
                make.top.bottom.trailing.equalTo(headerView!)
            }
            textLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
        if let label = headerView?.viewWithTag(1) as? UILabel {
            label.text = viewModel?.groupList[section]
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel?.groupList
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: gReuseIdentifier, for: indexPath) as? TUICommonContactSelectCell else {
            return UITableViewCell()
        }
        guard let group = viewModel?.groupList[indexPath.section],
              let list = viewModel?.dataDict[group]
        else {
            return cell
        }
        let data = list[indexPath.row]
        if data.isEnabled {
            data.cselector = #selector(didSelectContactCell(_:))
        } else {
            data.cselector = nil
        }
        cell.fill(with: data)
        return cell
    }

    @objc func didSelectContactCell(_ cell: TUICommonContactSelectCell) {
        guard let data = cell.selectData else { return }
        if !data.isSelected {
            if maxSelectCount > 0 && selectArray.count + 1 > maxSelectCount {
                TUITool.makeToast(String(format: TUISwift.timCommonLocalizableString("TUIKitTipsMostSelectTextFormat"), maxSelectCount))
                return
            }
        }
        data.isSelected = !data.isSelected
        cell.fill(with: data)
        if data.isSelected {
            selectArray.append(data)
        } else {
            selectArray.removeAll { $0 == data }
        }
        pickerView.selectArray = selectArray
    }

    @objc private func contactListNilLabelTapped(_ label: Any) {
        TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitTipsContactListNil"))
    }

    @objc private func finishTask() {
        finishBlock?(selectArray)
    }
}
