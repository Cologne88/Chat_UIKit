import TIMCommon
import TUICore
import UIKit

class TUIConversationSelectCollectionCell: UICollectionViewCell {
    var textLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = UIColor.tui_color(withHex: "#000000")
        contentView.addSubview(textLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.sizeToFit()
        textLabel.frame = CGRect(x: 0, y: TUISwift.kScale390(14), width: textLabel.frame.size.width, height: textLabel.frame.size.height)
    }
}

class TUIConversationSelectListPicker: UIControl, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var line: UIView!
    var collectionView: UICollectionView!
    var accessoryBtn: UIButton!
    var onCancel: ((TUICommonContactSelectCellData) -> Void)?

    var selectArray: [TUICommonContactSelectCellData]? {
        didSet {
            if let updatedArray = selectArray {
                collectionView.reloadData()
                accessoryBtn.isEnabled = !updatedArray.isEmpty
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initControl()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initControl() {
        line = UIView()
        line.backgroundColor = UIColor.tui_color(withHex: "#000000", alpha: 0.1)
        addSubview(line)

        let layout = TUICollectionRTLFitFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .normal

        collectionView.register(TUIConversationSelectCollectionCell.self, forCellWithReuseIdentifier: "PickerIdentifier")
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self

        addSubview(collectionView)

        accessoryBtn = UIButton(type: .custom)
        accessoryBtn.setTitle(TUISwift.timCommonLocalizableString("Forward"), for: .normal)
        accessoryBtn.setTitleColor(.systemBlue, for: .normal)
        accessoryBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        accessoryBtn.isEnabled = false
        addSubview(accessoryBtn)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        guard let selectArray = selectArray else { return CGSize.zero }
        let model = selectArray[indexPath.row]
        let formatTitle = indexPath.row != 0 ? ",\(model.title)" : model.title
        let size = formatTitle.boundingRect(with: CGSize(width: Int.max, height: 20),
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            attributes: [.font: UIFont.systemFont(ofSize: 14)],
                                            context: nil).size
        return CGSize(width: size.width, height: self.collectionView.frame.size.height)
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectArray?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let selectArray = selectArray else { return UICollectionViewCell() }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerIdentifier", for: indexPath) as? TUIConversationSelectCollectionCell {
            let data = selectArray[indexPath.row]
            if indexPath.row != 0 {
                cell.textLabel?.text = ",\(data.title)"
            } else {
                cell.textLabel?.text = data.title
            }
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let selectArray = selectArray else { return }
        if indexPath.item >= selectArray.count {
            return
        }
        let data = selectArray[indexPath.item]
        onCancel?(data)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        line.snp.remakeConstraints { make in
            make.top.left.equalTo(0)
            make.width.equalTo(self)
            make.height.equalTo(TUISwift.kScale390(1))
        }
        accessoryBtn.sizeToFit()
        accessoryBtn.snp.remakeConstraints { make in
            make.height.equalTo(30)
            make.right.equalToSuperview().offset(-30)
            make.top.equalToSuperview().offset(13)
        }
        collectionView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(TUISwift.kScale390(16))
            make.height.equalTo(40)
            make.right.equalTo(accessoryBtn.snp.left).offset(-30)
            make.centerY.equalTo(accessoryBtn)
        }
    }
}

class TUIConversationSelectController_Minimalist: UIViewController, UITableViewDelegate, UITableViewDataSource, TUIFloatSubViewControllerProtocol {
    var tableView: UITableView!
    var pickerView: TUIConversationSelectListPicker!
    var headerView: TUICommonTableViewCell!

    var enableMuliple: Bool = false
    var showContactSelectVC: UIViewController?
    var dataListObservation: NSKeyValueObservation?
    
    var floatDataSourceChanged: (([Any]) -> Void)?

    let Id: String = "con"

    lazy var dataProvider: TUIConversationSelectDataProvider_Minimalist = {
        var dataProvider = TUIConversationSelectDataProvider_Minimalist()
        dataProvider.loadConversations()
        return dataProvider
    }()

    lazy var currentSelectedList: [TUIConversationCellData] = {
        var currentSelectedList = [TUIConversationCellData]()
        return currentSelectedList
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateLayout()
    }

    deinit {
        dataListObservation?.invalidate()
        dataListObservation = nil
        print("\(String(describing: self)) dealloc")
    }

    class func showIn(_ presentVC: UIViewController?) -> TUIConversationSelectController_Minimalist {
        let vc = TUIConversationSelectController_Minimalist()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        var pVc = presentVC
        if pVc == nil {
            pVc = TUITool.applicationKeywindow()?.rootViewController
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
        headerView.textLabel!.text = TUISwift.timCommonLocalizableString("TUIKitRelayTargetCreateNewChat")
        headerView.textLabel!.font = UIFont.systemFont(ofSize: 15)
        headerView.accessoryType = .disclosureIndicator
        headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCreateSessionOrSelectContact)))

        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TUIConversationForwardSelectCell_Minimalist.self, forCellReuseIdentifier: Id)
        view.addSubview(tableView)

        pickerView = TUIConversationSelectListPicker()

        pickerView.backgroundColor = .white
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

        dataListObservation = dataProvider.observe(\.dataList, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            self.tableView.reloadData()
        }
    }

    func updateLayout() {
        pickerView.isHidden = !enableMuliple
        headerView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 55)
        headerView.textLabel!.text = enableMuliple ? TUISwift.timCommonLocalizableString("TUIKitRelayTargetSelectFromContacts") : TUISwift.timCommonLocalizableString("TUIKitRelayTargetCreateNewChat")

        if !enableMuliple {
            tableView.frame = view.bounds
            return
        }

        let pH: CGFloat = 55
        var pMargin: CGFloat = 0
        if #available(iOS 11.0, *) {
            pMargin = view.safeAreaInsets.bottom
        }
        pickerView.frame = CGRect(x: 0, y: view.bounds.height - pH - pMargin, width: view.bounds.width, height: pH + pMargin)
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - pH - pMargin)
    }

    func updatePickerView() {
        var arrayM: [TUICommonContactSelectCellData] = []
        for convCellData in currentSelectedList {
            let data = TUICommonContactSelectCellData()
            if let faceUrl = convCellData.faceUrl {
                data.avatarUrl = URL(string: faceUrl)!
            }
            data.avatarImage = convCellData.avatarImage ?? UIImage()
            data.title = convCellData.title ?? ""
            data.identifier = convCellData.conversationID ?? ""
            arrayM.append(data)
        }
        pickerView.selectArray = arrayM
    }

    @objc func doCancel() {
        if enableMuliple {
            enableMuliple = false

            for cellData in dataProvider.dataList {
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
        enableMuliple = true
        updateLayout()
        tableView.reloadData()
    }

    @objc func onCreateSessionOrSelectContact() {
        var ids: [String] = []
        for cd in currentSelectedList {
            if let userID = cd.userID, userID != V2TIMManager.sharedInstance().getLoginUser() {
                ids.append(userID)
            }
        }

        weak var weakSelf = self
        let selectContactCompletion: ([TUICommonContactSelectCellData]) -> Void = { array in
            weakSelf?.dealSelectBlock(array)
        }

        let vc = TUICore.createObject("TUICore_TUIContactObjectFactory", key: "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod", param: [
            "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_DisableIdsKey": ids,
            "TUICore_TUIContactObjectFactory_GetContactSelectControllerMethod_CompletionKey": selectContactCompletion
        ])

        if let viewController = vc as? UIViewController {
            navigationController?.pushViewController(viewController, animated: true)
        }
        showContactSelectVC = vc as? UIViewController
    }

    func dealSelectBlock(_ array: [TUICommonContactSelectCellData]) {
        let selectArray = array
        guard let _ = selectArray.first else {
            assertionFailure("Error value type")
            return
        }

        if enableMuliple {
            for contact in selectArray {
                if existInSelectedArray(contact.identifier) {
                    continue
                }
                let conv = findItemInDataListArray(contact.identifier) ?? TUIConversationCellData()
                conv.conversationID = contact.identifier
                conv.userID = contact.identifier
                conv.groupID = ""
                conv.avatarImage = contact.avatarImage
                conv.faceUrl = contact.avatarUrl?.absoluteString
                conv.selected = !conv.selected

                currentSelectedList.append(conv)
            }

            updatePickerView()
            tableView.reloadData()
            navigationController?.popViewController(animated: true)
        } else {
            if selectArray.count <= 1 {
                guard let contact = selectArray.first else { return }
                let conv = TUIConversationCellData()
                conv.conversationID = contact.identifier
                conv.userID = contact.identifier
                conv.groupID = ""
                conv.avatarImage = contact.avatarImage
                conv.faceUrl = contact.avatarUrl?.absoluteString
                currentSelectedList = [conv]
                tryFinishSelected { [weak self] finished in
                    guard let self = self else { return }
                    if finished {
                        self.notifyFinishSelecting()
                        dismiss(animated: true, completion: nil)
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
                            dismiss(animated: true, completion: nil)
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
        for cellData in dataProvider.dataList {
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
        var temMArr: [[String: Any]] = []
        for cellData in currentSelectedList {
            temMArr.append([
                "TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_ConversationID": cellData.conversationID ?? "",
                "TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_Title": cellData.title ?? "",
                "TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_UserID": cellData.userID ?? "",
                "TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList_GroupID": cellData.groupID ?? ""
            ])
        }
        if navigateValueCallback != nil {
            navigateValueCallback!(["TUICore_TUIConversationObjectFactory_ConversationSelectVC_ResultList": temMArr])
        }
    }

    func createGroupWithContacts(_ contacts: [TUICommonContactSelectCellData], completion: @escaping (Bool) -> Void) {
        weak var weakSelf = self
        let createGroupCompletion: (Bool, String, String) -> Void = { success, groupID, groupName in
            guard success else {
                TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitRelayTargetCrateGroupError"))
                completion(false)
                return
            }
            let cellData = TUIConversationCellData()
            cellData.groupID = groupID
            cellData.title = groupName
            weakSelf?.currentSelectedList = [cellData]
            weakSelf?.notifyFinishSelecting()
            completion(true)
        }
        let param: [String: Any] = [
            "TUICore_TUIContactService_CreateGroupMethod_GroupTypeKey": "Meeting",
            "TUICore_TUIContactService_CreateGroupMethod_OptionKey": V2TIMGroupAddOpt.GROUP_ADD_ANY.rawValue,
            "TUICore_TUIContactService_CreateGroupMethod_ContactsKey": contacts,
            "TUICore_TUIContactService_CreateGroupMethod_CompletionKey": createGroupCompletion
        ]
        TUICore.callService("TUICore_TUIContactService_Minimalist", method: "TUICore_TUIContactService_CreateGroupMethod", param: param)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.dataList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Id, for: indexPath) as? TUIConversationForwardSelectCell_Minimalist {
            if indexPath.row < 0 || indexPath.row >= dataProvider.dataList.count {
                return cell
            }

            let cellData = dataProvider.dataList[indexPath.row]
            cellData.showCheckBox = enableMuliple
            cell.fillWithData(cellData)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cellData = dataProvider.dataList[indexPath.row]
        cellData.selected = !cellData.selected
        if !enableMuliple {
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
        titleView.backgroundColor = .white
        titleView.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 30)
        let label = UILabel()
        label.text = TUISwift.timCommonLocalizableString("TUIKitRelayRecentMessages")
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.tui_color(withHex: "#000000")
        label.textAlignment = .left
        titleView.addSubview(label)
        label.frame = CGRect(x: 14, y: 0, width: tableView.bounds.width - 10, height: 30)
        return titleView
    }

    // MARK: - TUIFloatSubViewControllerProtocol

    func floatControllerLeftButtonClick() {
        doCancel()
    }

    func floatControllerRightButtonClick() {
        doMultiple()
    }
}
