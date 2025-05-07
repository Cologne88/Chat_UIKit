//  TUIContactSelectController_Minimalist.swift
//  TUIContact

import TIMCommon
import TUICore
import UIKit

typealias ContactSelectFinishBlock_Minimalist = ([TUICommonContactSelectCellData_Minimalist]) -> Void

class TUIContactSelectControllerHeaderView_Minimalist: UIView {
    var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.safeImage(TUISwift.tuiContactImagePath_Minimalist("contact_info_add_icon"))
        return imageView
    }()

    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale390(18))
        label.text = ""
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(avatarImageView)
        addSubview(nameLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
    }

    private func updateUI() {
        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale390(20))
            make.left.equalTo(TUISwift.kScale390(18))
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.remakeConstraints { make in
            make.height.equalToSuperview()
            make.left.equalTo(avatarImageView.snp.right).offset(14)
            make.right.equalToSuperview().offset(-TUISwift.kScale390(16))
        }
        nameLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        nameLabel.textColor = UIColor.tui_color(withHex: "#147AFF")
    }
}

class TUIContactSelectController_Minimalist: UIViewController, UITableViewDelegate, UITableViewDataSource, TUIFloatSubViewControllerProtocol {
    var floatDataSourceChanged: (([Any]) -> Void)?
    
    private(set) var selectArray: [TUICommonContactSelectCellData_Minimalist] = []

    var finishBlock: ContactSelectFinishBlock_Minimalist?
    var maxSelectCount: Int = 0
    var sourceIds: [String]?
    var disableIds: [String]?
    var displayNames: [String: String]?
    var navigationTitle: String?

    var tableView: UITableView!
    var emptyView: UIView!
    var addNewGroupHeaderView: TUIContactSelectControllerHeaderView_Minimalist!
    private var isLoadFinishedObservation: NSKeyValueObservation?
    private var groupListObservation: NSKeyValueObservation?

    lazy var userPanelHeaderView: TUIContactUserPanelHeaderView_Minimalist = .init()

