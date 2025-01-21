import TIMCommon
import UIKit

class TUIGroupTypeData: NSObject {
    var image: UIImage?
    var title: String?
    var describeText: String?
    var groupType: String?
    var cellHeight: CGFloat = 0.0

    func caculateCellHeight() {
        guard let descStr = describeText else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 18
        if #available(iOS 9.0, *) {
            paragraphStyle.allowsDefaultTighteningForTruncation = true
        }
        paragraphStyle.alignment = .justified
        let rect = descStr.boundingRect(
            with: CGSize(width: TUISwift.screen_Width() - 32, height: CGFloat(Int.max)),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.paragraphStyle: paragraphStyle],
            context: nil
        )

        let height = ceil(rect.height) + 1
        cellHeight = 12 + 40 + 8 + height + 16
    }
}

class TUIGroupTypeCell: UITableViewCell {
    var image: UIImageView!
    var title: UILabel!
    var describeTextViewRect: CGRect = .zero
    var cellData: TUIGroupTypeData?

    lazy var describeTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.textAlignment = TUISwift.isRTL() ? .right : .left
        return textView
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
        backgroundColor = UIColor(named: "form_bg_color") ?? UIColor.white

        image = UIImageView()
        image.contentMode = .scaleAspectFit
        contentView.addSubview(image)

        title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = UIColor(named: "form_title_color") ?? UIColor.black
        title.textAlignment = TUISwift.isRTL() ? .right : .left
        title.numberOfLines = 0
        contentView.addSubview(title)

        contentView.addSubview(describeTextView)
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        image.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(16)
            make.top.equalTo(contentView).offset(16)
            make.width.height.equalTo(40)
        }

        title.sizeToFit()
        title.snp.remakeConstraints { make in
            make.leading.equalTo(image.snp.trailing).offset(10)
            make.centerY.equalTo(image)
            make.trailing.equalTo(contentView).offset(-4)
        }

        describeTextView.snp.remakeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(contentView).offset(-16)
            make.top.equalTo(image.snp.bottom).offset(8)
            make.height.equalTo(describeTextViewRect.size.height)
        }
    }

    func setData(_ data: TUIGroupTypeData) {
        cellData = data
        image.image = data.image
        title.text = data.title
        updateRectAndTextForDescribeTextView(describeTextView, groupType: data.groupType)
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
            .foregroundColor: UIColor(named: "#888888") ?? UIColor.gray,
            .paragraphStyle: paragraphStyle
        ]
        let attributedString = NSMutableAttributedString(string: descStr, attributes: attributes)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: descStr.count))
        describeTextView.attributedText = attributedString

        let rect = descStr.boundingRect(with: CGSize(width: TUISwift.screen_Width() - 32, height: CGFloat(Int.max)),
                                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                                        attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle],
                                        context: nil)

        describeTextViewRect = CGRect(x: 0, y: 0, width: ceil(rect.width) + 1, height: ceil(rect.height) + 1)
    }
}

class TUIGroupTypeListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var selectCallBack: ((String) -> Void)?

    private var tableView: UITableView!
    private var titleView: TUINaviBarIndicatorView!
    private var data: [TUIGroupTypeData] = []
    private var bottomButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData()
        setupView()
    }

    private func setupData() {
        // work
        let dataWork = TUIGroupTypeData()
        dataWork.groupType = GroupType_Work
        dataWork.image = TUISwift.defaultGroupAvatarImage(byGroupType: GroupType_Work)
        dataWork.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work")
        dataWork.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Work_Desc") ?? "")\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc") ?? "")"
        dataWork.caculateCellHeight()
        data.append(dataWork)

        // Public
        let dataPublic = TUIGroupTypeData()
        dataPublic.groupType = GroupType_Public
        dataPublic.image = TUISwift.defaultGroupAvatarImage(byGroupType: GroupType_Public)
        dataPublic.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public")
        dataPublic.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Public_Desc") ?? "")\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc") ?? "")"
        dataPublic.caculateCellHeight()
        data.append(dataPublic)

        // Meeting
        let dataMeeting = TUIGroupTypeData()
        dataMeeting.groupType = GroupType_Meeting
        dataMeeting.image = TUISwift.defaultGroupAvatarImage(byGroupType: GroupType_Meeting)
        dataMeeting.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting")
        dataMeeting.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Meeting_Desc") ?? "")\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc") ?? "")"
        dataMeeting.caculateCellHeight()
        data.append(dataMeeting)

        // Community
        let dataCommunity = TUIGroupTypeData()
        dataCommunity.groupType = GroupType_Community
        dataCommunity.image = TUISwift.defaultGroupAvatarImage(byGroupType: GroupType_Community)
        dataCommunity.title = TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community")
        dataCommunity.describeText = "\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_Community_Desc") ?? "")\(TUISwift.timCommonLocalizableString("TUIKitCreatGroupType_See_Doc") ?? "")"
        dataCommunity.caculateCellHeight()
        data.append(dataCommunity)
    }

    private func setupView() {
        tableView = UITableView(frame: .zero, style: .plain)
        view.addSubview(tableView)
        tableView.frame = view.frame
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.groupTableViewBackground
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
        bottomButton.frame = CGRect(x: 15, y: 40, width: view.frame.width - 30, height: 18)
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
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? TUIGroupTypeCell
        if cell == nil {
            cell = TUIGroupTypeCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell?.selectionStyle = .none
        }
        cell?.setData(data[indexPath.section])
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.data[indexPath.section]
        if let groupType = data.groupType {
            selectCallBack?(groupType)
        }
        navigationController?.popViewController(animated: true)
    }

    @objc private func bottomButtonClick() {
        if let url = URL(string: "https://cloud.tencent.com/product/im") {
            TUITool.openLink(with: url)
        }
    }
}
