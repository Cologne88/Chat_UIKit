// TUIProfileCardCell_Minimalist.swift
// TUIContact

import UIKit
import TIMCommon

class TUIProfileCardCell_Minimalist: TUICommonTableViewCell {
    let avatar: UIImageView = UIImageView()
    let name: UILabel = UILabel()
    let identifier: UILabel = UILabel()
    let signature: UILabel = UILabel()
    let genderIcon: UIImageView = UIImageView()
    var cardData: TUIProfileCardCellData_Minimalist?
    weak var delegate: TUIProfileCardDelegate?

    var textValueObservation: NSKeyValueObservation?
    var identifierObservation: NSKeyValueObservation?
    var nameObservation: NSKeyValueObservation?
    var avatarUrlObservation: NSKeyValueObservation?
    var genderStringObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        textValueObservation = nil
        identifierObservation = nil
        nameObservation = nil
        avatarUrlObservation = nil
        genderStringObservation = nil
    }

    private func setupViews() {
        let headSize = CGSize(width: TUISwift.kScale390(66), height: TUISwift.kScale390(66))
        avatar.frame = CGRect(x: TUISwift.kScale390(16), y: TUISwift.kScale390(10), width: headSize.width, height: headSize.height)
        avatar.contentMode = .scaleAspectFit
        avatar.layer.cornerRadius = 4
        avatar.layer.masksToBounds = true
        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(onTapAvatar))
        avatar.addGestureRecognizer(tapAvatar)
        avatar.isUserInteractionEnabled = true

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatar.layer.masksToBounds = true
            avatar.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatar.layer.masksToBounds = true
            avatar.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        contentView.addSubview(avatar)

        genderIcon.contentMode = .scaleAspectFit
        genderIcon.image = cardData?.genderIconImage
        contentView.addSubview(genderIcon)

        name.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(24))
        name.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        contentView.addSubview(name)

        identifier.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        identifier.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        contentView.addSubview(identifier)

        signature.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        signature.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        contentView.addSubview(signature)

        selectionStyle = .none
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUIProfileCardCellData_Minimalist else { return }

        super.fill(with: data)
        cardData = data
        signature.isHidden = !data.showSignature

        // set data
        textValueObservation = signature.observe(\.text, options: [.new, .initial]) { [weak self] (data, change) in
            guard let _ = self, let _ = change.newValue else { return }
        }

        identifierObservation = data.observe(\.identifier, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self, let value = change.newValue else { return }
            self.identifier.text = "ID: \(value ?? "")"
        }

        nameObservation = data.observe(\.name, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self, let value = change.newValue else { return }
            self.name.text = value
            self.name.sizeToFit()
        }

        avatarUrlObservation = data.observe(\.avatarUrl, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self, let value = change.newValue else { return }
            self.avatar.sd_setImage(with: value, placeholderImage: self.cardData?.avatarImage)
        }

        genderStringObservation = data.observe(\.genderString, options: [.new, .initial]) { [weak self] (data, change) in
            guard let self = self, let value = change.newValue else { return }
            if value == TUISwift.timCommonLocalizableString("Male") {
                self.genderIcon.image = TUISwift.tuiContactCommonBundleImage("male")
            } else if value == TUISwift.timCommonLocalizableString("Female") {
                self.genderIcon.image = TUISwift.tuiContactCommonBundleImage("female")
            } else {
                self.genderIcon.image = nil
            }
        }

        accessoryType = data.showAccessory ? .disclosureIndicator : .none

        // tell constraints they need updating
        setNeedsUpdateConstraints()

        // update constraints now so we can animate the change
        updateConstraintsIfNeeded()

        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        let headSize = CGSize(width: TUISwift.kScale390(66), height: TUISwift.kScale390(66))

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
            if identifier.frame.size.width > 80 {
                make.width.greaterThanOrEqualTo(identifier.frame.size.width)
            } else {
                make.width.greaterThanOrEqualTo(80)
            }
            make.height.greaterThanOrEqualTo(identifier.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
        }

        if cardData?.showSignature == true {
            signature.sizeToFit()
            signature.snp.remakeConstraints { make in
                make.leading.equalTo(name)
                make.top.equalTo(identifier.snp.bottom).offset(5)
                if signature.frame.size.width > 80 {
                    make.width.greaterThanOrEqualTo(signature.frame.size.width)
                } else {
                    make.width.greaterThanOrEqualTo(80)
                }
                make.height.greaterThanOrEqualTo(signature.frame.size.height)
                make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
            }
        } else {
            signature.frame = .zero
        }
    }

    @objc private func onTapAvatar() {
        if let profileCardCell = self as? TUIProfileCardCell {
            delegate?.didTapOnAvatar(profileCardCell)
        }

    }
}
