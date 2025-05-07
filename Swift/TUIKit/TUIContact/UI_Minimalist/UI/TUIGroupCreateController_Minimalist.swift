// TUIGroupCreateController_Minimalist.swift
// TUIContact

import SDWebImage
import TIMCommon
import UIKit

class TUIGroupPortraitSelectAvatarCollectionCell_Minimalist: UICollectionViewCell {
    var imageView: UIImageView!
    var customMaskView: UIView!
    var descLabel: UILabel!
    var cardItem: TUISelectAvatarCardItem? {
        didSet {
            updateCellView()
        }
    }

    lazy var selectedView: UIImageView = {
        let selectedView = UIImageView(frame: .zero)
        selectedView.image = UIImage.safeImage(TUISwift.timCommonImagePath("icon_avatar_selected"))
        return selectedView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        imageView.layer.borderWidth = 2
        imageView.layer.masksToBounds = true
        contentView.addSubview(imageView)

        imageView.addSubview(selectedView)

        setupCustomMaskView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCellView()
        selectedView.frame = CGRect(x: imageView.frame.size.width - 16 - 4, y: 4, width: 16, height: 16)
    }

    func updateCellView() {
        updateSelectedUI()
        updateImageView()
        updateMaskView()
    }

    func updateSelectedUI() {
        guard let cardItem = cardItem else { return }

        if cardItem.isSelect {
            imageView.layer.borderColor = TUISwift.timCommonDynamicColor("", defaultColor: "#006EFF").cgColor
            selectedView.isHidden = false
        } else {
            if cardItem.isDefaultBackgroundItem {
                imageView.layer.borderColor = UIColor.gray.withAlphaComponent(0.1).cgColor
            } else {
                imageView.layer.borderColor = UIColor.clear.cgColor
            }
            selectedView.isHidden = true
        }
    }

    func updateImageView() {
        guard let cardItem = cardItem else { return }

        if cardItem.isGroupGridAvatar {
            updateNormalGroupGridAvatar()
        } else {
            imageView.sd_setImage(with: URL(string: cardItem.posterUrlStr ?? ""),
                                  placeholderImage: TUISwift.timCommonBundleThemeImage("default_c2c_head_img", defaultImage: "default_c2c_head_img"))
        }
    }

    func updateMaskView() {
        guard let cardItem = cardItem else { return }

        if cardItem.isDefaultBackgroundItem {
            customMaskView?.isHidden = false
            customMaskView.frame = CGRect(x: 0, y: imageView.frame.size.height - 28, width: imageView.frame.size.width, height: 28)
            descLabel.sizeToFit()
            descLabel.center = customMaskView.center
        } else {
            customMaskView.isHidden = true
        }
    }

    func updateNormalGroupGridAvatar() {
        guard let cardItem = cardItem else { return }

        if TUIConfig.default().enableGroupGridAvatar && cardItem.cacheGroupGridAvatarImage != nil {
            imageView.sd_setImage(with: nil, placeholderImage: cardItem.cacheGroupGridAvatarImage)
        }
    }

    func setupCustomMaskView() {
        customMaskView = UIView(frame: .zero)
        customMaskView.backgroundColor = UIColor.tui_color(withHex: "cccccc")
        imageView.addSubview(customMaskView)

        descLabel = UILabel(frame: .zero)
        descLabel.text = TUISwift.timCommonLocalizableString("TUIKitDefaultBackground")
        descLabel.textColor = .white
        descLabel.font = UIFont.systemFont(ofSize: 13)
        customMaskView.addSubview(descLabel)

        descLabel.sizeToFit()
        descLabel.center = customMaskView.center
    }
}

