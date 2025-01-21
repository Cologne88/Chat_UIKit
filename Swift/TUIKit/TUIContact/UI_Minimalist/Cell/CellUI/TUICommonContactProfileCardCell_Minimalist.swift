//  TUICommonContactProfileCardCell_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon

protocol TUIContactProfileCardDelegate_Minimalist: AnyObject {
    func didTapOnAvatar(_ cell: TUICommonContactProfileCardCell_Minimalist)
}

class TUICommonContactProfileCardCellData_Minimalist: TUICommonCellData {
    var avatarImage: UIImage?
    @objc dynamic var avatarUrl: URL?
    var name: String?
    var identifier: String?
    var signature: String?
    var genderIconImage: UIImage?
    var genderString: String?
    var showAccessory: Bool = false
    var showSignature: Bool = false
}

class TUICommonContactProfileCardCell_Minimalist: TUICommonTableViewCell {
    let avatar = UIImageView()
    let name = UILabel()
    let identifier = UILabel()
    let signature = UILabel()
    let genderIcon = UIImageView()
    var cardData: TUICommonContactProfileCardCellData_Minimalist?
    weak var delegate: TUIContactProfileCardDelegate_Minimalist?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let headSize = CGSize(width: TUISwift.kScale390(43), height: TUISwift.kScale390(43))
        avatar.frame = CGRect(x: TUISwift.kScale390(16), y: TUISwift.kScale390(10), width: headSize.width, height: headSize.height)
        avatar.contentMode = .scaleAspectFit
        avatar.layer.cornerRadius = 4
        avatar.layer.masksToBounds = true

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(onTapAvatar))
        avatar.addGestureRecognizer(tapAvatar)
        avatar.isUserInteractionEnabled = true
        contentView.addSubview(avatar)

        genderIcon.contentMode = .scaleAspectFit
        genderIcon.image = cardData?.genderIconImage
        contentView.addSubview(genderIcon)

        name.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(16))
        name.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        contentView.addSubview(name)

        identifier.font = UIFont.systemFont(ofSize: 13)
        identifier.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        contentView.addSubview(identifier)

        signature.font = UIFont.systemFont(ofSize: 14)
        signature.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        contentView.addSubview(signature)

        selectionStyle = .none
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUICommonContactProfileCardCellData_Minimalist else { return }

        super.fill(with: data)
        cardData = data
        signature.isHidden = !data.showSignature

        // set data
        _ = data.signature.map { signature.text = $0 }
        _ = data.identifier.map { identifier.text = "ID: \($0)" }
        _ = data.name.map { name.text = $0 }
        _ = data.avatarUrl.map { avatar.sd_setImage(with: $0, placeholderImage: cardData?.avatarImage) }

        if let genderString = data.genderString {
            if genderString == TUISwift.timCommonLocalizableString("Male") {
                genderIcon.image = TUISwift.tuiContactCommonBundleImage("male")
            } else if genderString == TUISwift.timCommonLocalizableString("Female") {
                genderIcon.image = TUISwift.tuiContactCommonBundleImage("female")
            } else {
                genderIcon.image = nil
            }
        }

        accessoryType = data.showAccessory ? .disclosureIndicator : .none
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        let headSize = CGSize(width: TUISwift.kScale390(43), height: TUISwift.kScale390(43))

        avatar.snp.remakeConstraints { make in
            make.size.equalTo(headSize)
            make.top.equalTo(TUISwift.kScale390(10))
            make.leading.equalTo(TUISwift.kScale390(16))
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatar.layer.masksToBounds = true
            avatar.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatar.layer.masksToBounds = true
            avatar.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        name.sizeToFit()
        name.snp.remakeConstraints { make in
            make.top.equalTo(CGFloat(TPersonalCommonCell_Margin))
            make.leading.equalTo(avatar.snp.trailing).offset(15)
            make.width.lessThanOrEqualTo(name.frame.size.width)
            make.height.greaterThanOrEqualTo(name.frame.size.height)
            make.trailing.lessThanOrEqualTo(genderIcon.snp.leading).offset(-1)
        }

        genderIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(name.font.pointSize * 0.9)
            make.centerY.equalTo(name)
            make.leading.equalTo(name.snp.trailing).offset(1)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-10)
        }

        identifier.sizeToFit()
        identifier.snp.remakeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(5)
            make.width.greaterThanOrEqualTo(max(identifier.frame.size.width, 80))
            make.height.greaterThanOrEqualTo(identifier.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
        }

        if cardData?.showSignature == true {
            signature.sizeToFit()
            signature.snp.remakeConstraints { make in
                make.leading.equalTo(name)
                make.top.equalTo(identifier.snp.bottom).offset(5)
                make.width.greaterThanOrEqualTo(max(signature.frame.size.width, 80))
                make.height.greaterThanOrEqualTo(signature.frame.size.height)
                make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
            }
        } else {
            signature.frame = .zero
        }
    }

    @objc private func onTapAvatar() {
        delegate?.didTapOnAvatar(self)
    }
}
