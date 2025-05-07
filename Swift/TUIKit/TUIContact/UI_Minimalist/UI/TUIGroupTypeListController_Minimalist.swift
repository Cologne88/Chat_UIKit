import TIMCommon
import UIKit

class TUIGroupTypeData_Minimalist {
    var image: UIImage?
    var title: String?
    var describeText: String?
    var groupType: String?
    var cellHeight: CGFloat = 0.0
    var isSelect: Bool = false
    
    func caculateCellHeight() {
        guard let descStr = describeText else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        if #available(iOS 9.0, *) {
            paragraphStyle.allowsDefaultTighteningForTruncation = true
        }
        paragraphStyle.alignment = .justified
        let rect = descStr.boundingRect(
            with: CGSize(width: TUISwift.screen_Width() - TUISwift.kScale390(32) - TUISwift.kScale390(30), height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.paragraphStyle: paragraphStyle],
            context: nil
        )
        
        let height = ceil(rect.height) + 1
        
        cellHeight = 12 + 22 + 8 + height + 16
    }
}

class TUIGroupTypeCell_Minimalist: UITableViewCell {
    private var customMaskView: UIView!
//    private var imageView: UIImageView = .init()
    private var title: UILabel!
    private var describeTextViewRect: CGRect = .zero
    private var cellData: TUIGroupTypeData_Minimalist?
    
    lazy var describeTextView: UITextView = {
        let describeTextView = UITextView()
        describeTextView.backgroundColor = .clear
        describeTextView.textAlignment = TUISwift.isRTL() ? .right : .left
        describeTextView.isEditable = false
        describeTextView.isScrollEnabled = false
        describeTextView.textContainerInset = .zero
        return describeTextView
    }()
    
    lazy var selectedView: UIImageView = {
        let selectedView = UIImageView(frame: .zero)
        selectedView.image = UIImage.safeImage(TUISwift.timCommonImagePath("icon_avatar_selected"))
        return selectedView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#FFFFFF")
        
        customMaskView = UIView(frame: .zero)
        customMaskView.layer.masksToBounds = true
        customMaskView.layer.borderWidth = TUISwift.kScale390(1)
        customMaskView.layer.borderColor = UIColor.tui_color(withHex: "#DDDDDD").cgColor
        customMaskView.layer.cornerRadius = TUISwift.kScale390(16)
        contentView.addSubview(customMaskView)
        
        title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        title.numberOfLines = 0
        customMaskView.addSubview(title)
        
        customMaskView.addSubview(describeTextView)
        customMaskView.addSubview(selectedView)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        customMaskView.snp.remakeConstraints { make in
            make.leading.equalTo(TUISwift.kScale390(16))
            make.top.equalTo(0)
            make.trailing.equalTo(self.snp.trailing).offset(-TUISwift.kScale390(16))
            make.height.equalTo(self)
        }
        
        if !selectedView.isHidden {
            selectedView.snp.remakeConstraints { make in
                make.leading.equalTo(TUISwift.kScale390(16))
                make.top.equalTo(TUISwift.kScale390(15))
                make.width.height.equalTo(TUISwift.kScale390(16))
            }
        }
        
        title.snp.remakeConstraints { make in
            if selectedView.isHidden {
                make.leading.equalTo(customMaskView).offset(TUISwift.kScale390(16))
            } else {
                make.leading.equalTo(selectedView.snp.trailing).offset(10)
            }
            make.trailing.equalTo(customMaskView.snp.trailing).offset(-10)
            make.height.equalTo(24)
            make.top.equalTo(TUISwift.kScale390(12))
        }
        
        describeTextView.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(16)
            make.trailing.equalTo(contentView).offset(-16)
            make.top.equalTo(title.snp.bottom).offset(TUISwift.kScale390(8))
            make.height.equalTo(describeTextViewRect.size.height)
        }
    }
    
    func setData(_ data: TUIGroupTypeData_Minimalist) {
        cellData = data
//        imageView?.image = data.image
        title.text = data.title
        updateRectAndTextForDescribeTextView(describeTextView, groupType: data.groupType)
        if data.isSelect {
            customMaskView.layer.borderColor = TUISwift.timCommonDynamicColor("", defaultColor: "#006EFF").cgColor
            selectedView.isHidden = false
        } else {
            customMaskView.layer.borderColor = UIColor.tui_color(withHex: "#DDDDDD").cgColor
            selectedView.isHidden = true
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    private func updateRectAndTextForDescribeTextView(_ describeTextView: UITextView, groupType: String?) {
        guard let descStr = cellData?.describeText else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        if #available(iOS 9.0, *) {
            paragraphStyle.allowsDefaultTighteningForTruncation = true
        }
        paragraphStyle.alignment = TUISwift.isRTL() ? .right : .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.tui_color(withHex: "#888888"),
            .paragraphStyle: paragraphStyle
        ]
        let attributedString = NSMutableAttributedString(string: descStr, attributes: attributes)
        describeTextView.attributedText = attributedString
        
        let rect = descStr.boundingRect(
            with: CGSize(width: TUISwift.screen_Width() - 32, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.paragraphStyle: paragraphStyle],
            context: nil
        )
        
        describeTextViewRect = CGRect(x: 0, y: 0, width: ceil(rect.width) + 1, height: ceil(rect.height) + 1)
    }
}

