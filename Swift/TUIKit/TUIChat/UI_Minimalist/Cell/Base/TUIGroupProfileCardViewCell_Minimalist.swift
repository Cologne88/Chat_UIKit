import TIMCommon
import TUICore
import UIKit

class TUIGroupProfileHeaderItemView_Minimalist: UIView {
    var iconView: UIImageView!
    var textLabel: UILabel!
    var messageBtnClickBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        iconView = UIImageView(image: TUISwift.defaultAvatarImage())
        addSubview(iconView)
        iconView.isUserInteractionEnabled = true
        iconView.contentMode = .scaleAspectFit

        textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.tui_color(withHex: "#000000")
        textLabel.isUserInteractionEnabled = true
        addSubview(textLabel)
        textLabel.text = "Message"

        backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        layer.cornerRadius = TUISwift.kScale390(12)
        layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        addGestureRecognizer(tap)
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        iconView.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale390(30))
            make.top.equalTo(TUISwift.kScale390(19))
            make.centerX.equalTo(self)
        }
        textLabel.sizeToFit()
        textLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.height.equalTo(TUISwift.kScale390(19))
            make.top.equalTo(iconView.snp.bottom).offset(TUISwift.kScale390(11))
            make.centerX.equalTo(self)
        }
    }

    @objc private func click() {
        messageBtnClickBlock?()
    }
}

class TUIGroupProfileHeaderView_Minimalist: UIView {
    var headImg: UIImageView!
    var descriptionLabel: UILabel!
    var editButton: UIButton!
    var idLabel: UILabel!
    var functionListView: UIView!
    var itemViewList: [TUIGroupProfileHeaderItemView_Minimalist]?
    
    var groupInfo: V2TIMGroupInfo? {
        didSet {
            guard let groupInfo = groupInfo else { return }
            headImg.sd_setImage(with: URL(string: groupInfo.faceURL.safeValue), placeholderImage: TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType))
            configHeadImageView(groupInfo)
            descriptionLabel.text = groupInfo.groupName
            idLabel.text = groupInfo.groupID
            editButton.isHidden = !TUIGroupProfileHeaderView_Minimalist.isMeSuper(groupInfo)
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    var headImgClickBlock: (() -> Void)?
    var editBtnClickBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        headImg = UIImageView(image: TUISwift.defaultAvatarImage())
        addSubview(headImg)
        headImg.isUserInteractionEnabled = true
        headImg.contentMode = .scaleAspectFit
        let tap = UITapGestureRecognizer(target: self, action: #selector(headImageClick))
        headImg.addGestureRecognizer(tap)

        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(24))
        descriptionLabel.textAlignment = .center
        descriptionLabel.isUserInteractionEnabled = true
        addSubview(descriptionLabel)

        editButton = UIButton(type: .system)
        addSubview(editButton)
        editButton.setImage(UIImage(named: TUISwift.tuiContactImagePath("icon_group_edit")), for: .normal)
        editButton.addTarget(self, action: #selector(editButtonClick), for: .touchUpInside)
        editButton.isHidden = true

        idLabel = UILabel()
        idLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        idLabel.textColor = UIColor.tui_color(withHex: "666666")
        idLabel.textAlignment = .center
        idLabel.isUserInteractionEnabled = true
        addSubview(idLabel)

        functionListView = UIView()
        functionListView.isUserInteractionEnabled = true
        addSubview(functionListView)
    }

    private func configHeadImageView(_ groupInfo: V2TIMGroupInfo) {
        guard let groupID = groupInfo.groupID, let pFaceUrl = groupInfo.faceURL, let groupType = groupInfo.groupType else { return }
        let originAvatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: groupInfo.groupType) ?? UIImage()
        let param: [String: Any] = [
            "groupID": groupID,
            "faceUrl": pFaceUrl,
            "groupType": groupType,
            "originAvatarImage": originAvatarImage
        ]
        TUIGroupAvatar.configAvatar(byParam: param, targetView: headImg)
    }

