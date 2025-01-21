//  TUIBlackListController_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon

class TUIBlackListController_Minimalist: UITableViewController, V2TIMFriendshipListener {
    var didSelectCellBlock: ((TUICommonContactCell_Minimalist) -> Void)?
    private var isLoadFinishedObservation: NSKeyValueObservation?
    
    lazy var viewModel: TUIBlackListViewDataProvider_Minimalist = {
        let viewModel = TUIBlackListViewDataProvider_Minimalist()
        return viewModel
    }()
    
    lazy var noDataTipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("nodata_tips_color", defaultColor: "#999999")
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.text = TUISwift.timCommonLocalizableString("TUIKitContactNoBlockList")
        return label
    }()
    
    deinit {
        isLoadFinishedObservation = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitContactsBlackList")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel
        tableView.delaysContentTouches = false

        isLoadFinishedObservation = viewModel.observe(\.isLoadFinished, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self, let finished = change.newValue else { return }
            if finished {
                self.tableView.reloadData()
            }
        }
        viewModel.loadBlackList()

        tableView.register(TUICommonContactCell_Minimalist.self, forCellReuseIdentifier: "FriendCell")
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorStyle = .none

        V2TIMManager.sharedInstance().addFriendListener(listener: self)

        tableView.addSubview(noDataTipsLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noDataTipsLabel.frame = CGRect(x: 10, y: 60, width: view.bounds.size.width - 20, height: 40)
    }

    // MARK: - V2TIMFriendshipListener
    func onBlackListAdded(_ infoList: [V2TIMFriendInfo]) {
        viewModel.loadBlackList()
    }

    private func onBlackListDeleted(_ userIDList: [String]) {
        viewModel.loadBlackList()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        noDataTipsLabel.isHidden = (viewModel.blackListData.count != 0)
        return viewModel.blackListData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! TUICommonContactCell_Minimalist
        let data = viewModel.blackListData[indexPath.row]
        data.cselector = #selector(didSelectBlackList(_:))
        cell.separtorView.isHidden = true
        cell.fill(with: data)
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    @objc func didSelectBlackList(_ cell: TUICommonContactCell_Minimalist) {
        didSelectCellBlock?(cell)
    }
}
