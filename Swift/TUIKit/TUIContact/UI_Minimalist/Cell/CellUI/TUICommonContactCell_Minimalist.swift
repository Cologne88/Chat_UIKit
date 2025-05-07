//  TUICommonContactCell_Minimalist.swift
//  TUIContact

import TIMCommon
import UIKit

class TUICommonContactCell_Minimalist: TUICommonTableViewCell {
    let avatarView = UIImageView()
    let titleLabel = UILabel()
    // The icon of indicating the user's online status
    var onlineStatusIcon = UIImageView()
    var separtorView = UIView()
    private(set) var contactData: TUICommonContactCellData_Minimalist?
    private var faceUrlObservation: NSKeyValueObservation?
    private var displayOnlineStatusIconObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#FFFFFF")
        avatarView.image = TUISwift.defaultAvatarImage()
        contentView.addSubview(avatarView)

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("", defaultColor: "#000000")

        contentView.addSubview(onlineStatusIcon)

        separtorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        contentView.addSubview(separtorView)
        separtorView.isHidden = true

        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        faceUrlObservation?.invalidate()
        faceUrlObservation = nil

        displayOnlineStatusIconObservation?.invalidate()
        displayOnlineStatusIconObservation = nil
    }

    override func fill(with contactData: TUICommonCellData) {
        guard let contactData = contactData as? TUICommonContactCellData_Minimalist else { return }

        super.fill(with: contactData)
        self.contactData = contactData

        titleLabel.text = contactData.title
        configHeadImageView(contactData)

        displayOnlineStatusIconObservation = TUIConfig.default().observe(\.displayOnlineStatusIcon, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            if contactData.onlineStatus == .online && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = false
                self.onlineStatusIcon.image = TUISwift.timCommonDynamicImage("icon_online_status", defaultImage: UIImage.safeImage(TUISwift.timCommonImagePath("icon_online_status")))
            } else if contactData.onlineStatus == .offline && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = false
                self.onlineStatusIcon.image = TUISwift.timCommonDynamicImage("icon_offline_status", defaultImage: UIImage.safeImage(TUISwift.timCommonImagePath("icon_offline_status")))
            } else {
                self.onlineStatusIcon.isHidden = true
                self.onlineStatusIcon.image = nil
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
        let imgWidth = TUISwift.kScale390(40)

        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(TUISwift.kScale390(16))
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.greaterThanOrEqualTo(contentView.snp.trailing)
        }

        onlineStatusIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale375(15))
            make.trailing.equalTo(avatarView.snp.trailing).offset(TUISwift.kScale375(5))
            make.bottom.equalTo(avatarView.snp.bottom)
        }
        onlineStatusIcon.layer.cornerRadius = 0.5 * TUISwift.kScale375(15)

        separtorView.snp.remakeConstraints { make in
            make.width.equalTo(contentView.snp.width)
            make.height.equalTo(1)
            make.leading.equalTo(avatarView.snp.trailing)
            make.bottom.equalTo(self.snp.bottom).offset(-1)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func configHeadImageView(_ convData: TUICommonContactCellData_Minimalist) {
        if let groupID = convData.groupID, let type = convData.groupType {
            convData.avatarImage = TUIGroupAvatar.getNormalGroupCacheAvatar(groupID: groupID, groupType: type)
        }

        faceUrlObservation = convData.observe(\.faceUrl, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let _ = change.newValue else { return }
            let groupID = convData.groupID ?? ""
            let pFaceUrl = convData.faceUrl ?? ""
            let groupType = convData.groupType
            let originAvatarImage: UIImage?
            if groupID.count > 0 {
                originAvatarImage = convData.avatarImage ?? TUISwift.defaultGroupAvatarImage(byGroupType: groupType)
            } else {
                originAvatarImage = convData.avatarImage ?? TUISwift.defaultAvatarImage()
            }
            let param: [String: Any] = [
                "groupID": groupID,
                "faceUrl": pFaceUrl,
                "groupType": groupType,
                "originAvatarImage": originAvatarImage as Any
            ]
            TUIGroupAvatar.configAvatar(by: param, targetView: self.avatarView)
        }
    }
}