    func setCustomItemViewList(_ itemList: [TUIGroupProfileHeaderItemView_Minimalist]) {
        itemViewList = itemList
        functionListView.subviews.forEach { $0.removeFromSuperview() }
        guard !itemList.isEmpty else { return }
        itemList.forEach { functionListView.addSubview($0) }
        let width = TUISwift.kScale390(92)
        let height = TUISwift.kScale390(95)
        let space = TUISwift.kScale390(18)
        let contentWidth = CGFloat(itemList.count) * width + CGFloat(itemList.count - 1) * space
        var x = 0.5 * (bounds.size.width - contentWidth)
        for item in itemList {
            item.frame = CGRect(x: x, y: 0, width: width, height: height)
            x = item.frame.maxX + space
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        let imgWidth = TUISwift.kScale390(94)
        headImg.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(TUISwift.kScale390(42))
        }

        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            headImg.layer.masksToBounds = true
            headImg.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            headImg.layer.masksToBounds = true
            headImg.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        descriptionLabel.sizeToFit()
        descriptionLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(headImg.snp.bottom).offset(TUISwift.kScale390(10))
            make.height.equalTo(30)
            make.width.equalTo(descriptionLabel.frame.size.width)
            make.width.lessThanOrEqualTo(self).multipliedBy(0.5)
        }

        editButton.snp.remakeConstraints { make in
            make.leading.equalTo(descriptionLabel.snp.trailing).offset(TUISwift.kScale390(3))
            make.top.equalTo(descriptionLabel.snp.top)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }

        idLabel.snp.remakeConstraints { make in
            make.leading.equalTo(self.snp.leading)
            make.top.equalTo(descriptionLabel.snp.bottom).offset(TUISwift.kScale390(8))
            make.height.equalTo(30)
            make.width.equalTo(self.frame.size.width)
        }

        if functionListView.subviews.count > 0 {
            functionListView.snp.remakeConstraints { make in
                make.leading.equalTo(0)
                make.width.equalTo(bounds.size.width)
                make.height.equalTo(TUISwift.kScale390(95))
                make.top.equalTo(idLabel.snp.bottom).offset(TUISwift.kScale390(18))
            }
        }
    }

    @objc private func headImageClick() {
        if let headImgClickBlock = headImgClickBlock, TUIGroupProfileHeaderView_Minimalist.isMeSuper(groupInfo) {
            headImgClickBlock()
        }
    }

    @objc private func editButtonClick() {
        if let editBtnClickBlock = editBtnClickBlock, TUIGroupProfileHeaderView_Minimalist.isMeSuper(groupInfo) {
            editBtnClickBlock()
        }
    }

    static func isMeSuper(_ groupInfo: V2TIMGroupInfo?) -> Bool {
        guard let groupInfo = groupInfo else { return false }
        return groupInfo.owner == V2TIMManager.sharedInstance().getLoginUser() && groupInfo.role == V2TIMGroupMemberRole.GROUP_MEMBER_ROLE_SUPER.rawValue
    }
}

class TUIGroupProfileCardViewCell_Minimalist: UITableViewCell {
    var headerView: TUIGroupProfileHeaderView_Minimalist!
    var cardData: TUIGroupProfileCardCellData_Minimalist?
    var itemViewList: [TUIGroupProfileHeaderItemView_Minimalist]?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        headerView = TUIGroupProfileHeaderView_Minimalist(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: TUISwift.kScale390(355)))
        contentView.addSubview(headerView)
    }

    func fill(with data: TUIGroupProfileCardCellData_Minimalist) {
        cardData = data
        headerView.headImg.sd_setImage(with: data.avatarUrl, placeholderImage: data.avatarImage)
        headerView.descriptionLabel.text = data.name
        headerView.idLabel.text = "ID: \(data.identifier)"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if headerView.functionListView.subviews.count > 0 {
            headerView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: TUISwift.kScale390(355))
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: TUISwift.kScale390(257))
        }
        headerView.descriptionLabel.sizeToFit()
        headerView.itemViewList = itemViewList
    }
}