private let reuseIdentifier = "TUISelectAvatarCollectionCell"
class TUIGroupCreatePortrait_Minimalist: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    var onClick: ((TUISelectAvatarCardItem) -> Void)?
    var titleView: TUINaviBarIndicatorView?
    var collectionView: UICollectionView!
    var dataArr: [TUISelectAvatarCardItem] = []
    var currentSelectCardItem: TUISelectAvatarCardItem?
    var rightButton: UIButton!
    var profilFaceURL: String?
    var cacheGroupGridAvatarImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initControl()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initControl() {
        let flowLayout = TUICollectionRTLFitFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 20
        flowLayout.minimumInteritemSpacing = 20
        flowLayout.sectionInset = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 15)

        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        addSubview(collectionView)
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self

        // Register cell classes
        collectionView.register(TUIGroupPortraitSelectAvatarCollectionCell_Minimalist.self, forCellWithReuseIdentifier: "reuseIdentifier")

        dataArr = []
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = CGRect(x: TUISwift.kScale390(15), y: bounds.origin.y, width: bounds.size.width - TUISwift.kScale390(33) - TUISwift.kScale390(15), height: bounds.size.height)
    }

    func loadData() {
        if TUIConfig.default().enableGroupGridAvatar, let cacheImage = cacheGroupGridAvatarImage {
            let cardItem = creatGroupGridAvatarCardItem()
            dataArr.append(cardItem)
        }
        let GroupAvatarCount = 24
        for i in 0 ..< GroupAvatarCount {
            let cardItem = creatCardItemByURL(urlStr: GroupAvatarURL(i + 1))
            dataArr.append(cardItem)
        }
        collectionView.reloadData()
    }

    func GroupAvatarURL(_ index: Int) -> String {
        return String(format: "https://im.sdk.cloud.tencent.cn/download/tuikit-resource/group-avatar/group_avatar_%d.png", index)
    }

    func creatCardItemByURL(urlStr: String) -> TUISelectAvatarCardItem {
        let cardItem = TUISelectAvatarCardItem()
        cardItem.posterUrlStr = urlStr
        cardItem.isSelect = false
        if cardItem.posterUrlStr == profilFaceURL {
            cardItem.isSelect = true
            currentSelectCardItem = cardItem
        }
        return cardItem
    }

    func creatGroupGridAvatarCardItem() -> TUISelectAvatarCardItem {
        let cardItem = TUISelectAvatarCardItem()
        cardItem.posterUrlStr = ""
        cardItem.isSelect = false
        cardItem.isGroupGridAvatar = true
        cardItem.cacheGroupGridAvatarImage = cacheGroupGridAvatarImage ?? UIImage()
        if profilFaceURL == nil {
            cardItem.isSelect = true
            currentSelectCardItem = cardItem
        }
        return cardItem
    }

    func setCurrentSelectCardItem(_ currentSelectCardItem: TUISelectAvatarCardItem?) {
        self.currentSelectCardItem = currentSelectCardItem
        if currentSelectCardItem != nil {
            rightButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#006EFF"), for: .normal)
        } else {
            rightButton.setTitleColor(.gray, for: .normal)
        }
    }

    func rightBarButtonClick() {
        guard let currentSelectCardItem = currentSelectCardItem else { return }
        onClick?(currentSelectCardItem)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = TUISwift.kScale390(50)
        let height = TUISwift.kScale390(50)
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: TUISwift.kScale390(6), left: 0, bottom: TUISwift.kScale390(15), right: 0)
    }

    // MARK: <UICollectionViewDataSource>

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataArr.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuseIdentifier", for: indexPath) as! TUIGroupPortraitSelectAvatarCollectionCell_Minimalist
        if indexPath.row < dataArr.count {
            cell.cardItem = dataArr[indexPath.row]
        }
        return cell
    }

    // MARK: <UICollectionViewDelegate>

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        recoverSelectedStatus()

        guard let cell = collectionView.cellForItem(at: indexPath) as? TUIGroupPortraitSelectAvatarCollectionCell_Minimalist else {
            collectionView.layoutIfNeeded()
            return
        }

        if currentSelectCardItem == cell.cardItem {
            currentSelectCardItem = nil
        } else {
            cell.cardItem?.isSelect = true
            cell.updateSelectedUI()
            currentSelectCardItem = cell.cardItem
        }
        onClick?(currentSelectCardItem ?? TUISelectAvatarCardItem())
    }

    func recoverSelectedStatus() {
        var index = 0
        for card in dataArr {
            if currentSelectCardItem == card {
                card.isSelect = false
                break
            }
            index += 1
        }

        let indexPath = IndexPath(row: index, section: 0)
        guard let cell = collectionView.cellForItem(at: indexPath) as? TUIGroupPortraitSelectAvatarCollectionCell_Minimalist else {
            collectionView.layoutIfNeeded()
            return
        }
        cell.updateSelectedUI()
    }
}

