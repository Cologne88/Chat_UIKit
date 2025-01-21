import ReactiveObjC
import TIMCommon
import UIKit

class TUIConversationForwardSelectCell_Minimalist: UITableViewCell {
    var selectButton: UIButton!
    var avatarView: UIImageView!
    var titleLabel: UILabel!
    var selectData: TUIConversationCellData?
    let faceUrlObserver = Observer()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        selectData?.faceUrl.removeObserver(faceUrlObserver)
    }

    private func setupViews() {
        selectButton = UIButton(type: .custom)
        contentView.addSubview(selectButton)
        selectButton.setImage(UIImage(named: TUISwift.timCommonImagePath("icon_select_normal")), for: .normal)
        selectButton.setImage(UIImage(named: TUISwift.timCommonImagePath("icon_select_pressed")), for: .highlighted)
        selectButton.setImage(UIImage(named: TUISwift.timCommonImagePath("icon_select_selected")), for: .selected)
        selectButton.setImage(UIImage(named: TUISwift.timCommonImagePath("icon_select_selected_disable")), for: .disabled)
        selectButton.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        selectButton.isUserInteractionEnabled = false

        avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
        contentView.addSubview(avatarView)
        avatarView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        titleLabel = UILabel()
        contentView.addSubview(titleLabel)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]

        selectionStyle = .none
    }

//    There is no such method in swift
//    override func setFrame(_ frame: CGRect) {
//        var newFrame = frame
//        newFrame.size.width = Screen_Width
//        super.setFrame(newFrame)
//    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        let imgWidth: CGFloat = TUISwift.kScale390(40)
        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(TUISwift.kScale390(16))
        }
        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        selectButton.sizeToFit()
        selectButton.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).offset(-TUISwift.kScale390(42))
            make.size.equalTo(selectButton.frame.size)
        }
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.greaterThanOrEqualTo(contentView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func fillWithData(_ selectData: TUIConversationCellData) {
        self.selectData = selectData
        titleLabel.text = selectData.title.value
        configHeadImageView(selectData)
        selectButton.isSelected = selectData.selected
        selectButton.isHidden = !selectData.showCheckBox

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    private func configHeadImageView(_ convData: TUIConversationCellData) {
        if let groupID = convData.groupID, groupID.count > 0 {
            convData.avatarImage = TUIGroupAvatar.getNormalGroupCacheAvatar(groupID, groupType: convData.groupType ?? "")
        }

        convData.faceUrl.addObserver(faceUrlObserver) { [weak self] _, _ in
            guard let self = self else { return }
            let groupID = convData.groupID ?? ""
            let pFaceUrl = convData.faceUrl.value
            let groupType = convData.groupType ?? ""
            let originAvatarImage: UIImage? = convData.avatarImage ?? (groupID.count > 0 ? TUISwift.defaultGroupAvatarImage(byGroupType: groupType) : TUISwift.defaultAvatarImage())
            let param: [String: Any] = [
                "groupID": groupID,
                "faceUrl": pFaceUrl,
                "groupType": groupType,
                "originAvatarImage": originAvatarImage ?? UIImage()
            ]
            TUIGroupAvatar.configAvatar(byParam: param, targetView: self.avatarView)
        }
        convData.faceUrl.value = convData.faceUrl.value
    }
}