class TUIGroupTypeListController_Minimalist: UIViewController, UITableViewDataSource, UITableViewDelegate, TUIFloatSubViewControllerProtocol {
    var floatDataSourceChanged: (([Any]) -> Void)?
    
    var cacheGroupType: String?
    var selectCallBack: ((String) -> Void)?
    
    private var tableView: UITableView!
    private var titleView: TUINaviBarIndicatorView!
    private var data: [TUIGroupTypeData_Minimalist] = []
    private var bottomButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupView()
    }
    
    private func setupData() {
        data = []
        
        // Work
        let dataWork = TUIGroupTypeData_Minimalist()
        dataWork.groupType = "Work"
        dataWork.image = TUISwift.defaultGroupAvatarImage(byGroupType: "Work")
        dataWork.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work")
        dataWork.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work_Desc"))\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
        dataWork.caculateCellHeight()
        data.append(dataWork)
        if cacheGroupType == "Work" {
            dataWork.isSelect = true
        }
        
        // Public
        let dataPublic = TUIGroupTypeData_Minimalist()
        dataPublic.groupType = "Public"
        dataPublic.image = TUISwift.defaultGroupAvatarImage(byGroupType: "Public")
        dataPublic.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public")
        dataPublic.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public_Desc"))\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
        dataPublic.caculateCellHeight()
        data.append(dataPublic)
        if cacheGroupType == "Public" {
            dataPublic.isSelect = true
        }
        
        // Meeting
        let dataMeeting = TUIGroupTypeData_Minimalist()
        dataMeeting.groupType = "Meeting"
        dataMeeting.image = TUISwift.defaultGroupAvatarImage(byGroupType: "Meeting")
        dataMeeting.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting")
        dataMeeting.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting_Desc"))\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
        dataMeeting.caculateCellHeight()
        data.append(dataMeeting)
        if cacheGroupType == "Meeting" {
            dataMeeting.isSelect = true
        }
        
        // Community
        let dataCommunity = TUIGroupTypeData_Minimalist()
        dataCommunity.groupType = "Community"
        dataCommunity.image = TUISwift.defaultGroupAvatarImage(byGroupType: "Community")
        dataCommunity.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community")
        dataCommunity.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community_Desc"))\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc"))"
        dataCommunity.caculateCellHeight()
        data.append(dataCommunity)
        if cacheGroupType == "Community" {
            dataCommunity.isSelect = true
        }
    }
    
    private func setupView() {
        tableView = UITableView(frame: .zero, style: .plain)
        view.addSubview(tableView)
        var rect = view.bounds
        rect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height - TUISwift.kScale390(87.5))
        
        tableView.frame = rect
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        titleView = TUINaviBarIndicatorView()
        titleView.setTitle(TUISwift.timCommonLocalizableString("ChatsNewGroupText"))
        navigationItem.titleView = titleView
        navigationItem.title = ""
        
        let bottomView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 140))
        tableView.tableFooterView = bottomView
        
        bottomButton = UIButton(type: .custom)
        bottomView.addSubview(bottomButton)
        bottomButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        bottomButton.setTitle(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc_Simple"), for: .normal)
        bottomButton.setTitleColor(.systemBlue, for: .normal)
        bottomButton.frame = CGRect(x: 15, y: 30, width: view.frame.width - 30, height: 18)
        bottomButton.addTarget(self, action: #selector(bottomButtonClick), for: .touchUpInside)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return data[indexPath.section].cellHeight
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TUIGroupTypeCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? TUIGroupTypeCell_Minimalist
        if cell == nil {
            cell = TUIGroupTypeCell_Minimalist(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .none
        }
        cell?.setData(data[indexPath.section])
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedData = data[indexPath.section]
        data.forEach { $0.isSelect = false }
        selectedData.isSelect = true
        tableView.reloadData()
        
        selectCallBack?(selectedData.groupType ?? "Public")
    }
    
    @objc private func bottomButtonClick() {
        if let url = URL(string: "https://cloud.tencent.com/product/im") {
            TUITool.openLink(with: url)
        }
    }

    // MARK: - TUIChatFloatSubViewControllerProtocol

    func floatControllerLeftButtonClick() {
        dismiss(animated: true, completion: nil)
    }

    func floatControllerRightButtonClick() {
        dismiss(animated: true, completion: nil)
    }
}
