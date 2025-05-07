import TIMCommon
import UIKit

class TUISearchResultCell: UITableViewCell {
    let avatarView = UIImageView()
    let title_label = UILabel()
    private var detail_title = UILabel()
    private var separatorView = UIView()
    private var cellModel: TUISearchResultCellModel?

    private var avatarUrlObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        contentView.addSubview(avatarView)

        title_label.text = ""
        title_label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        title_label.font = UIFont.systemFont(ofSize: 14.0)
        title_label.rtlAlignment = TUITextRTLAlignment.leading
        contentView.addSubview(title_label)

        detail_title.text = ""
        detail_title.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        detail_title.font = UIFont.systemFont(ofSize: 12.0)
        detail_title.rtlAlignment = TUITextRTLAlignment.leading
        contentView.addSubview(detail_title)

        separatorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        contentView.addSubview(separatorView)

        selectionStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Layout code here if needed
    }

    func fillWithData(_ cellModel: TUISearchResultCellModel) {
        self.cellModel = cellModel

        title_label.text = nil
        title_label.attributedText = nil
        detail_title.text = nil
        detail_title.attributedText = nil

        title_label.text = cellModel.title
        if let titleAttributeString = cellModel.titleAttributeString {
            title_label.attributedText = titleAttributeString
        }
        detail_title.text = cellModel.details
        if let detailsAttributeString = cellModel.detailsAttributeString {
            detail_title.attributedText = detailsAttributeString
        }

        // Setup default avatar
        if let groupID = cellModel.groupID, !groupID.isEmpty {
            var avatar: UIImage? = nil
            if TUIConfig.default().enableGroupGridAvatar {
                let key = "TUIConversationLastGroupMember_\(groupID)"
                let member = UserDefaults.standard.integer(forKey: key)
                avatar = TUIGroupAvatar.getCacheAvatar(forGroup: groupID, number: UInt32(member))
            }
            cellModel.avatarImage = avatar ?? TUISwift.defaultGroupAvatarImage(byGroupType: cellModel.groupType)
        }

        avatarUrlObservation = cellModel.observe(\.avatarUrl, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let faceUrl = change.newValue else { return }
            if let modelGroupID = cellModel.groupID, !modelGroupID.isEmpty {
                if let faceUrl = faceUrl, !faceUrl.isEmpty {
                    self.avatarView.sd_setImage(with: URL(string: faceUrl), placeholderImage: self.cellModel?.avatarImage)
                } else {
                    if TUIConfig.default().enableGroupGridAvatar {
                        self.avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                        TUIGroupAvatar.getCacheGroupAvatar(modelGroupID) { avatar, groupID in
                            let avatar: UIImage? = avatar
                            if groupID == modelGroupID {
                                if avatar != nil {
                                    self.avatarView.sd_setImage(with: nil, placeholderImage: avatar)
                                } else {
                                    self.avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                                    TUIGroupAvatar.fetchGroupAvatars(groupID, placeholder: cellModel.avatarImage ?? UIImage()) { success, image, groupID in
                                        if groupID == modelGroupID {
                                            self.avatarView.sd_setImage(with: nil, placeholderImage: success ? image : TUISwift.defaultGroupAvatarImage(byGroupType: self.cellModel?.groupType))
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        self.avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                    }
                }
            } else {
                self.avatarView.sd_setImage(with: URL(string: faceUrl ?? ""), placeholderImage: self.cellModel?.avatarImage)
            }
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        let headSize = CGSize(width: TUISwift.kScale390(40), height: TUISwift.kScale390(40))

        avatarView.snp.remakeConstraints { make in
            make.size.equalTo(headSize)
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(TUISwift.kScale390(10))
        }

        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        let title = title_label.text ?? title_label.attributedText?.string ?? ""
        let detail = detail_title.text ?? detail_title.attributedText?.string ?? ""
        title_label.sizeToFit()
        detail_title.sizeToFit()

        if !title.isEmpty && !detail.isEmpty {
            title_label.snp.remakeConstraints { make in
                make.top.equalTo(avatarView.snp.top)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(title_label.frame.size.height)
            }

            detail_title.snp.remakeConstraints { make in
                make.bottom.equalTo(avatarView.snp.bottom)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(detail_title.frame.size.height)
            }
        } else {
            title_label.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarView.snp.centerY)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(title_label.frame.size.height)
            }

            detail_title.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarView.snp.centerY)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(detail_title.frame.size.height)
            }
        }

        separatorView.snp.remakeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing)
            make.bottom.equalTo(contentView.snp.bottom).offset(-1)
            make.width.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
}