    lazy var viewModel: TUIContactSelectViewDataProvider_Minimalist = .init()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initData()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        isLoadFinishedObservation = nil
        groupListObservation = nil
    }

    private func initData() {
        maxSelectCount = 0
        selectArray = []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: TUISwift.timCommonLocalizableString("Done"),
            style: .plain,
            target: self,
            action: #selector(finishTask)
        )

        tableView = UITableView(frame: view.bounds, style: .plain)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .systemBlue
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none

        let footerView = UIView(frame: .zero)
        tableView.tableFooterView = footerView
        tableView.register(TUICommonContactSelectCell_Minimalist.self, forCellReuseIdentifier: "TUICommonContactSelectCell_Minimalist")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        emptyView = UIView(frame: .zero)
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(contactListNilLabelTapped))
        emptyView.addGestureRecognizer(tapGesture)

        let tipsLabel = UILabel(frame: .zero)
        emptyView.addSubview(tipsLabel)
        tipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitTipsContactListNil")
        tipsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addNewGroupHeaderView = TUIContactSelectControllerHeaderView_Minimalist()
        addNewGroupHeaderView.nameLabel.text = TUISwift.timCommonLocalizableString("TUIKitRelayTargetCreateNewGroup")
        addNewGroupHeaderView.nameLabel.font = UIFont.systemFont(ofSize: 15.0)
        addNewGroupHeaderView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCreateSessionOrSelectContact)))
        tableView.tableHeaderView = addNewGroupHeaderView

        setupBinds()
        if let sourceIds = sourceIds {
            viewModel.setSourceIds(sourceIds, displayNames: displayNames)
        } else {
            viewModel.loadContacts()
        }

        navigationItem.title = navigationTitle
    }

    private func setupBinds() {
        isLoadFinishedObservation = viewModel.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let finished = change.newValue else { return }
            if finished {
                self.tableView.reloadData()
            }
        }
        groupListObservation = viewModel.observe(\.groupList, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let list = change.newValue else { return }
            self.emptyView.isHidden = !list.isEmpty
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.mm_width(view.mm_w).mm_flexToBottom(0)
        if maxSelectCount == 1 {
            addNewGroupHeaderView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 55)
            addNewGroupHeaderView.isHidden = false
        } else {
            addNewGroupHeaderView.frame = .zero
            addNewGroupHeaderView.isHidden = true
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.groupList.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = viewModel.groupList[section]
        return viewModel.dataDict[group]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerViewId = "ContactDrawerView"
        var headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerViewId)
        if headerView == nil {
            headerView = UITableViewHeaderFooterView(reuseIdentifier: headerViewId)
            let textLabel = UILabel(frame: .zero)
            textLabel.tag = 1
            textLabel.font = UIFont.boldSystemFont(ofSize: 16)
            textLabel.textColor = UIColor.tui_color(withHex: "#000000")
            textLabel.rtlAlignment = .leading
            headerView?.addSubview(textLabel)
            textLabel.snp.remakeConstraints { make in
                make.leading.equalTo(headerView!.snp.leading).offset(12)
                make.top.bottom.trailing.equalToSuperview()
            }
            textLabel.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        }
        if let label = headerView?.viewWithTag(1) as? UILabel {
            label.text = viewModel.groupList[section]
        }
        headerView?.backgroundColor = .white
        headerView?.contentView.backgroundColor = .white

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 33
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.groupList
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TUICommonContactSelectCell_Minimalist", for: indexPath) as? TUICommonContactSelectCell_Minimalist else {
            return UITableViewCell()
        }

        let group = viewModel.groupList[indexPath.section]
        if let list = viewModel.dataDict[group] {
            let data = list[indexPath.row]
            if data.isEnabled {
                data.cselector = #selector(didSelectContactCell(_:))
            } else {
                data.cselector = nil
            }
            if maxSelectCount == 1 {
                cell.selectButton.isHidden = true
            }

            cell.fill(with: data)
        }

        return cell
    }

    @objc private func contactListNilLabelTapped(_ label: Any) {
        TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitTipsContactListNil"))
    }

    @objc func didSelectContactCell(_ cell: TUICommonContactSelectCell_Minimalist) {
        guard let selectData = cell.selectData else { return }
        if !selectData.isSelected {
            if maxSelectCount > 0 && selectArray.count + 1 > maxSelectCount {
                TUITool.makeToast(String(format: TUISwift.timCommonLocalizableString("TUIKitTipsMostSelectTextFormat"), maxSelectCount))
                return
            }
        }
        selectData.isSelected = !selectData.isSelected
        cell.fill(with: selectData)

        if selectData.isSelected {
            selectArray.append(selectData)
        } else {
            selectArray.removeAll { $0 == selectData }
        }
        floatDataSourceChanged?(selectArray)

        if maxSelectCount != 1 {
            if !selectArray.isEmpty {
                userPanelHeaderView.isHidden = false
                userPanelHeaderView.frame = CGRect(x: 0, y: TUISwift.kScale390(22), width: view.bounds.width, height: TUISwift.kScale390(62))
                userPanelHeaderView.selectedUsers = selectArray
                userPanelHeaderView.clickCallback = { [weak self] in
                    guard let self = self else { return }
                    self.selectArray = self.userPanelHeaderView.selectedUsers as! [TUICommonContactSelectCellData_Minimalist]
                    self.floatDataSourceChanged?(self.selectArray)
                    self.userPanelHeaderView.userPanel.reloadData()
                    self.tableView.reloadData()
                    if self.selectArray.isEmpty {
                        self.hidePanelHeaderViewWhenUserSelectCountZero()
                    }
                }
                tableView.tableHeaderView = userPanelHeaderView
                tableView.tableHeaderView?.isUserInteractionEnabled = true
                userPanelHeaderView.userPanel.reloadData()
            } else {
                hidePanelHeaderViewWhenUserSelectCountZero()
            }
        } else {
            finishTask()
            dismiss(animated: true, completion: nil)
        }
    }

    private func hidePanelHeaderViewWhenUserSelectCountZero() {
        userPanelHeaderView.isHidden = true
        userPanelHeaderView.frame = .zero
        tableView.tableHeaderView = userPanelHeaderView
    }

    @objc private func onCreateSessionOrSelectContact() {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name("kTUIConversationCreatGroupNotification"), object: nil)
        }
    }

    @objc private func finishTask() {
        finishBlock?(selectArray)
    }

    // MARK: - TUIChatFloatSubViewControllerProtocol

    func floatControllerLeftButtonClick() {
        dismiss(animated: true, completion: nil)
    }

    func floatControllerRightButtonClick() {
        finishTask()
        dismiss(animated: true, completion: nil)
    }
}