class TUIGroupCreateController_Minimalist: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TUIFloatSubViewControllerProtocol {
    var floatDataSourceChanged: (([Any]) -> Void)?
    
    var createGroupInfo: V2TIMGroupInfo?
    var createContactArray: [TUICommonContactSelectCellData]?
    var submitCallback: ((Bool, V2TIMGroupInfo?, UIImage?) -> Void)?

    private var tableView: UITableView!
    private var groupNameTextField: UITextField!
    private var groupIDTextField: UITextField!
    private var keyboardShown = false
    private var titleView: TUINaviBarIndicatorView!
    private var describeTextViewRect: CGRect = .zero
    private var userPanelHeaderView: TUIContactUserPanelHeaderView_Minimalist!
    private var submitShowImage: UIImage?
    private var cacheGroupGridAvatarImage: UIImage?

    lazy var describeTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textAlignment = TUISwift.isRTL() ? .right : .left
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return textView
    }()

    lazy var createPortraitView: TUIGroupCreatePortrait_Minimalist = {
        let portraitView = TUIGroupCreatePortrait_Minimalist(frame: .zero)
        let headImage = UIImageView(image: TUISwift.defaultGroupAvatarImage(byGroupType: createGroupInfo?.groupType))

        if let cacheImage = cacheGroupGridAvatarImage, TUIConfig.default().enableGroupGridAvatar {
            portraitView.cacheGroupGridAvatarImage = cacheImage
            headImage.sd_setImage(with: URL(string: createGroupInfo?.faceURL ?? ""), placeholderImage: cacheImage)
        }
        submitShowImage = headImage.image
        portraitView.loadData()

        return portraitView
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.mm_width(view.mm_w).mm_flexToBottom(0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: view.frame, style: .plain)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        let paragraphPlaceholderStyle = NSMutableParagraphStyle()
        paragraphPlaceholderStyle.firstLineHeadIndent = 0
        paragraphPlaceholderStyle.headIndent = 0
        paragraphPlaceholderStyle.alignment = TUISwift.isRTL() ? .left : .right
        let attributesPlaceholder: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: TUISwift.kScale390(16)),
            .paragraphStyle: paragraphPlaceholderStyle
        ]

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.alignment = TUISwift.isRTL() ? .right : .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: TUISwift.kScale390(16)),
            .paragraphStyle: paragraphStyle
        ]

        groupNameTextField = UITextField(frame: .zero)
        groupNameTextField.textAlignment = TUISwift.isRTL() ? .right : .left
        groupNameTextField.attributedText = NSAttributedString(string: "", attributes: attributes)
        groupNameTextField.attributedPlaceholder = NSAttributedString(string: TUISwift.timCommonLocalizableString("TUIKitCreatGroupNamed_Placeholder"), attributes: attributesPlaceholder)
        groupNameTextField.delegate = self

        if let groupName = createGroupInfo?.groupName, !groupName.isEmpty {
            groupNameTextField.attributedText = NSAttributedString(string: groupName, attributes: attributes)
        }

        groupIDTextField = UITextField(frame: .zero)
        groupIDTextField.textAlignment = TUISwift.isRTL() ? .right : .left
        groupIDTextField.keyboardType = .default
        groupIDTextField.attributedText = NSAttributedString(string: "", attributes: attributes)
        groupIDTextField.attributedPlaceholder = NSAttributedString(string: TUISwift.timCommonLocalizableString("TUIKitCreatGroupID_Placeholder"), attributes: attributesPlaceholder)
        groupIDTextField.delegate = self

        updateRectAndTextForDescribeTextView(describeTextView)

        titleView = TUINaviBarIndicatorView()
        titleView.setTitle(TUISwift.timCommonLocalizableString("ChatsNewGroupText"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        creatGroupAvatarImage()
    }

    private func creatGroupAvatarImage() {
        guard TUIConfig.default().enableGroupGridAvatar, cacheGroupGridAvatarImage == nil else { return }
        var muArray = [String]()
        createContactArray?.forEach { cellData in
            if let avatarUrl = cellData.avatarUrl?.absoluteString {
                muArray.append(avatarUrl)
            } else {
                muArray.append("about:blank")
            }
        }
        muArray.append(TUILogin.getFaceUrl() ?? "")

        TUIGroupAvatar.createGroupAvatar(muArray) { [weak self] groupAvatar in
            guard let self else { return }
            self.cacheGroupGridAvatarImage = groupAvatar
            self.tableView.reloadData()
        }
    }

    private func updateRectAndTextForDescribeTextView(_ describeTextView: UITextView) {
        var descStr = ""
        Self.getfomatDescribeType(createGroupInfo?.groupType) { _, groupTypeDescribeStr in
            descStr = groupTypeDescribeStr
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = TUISwift.isRTL() ? .right : .left
        let dictionary: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.tui_color(withHex: "#888888"),
            .paragraphStyle: paragraphStyle
        ]
        let attributedString = NSMutableAttributedString(string: descStr, attributes: dictionary)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: descStr.count))
        let inviteTipstring = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Desc_Highlight")
        if inviteTipstring.count > 0 {
            attributedString.addAttribute(.link, value: "https://cloud.tencent.com/product/im", range: (descStr as NSString).range(of: inviteTipstring))
        }
        describeTextView.attributedText = attributedString

        let rect = describeTextView.text.boundingRect(with: CGSize(width: view.bounds.width - 32, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle], context: nil)
        describeTextViewRect = rect
    }

    // MARK: - TableView DataSource and Delegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return TUISwift.kScale390(144)
        } else if indexPath.section == 3 {
            return TUISwift.kScale390(60)
        }
        return 44
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear

        if section == 1 {
            view.addSubview(describeTextView)
            describeTextView.mm_width(describeTextViewRect.size.width)
                .mm_height(describeTextViewRect.size.height)
                .mm_top(TUISwift.kScale390(12))
                .mm_left(TUISwift.kScale390(13))
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 1 ? describeTextViewRect.size.height + 20 : 10
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear

        let sectionTitleLabel = UILabel()

        if section == 2 || section == 3 {
            view.addSubview(sectionTitleLabel)
            sectionTitleLabel.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(16))
            sectionTitleLabel.rtlAlignment = .leading
            if section == 2 {
                sectionTitleLabel.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupAvatar")
            } else if section == 3 {
                sectionTitleLabel.text = TUISwift.timCommonLocalizableString("TUIKitCreateMemebers")
            }

            sectionTitleLabel.sizeToFit()
            sectionTitleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(TUISwift.kScale390(16))
                make.top.equalTo(TUISwift.kScale390(12))
                make.size.equalTo(sectionTitleLabel.frame.size)
            }
        }
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 || section == 3 {
            return TUISwift.kScale390(44)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "groupName")
                cell.contentView.addSubview(groupNameTextField)
                cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
                groupNameTextField.snp.remakeConstraints { make in
                    make.trailing.equalTo(cell.contentView.snp.trailing)
                    make.leading.equalTo(cell.contentView.snp.leading).offset(10)
                    make.height.equalTo(cell.contentView)
                    make.centerY.equalTo(cell.contentView)
                }
                return cell
            } else {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "groupID")
                cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
                cell.contentView.addSubview(groupIDTextField)
                groupIDTextField.snp.remakeConstraints { make in
                    make.trailing.equalTo(cell.contentView.snp.trailing)
                    make.leading.equalTo(cell.contentView.snp.leading).offset(10)
                    make.height.equalTo(cell.contentView)
                    make.width.equalTo(cell.contentView)
                    make.centerY.equalTo(cell.contentView)
                }
                return cell
            }
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "GroupType")
            cell.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
            cell.accessoryType = .disclosureIndicator
            let leftTextLabel = UILabel()
            cell.contentView.addSubview(leftTextLabel)
            leftTextLabel.snp.makeConstraints { make in
                make.width.equalTo(cell.contentView.snp.width)
                make.height.equalTo(cell.contentView.snp.height)
                make.leading.equalTo(TUISwift.kScale390(16))
            }
            leftTextLabel.text = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType")
            leftTextLabel.textColor = .gray
            leftTextLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
            leftTextLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            Self.getfomatDescribeType(createGroupInfo?.groupType) { groupTypeStr, _ in
                cell.detailTextLabel?.text = groupTypeStr
            }
            return cell
        } else if indexPath.section == 2 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "GroupChoose")
            cell.contentView.addSubview(createPortraitView)
            createPortraitView.snp.remakeConstraints { make in
                make.leading.equalTo(cell.contentView)
                make.height.equalTo(TUISwift.kScale390(144))
                make.width.equalTo(cell.contentView)
                make.centerY.equalTo(cell.contentView)
            }
            createPortraitView.onClick = { [weak self] data in
                guard let self = self else { return }
                if let urlStr = data.posterUrlStr {
                    self.createGroupInfo?.faceURL = urlStr
                } else {
                    self.createGroupInfo?.faceURL = nil
                }
            }
            return cell
        } else if indexPath.section == 3 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "UserPanel")
            userPanelHeaderView = TUIContactUserPanelHeaderView_Minimalist()
            cell.contentView.addSubview(userPanelHeaderView)
            userPanelHeaderView.snp.remakeConstraints { make in
                make.trailing.equalTo(cell.contentView)
                make.height.equalTo(TUISwift.kScale390(57))
                make.width.equalTo(cell.contentView)
                make.centerY.equalTo(cell.contentView)
            }
            userPanelHeaderView.selectedUsers = createContactArray ?? []
            userPanelHeaderView.clickCallback = { [weak self] in
                self?.createContactArray = self?.userPanelHeaderView.selectedUsers
                self?.userPanelHeaderView.userPanel.reloadData()
                self?.tableView.reloadData()
            }
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        if indexPath.section == 1 {
            let vc = TUIGroupTypeListController_Minimalist()
            vc.cacheGroupType = createGroupInfo?.groupType
            vc.title = ""
            let floatVC = TUIFloatViewController()
            floatVC.appendChildViewController(vc, topMargin: TUISwift.kScale390(87.5))
            floatVC.topGestureView.setTitleText(mainText: TUISwift.timCommonLocalizableString("TUIKitGroupProfileType"), subTitleText: "", leftBtnText: TUISwift.timCommonLocalizableString("TUIKitCreateCancel"), rightBtnText: "")
            floatVC.topGestureView.rightButton.isHidden = true
            floatVC.topGestureView.subTitleLabel.isHidden = true
            present(floatVC, animated: true, completion: nil)

            vc.selectCallBack = { [weak self, weak floatVC] groupType in
                guard let self = self else { return }
                guard let floatVC = floatVC else { return }
                self.createGroupInfo?.groupType = groupType
                self.updateRectAndTextForDescribeTextView(self.describeTextView)
                self.tableView.reloadData()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    floatVC.floatDismissViewControllerAnimated(true, completion: {})
                }
            }
        } else if indexPath.section == 2 {
            didTapToChooseAvatar()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    // MARK: - TextField Delegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == groupNameTextField {
            if let text = textField.text, text.count > 10 {
                textField.text = String(text.prefix(10))
            }
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == groupIDTextField {
            let currentText = textField.text ?? ""
            let proposedNewLength = currentText.count - range.length + string.count
            if proposedNewLength > 16 {
                return false
            }
            return true
        }
        return true
    }

    // MARK: - Format

    static func getfomatDescribeType(_ groupType: String?, completion: (String, String) -> Void) {
        guard let groupType = groupType else {
            completion("", "")
            return
        }
        var desc = ""
        switch groupType {
        case "Work":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work"), desc)
        case "Public":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public"), desc)
        case "Meeting":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting"), desc)
        case "Community":
            desc = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community_Desc"))\n\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
            completion(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community"), desc)
        default:
            completion(groupType, groupType)
        }
    }

    // MARK: - Actions

    private func didTapToChooseAvatar() {
        let vc = TUISelectAvatarController()
        vc.selectAvatarType = .groupAvatar
        vc.createGroupType = createGroupInfo?.groupType ?? "Public"
        vc.cacheGroupGridAvatarImage = cacheGroupGridAvatarImage ?? UIImage()
        vc.profilFaceURL = createGroupInfo?.faceURL ?? ""
        navigationController?.pushViewController(vc, animated: true)
        vc.selectCallBack = { [weak self] urlStr in
            guard let self = self else { return }
            if !urlStr.isEmpty {
                self.createGroupInfo?.faceURL = urlStr
            } else {
                self.createGroupInfo?.faceURL = nil
            }
            self.tableView.reloadData()
        }
    }

    private func finishTask() {
        createGroupInfo?.groupName = groupNameTextField.text
        createGroupInfo?.groupID = groupIDTextField.text

        guard let info = createGroupInfo, let createContactArray = createContactArray else { return }

        let isCommunity = info.groupType == "Community"
        let hasTGSPrefix = info.groupID?.hasPrefix("@TGS#_") ?? false

        if let groupIDText = groupIDTextField.text, !groupIDText.isEmpty {
            if isCommunity && !hasTGSPrefix {
                let toastMsg = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessageRuleError")
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
                return
            }

            if !isCommunity && hasTGSPrefix {
                let toastMsg = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessageRuleError")
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
                return
            }
        }

        var members = [V2TIMCreateGroupMemberInfo]()
        for item in createContactArray {
            let member = V2TIMCreateGroupMemberInfo()
            member.userID = item.identifier
            member.role = UInt32(V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_MEMBER.rawValue)
            members.append(member)
        }

        let showName = TUILogin.getNickName() ?? TUILogin.getUserID()

        V2TIMManager.sharedInstance().createGroup(info: info, memberList: members, succ: { [weak self] groupID in
            guard let self = self else { return }
            var content = TUISwift.timCommonLocalizableString("TUIGroupCreateTipsMessage")
            if info.groupType == "Community" {
                content = TUISwift.timCommonLocalizableString("TUICommunityCreateTipsMessage")
            }
            let dic: [String: Any] = [
                "version": GroupCreate_Version,
                "businessID": "group_create",
                "opUser": showName ?? "",
                "content": content,
                "cmd": info.groupType == "Community" ? 1 : 0
            ]
            if let data = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted),
               let msg = V2TIMManager.sharedInstance().createCustomMessage(data: data)
            {
                _ = V2TIMManager.sharedInstance().sendMessage(message: msg, receiver: nil, groupID: groupID, priority: .PRIORITY_DEFAULT, onlineUserOnly: false, offlinePushInfo: nil, progress: nil, succ: nil, fail: nil)
            }
            self.createGroupInfo?.groupID = groupID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.submitCallback?(true, self.createGroupInfo, self.submitShowImage)
                self.dismiss(animated: true, completion: nil)
            }
        }, fail: { [weak self] code, msg in
            guard let self = self else { return }
            if code == ERR_SDK_INTERFACE_NOT_SUPPORT.rawValue {
                TUITool.postUnsupportNotification(ofService: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunity"), serviceDesc: TUISwift.timCommonLocalizableString("TUIKitErrorUnsupportIntefaceCommunityDesc"), debugOnly: true)
            } else {
                var toastMsg = TUITool.convertIMError(Int(code), msg: msg) ?? ""
                if toastMsg.count == 0 {
                    toastMsg = "\(code)"
                }
                TUITool.hideToastActivity()
                TUITool.makeToast(toastMsg, duration: 3.0, idposition: TUICSToastPositionBottom)
            }
            self.submitCallback?(false, self.createGroupInfo, self.submitShowImage)
            self.dismiss(animated: true, completion: nil)
        })
    }

    // MARK: - TUIChatFloatSubViewControllerProtocol

    func floatControllerLeftButtonClick() {
        dismiss(animated: true, completion: nil)
    }

    func floatControllerRightButtonClick() {
        finishTask()
    }
}
