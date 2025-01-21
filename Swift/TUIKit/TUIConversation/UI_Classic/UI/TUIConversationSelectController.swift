import TIMCommon
import TUICore
import UIKit

class TUIConversationSelectController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let Id = "con"

    var tableView: UITableView!
    var pickerView: TUIContactListPicker!
    var headerView: TUICommonTableViewCell!

    var enableMultiple: Bool = false
    weak var showContactSelectVC: UIViewController?

    let dataListObserver = Observer()

    lazy var currentSelectedList: [TUIConversationCellData] = {
        let currentSelectedList = [TUIConversationCellData]()
        return currentSelectedList
    }()

    lazy var dataProvider: TUIConversationSelectDataProvider = {
        dataProvider = TUIConversationSelectDataProvider()
        dataProvider.loadConversations()
        return dataProvider
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateLayout()
    }

    deinit {
        dataProvider.dataList.removeObserver(dataListObserver)
        print("\(String(describing: self)) dealloc")
    }

    class func showIn(_ presentVC: UIViewController?) -> TUIConversationSelectController {
        let vc = TUIConversationSelectController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        var pVc = presentVC
        if pVc == nil {
            pVc = UIApplication.shared.keyWindow?.rootViewController
        }
        if let pVc = pVc {
            pVc.present(nav, animated: true, completion: nil)
        }
        return vc
    }

    func setupViews() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: TUISwift.timCommonLocalizableString("Cancel"), style: .plain, target: self, action: #selector(doCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: TUISwift.timCommonLocalizableString("Multiple"), style: .plain, target: self, action: #selector(doMultiple))

        view.backgroundColor = .white

        headerView = TUICommonTableViewCell()
        headerView.textLabel?.text = TUISwift.timCommonLocalizableString("TUIKitRelayTargetCreateNewChat")
        headerView.textLabel?.font = UIFont.systemFont(ofSize: 15.0)
        headerView.accessoryType = .disclosureIndicator
        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCreateSessionOrSelectContact)))

        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableHeaderView = headerView
        tableView.register(TUIConversationCell.self, forCellReuseIdentifier: TUIConversationSelectController.Id)
        view.addSubview(tableView)

        pickerView = TUIContactListPicker()
        pickerView.backgroundColor = .groupTableViewBackground
        pickerView.isHidden = true
        pickerView.accessoryBtn.addTarget(self, action: #selector(doPickerDone), for: .touchUpInside)
        pickerView.onCancel = { [weak self] data in
            guard let self = self else { return }
            if let tmp = self.currentSelectedList.first(where: { $0.conversationID == data.identifier }) {
                tmp.selected = false
                self.currentSelectedList.removeAll(where: { $0 == tmp })
                self.updatePickerView()
                self.tableView.reloadData()
            }
        }
        view.addSubview(pickerView)

        dataProvider = TUIConversationSelectDataProvider()
        dataProvider.loadConversations()

        dataProvider.dataList.addObserver(dataListObserver) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }

    func updateLayout() {
        pickerView.isHidden = !enableMultiple
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 55)
        headerView.textLabel?.text = enableMultiple ? TUISwift.timCommonLocalizableString("TUIKitRelayTargetSelectFromContacts") : TUISwift.timCommonLocalizableString("TUIKitRelayTargetCreateNewChat")

        if !enableMultiple {
            tableView.frame = view.bounds
            return
        }

        let pH: CGFloat = 55
        var pMargin: CGFloat = 0
        if #available(iOS 11.0, *) {
            pMargin = view.safeAreaInsets.bottom
        }
        pickerView.frame = CGRect(x: 0, y: view.bounds.size.height - pH - pMargin, width: view.bounds.size.width, height: pH + pMargin)
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height - pH - pMargin)
    }

    func updatePickerView() {
        var arrayM = [TUICommonContactSelectCellData]()
        for convCellData in currentSelectedList {
            let data = TUICommonContactSelectCellData()
            if let url = URL(string: convCellData.faceUrl.value) {
                data.avatarUrl = url
            }
            data.avatarImage = convCellData.avatarImage ?? UIImage()
            data.title = convCellData.title.value
            data.identifier = convCellData.conversationID ?? ""
            arrayM.append(data)
        }
        pickerView.selectArray = arrayM
    }

    @objc func doCancel() {
        if enableMultiple {
            enableMultiple = false

            for cellData in dataProvider.dataList.value {
                cellData.selected = false
            }

            currentSelectedList.removeAll()
            pickerView.selectArray = []
            updatePickerView()
            updateLayout()
            tableView.reloadData()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc func doMultiple() {
        enableMultiple = true
        updateLayout()
        tableView.reloadData()
    }

    @objc func onCreateSessionOrSelectContact() {
        var ids = [String]()
        for cd in currentSelectedList {
            if cd.userID != V2TIMManager.sharedInstance().getLoginUser() {
                if let userID = cd.userID {
                    ids.append(userID)
                }
            }
        }

        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { [weak self] array in
            guard let self = self else { return }
            self.dealSelectBlock(array)
        }

        let vc = TUICore.createObject(TUICore_TUIContactObjectFactory, key: TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod, param: [
            TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey: ids,
            TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey: selectContactCompletion
        ])

        if let viewController = vc as? UIViewController {
            navigationController?.pushViewController(viewController, animated: true)
        }
        showContactSelectVC = vc as? UIViewController
    }

    func dealSelectBlock(_ array: [TUICommonContactSelectCellData]) {
        let selectArray = array
        if enableMultiple {
            for contact in selectArray {
                if existInSelectedArray(contact.identifier) {
                    continue
                }
                if let conv = findItemInDataListArray(contact.identifier) {
                    conv.selected = !conv.selected
                    currentSelectedList.append(conv)
                } else {
                    let conv = TUIConversationCellData()
                    conv.conversationID = contact.identifier
                    conv.userID = contact.identifier
                    conv.groupID = ""
                    conv.avatarImage = contact.avatarImage
                    conv.faceUrl.value = contact.avatarUrl?.absoluteString ?? ""
                    currentSelectedList.append(conv)
                }
            }
            updatePickerView()
            tableView.reloadData()
            navigationController?.popViewController(animated: true)
        } else {
            if selectArray.count <= 1 {
                if let contact = selectArray.first {
                    let conv = TUIConversationCellData()
                    conv.conversationID = contact.identifier
                    conv.userID = contact.identifier
                    conv.groupID = ""
                    conv.avatarImage = contact.avatarImage
                    conv.faceUrl.value = contact.avatarUrl?.absoluteString ?? ""
                    currentSelectedList = [conv]
                    tryFinishSelected { [weak self] finished in
                        guard let self = self else { return }
                        if finished {
                            self.notifyFinishSelecting()
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
                return
            }
            tryFinishSelected { [weak self] finished in
                guard let self = self else { return }
                if finished {
                    self.createGroupWithContacts(selectArray) { [weak self] success in
                        guard let self = self else { return }
                        if success {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }

    func existInSelectedArray(_ identifier: String) -> Bool {
        for cellData in currentSelectedList {
            if let userID = cellData.userID, userID == identifier {
                return true
            }
        }
        return false
    }

    func findItemInDataListArray(_ identifier: String) -> TUIConversationCellData? {
        for cellData in dataProvider.dataList.value {
            if let userID = cellData.userID, userID == identifier {
                return cellData
            }
        }
        return nil
    }

    @objc func doPickerDone() {
        tryFinishSelected { [weak self] finished in
            guard let self = self else { return }
            if finished {
                notifyFinishSelecting()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func tryFinishSelected(_ handler: @escaping (Bool) -> Void) {
        let alertVc = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitRelayConfirmForward"), message: nil, preferredStyle: .alert)
        alertVc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Cancel"), style: .default, handler: { _ in
            handler(false)
        }))
        alertVc.addAction(UIAlertAction(title: TUISwift.timCommonLocalizableString("Confirm"), style: .default, handler: { _ in
            handler(true)
        }))
        present(alertVc, animated: true, completion: nil)
    }

    func notifyFinishSelecting() {
        var temMArr = [NSDictionary]()
        for cellData in currentSelectedList {
            temMArr.append([
                TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_ConversationID: cellData.conversationID ?? "",
                TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_Title: cellData.title.value,
                TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_UserID: cellData.userID ?? "",
                TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_GroupID: cellData.groupID ?? ""
            ])
        }
        if navigateValueCallback != nil {
            navigateValueCallback!([TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList: temMArr])
        }
    }

    func createGroupWithContacts(_ contacts: [TUICommonContactSelectCellData], completion: @escaping (Bool) -> Void) {
        let createGroupCompletion: (Bool, String?, String?) -> Void = { [weak self] success, groupID, groupName in
            guard let self = self else { return }
            if !success {
                TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitRelayTargetCrateGroupError"))
                completion(false)
                return
            }
            let cellData = TUIConversationCellData()
            cellData.groupID = groupID ?? ""
            cellData.title.value = groupName ?? ""
            self.currentSelectedList = [cellData]
            notifyFinishSelecting()
            completion(true)
        }
        let param: [String: Any] = [
            TUICore_TUIContactService_CreateGroupMethod_GroupTypeKey: GroupType_Meeting,
            TUICore_TUIContactService_CreateGroupMethod_OptionKey: V2TIMGroupAddOpt.GROUP_ADD_ANY,
            TUICore_TUIContactService_CreateGroupMethod_ContactsKey: contacts,
            TUICore_TUIContactService_CreateGroupMethod_CompletionKey: createGroupCompletion
        ]
        TUICore.callService(TUICore_TUIContactService, method: TUICore_TUIContactService_CreateGroupMethod, param: param)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.dataList.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "con", for: indexPath) as? TUIConversationCell else {
            return UITableViewCell()
        }
        guard indexPath.row >= 0 && indexPath.row < dataProvider.dataList.value.count else {
            return cell
        }
        let cellData = dataProvider.dataList.value[indexPath.row]
        cellData.showCheckBox = enableMultiple
        cell.fill(with: cellData)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cellData = dataProvider.dataList.value[indexPath.row]
        cellData.selected = !cellData.selected
        if !enableMultiple {
            currentSelectedList = [cellData]
            tryFinishSelected { [weak self] finished in
                guard let self = self else { return }
                if finished {
                    notifyFinishSelecting()
                    self.dismiss(animated: true, completion: nil)
                }
            }
            return
        }

        if currentSelectedList.contains(cellData) {
            currentSelectedList.removeAll(where: { $0 == cellData })
        } else {
            currentSelectedList.append(cellData)
        }

        updatePickerView()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56.0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titleView = UIView()
        titleView.backgroundColor = .groupTableViewBackground
        titleView.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30)
        let label = UILabel()
        label.text = TUISwift.timCommonLocalizableString("TUIKitRelayRecentMessages")
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = .darkGray
        label.textAlignment = .left
        titleView.addSubview(label)
        label.frame = CGRect(x: 10, y: 0, width: tableView.bounds.size.width - 10, height: 30)
        return titleView
    }
}
