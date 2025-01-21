import TIMCommon
import TUICore
import UIKit

protocol TUIContactProfileCardDelegate: NSObjectProtocol {
    func didTapOnAvatar(cell: TUICommonContactProfileCardCell)
}

class TUICommonContactProfileCardCellData: TUICommonCellData {
    var avatarImage: UIImage? = TUISwift.defaultAvatarImage()
    var genderIconImage: UIImage?
    var showAccessory: Bool = false
    var showSignature: Bool = false
    @objc dynamic var avatarUrl: URL?
    @objc dynamic var name: String?
    @objc dynamic var identifier: String?
    @objc dynamic var signature: String?
    @objc dynamic var genderString: String?

    override init() {
        super.init()
        if genderString == TUISwift.timCommonLocalizableString("Male") {
            genderIconImage = TUISwift.tuiContactCommonBundleImage("male")
        } else if genderString == TUISwift.timCommonLocalizableString("Female") {
            genderIconImage = TUISwift.tuiContactCommonBundleImage("female")
        } else {
            genderIconImage = nil
        }
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.tPersonalCommonCell_Image_Size().height + CGFloat(2 * TPersonalCommonCell_Margin) + (showSignature ? 24 : 0)
    }
}

class TUICommonContactProfileCardCell: TUICommonTableViewCell {
    var avatar: UIImageView = .init()
    var name: UILabel = .init()
    var identifier: UILabel = .init()
    var signature: UILabel = .init()
    var genderIcon: UIImageView = .init()
    var cardData: TUICommonContactProfileCardCellData?

    var avatarUrlObservation: NSKeyValueObservation?
    var nameObservation: NSKeyValueObservation?
    var identifierObservation: NSKeyValueObservation?
    var signatureObservation: NSKeyValueObservation?
    var genderStringObservation: NSKeyValueObservation?

    weak var delegate: TUIContactProfileCardDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarUrlObservation?.invalidate()
        avatarUrlObservation = nil
        nameObservation?.invalidate()
        nameObservation = nil
        identifierObservation?.invalidate()
        identifierObservation = nil
        signatureObservation?.invalidate()
        signatureObservation = nil
        genderStringObservation?.invalidate()
        genderStringObservation = nil
    }

    private func setupViews() {
        let headSize = TUISwift.tPersonalCommonCell_Image_Size()
        avatar.frame = CGRect(x: CGFloat(TPersonalCommonCell_Margin), y: CGFloat(TPersonalCommonCell_Margin), width: headSize.width, height: headSize.height)
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

        name.font = UIFont.boldSystemFont(ofSize: 18)
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
        guard let data = data as? TUICommonContactProfileCardCellData else { return }

        super.fill(with: data)
        cardData = data
        signature.isHidden = !data.showSignature

        signatureObservation = data.observe(\.signature, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.signature.text = newValue
        }

        identifierObservation = data.observe(\.identifier, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.identifier.text = "ID: \(newValue ?? "")"
        }

        nameObservation = data.observe(\.name, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.name.text = newValue
        }

        avatarUrlObservation = data.observe(\.avatarUrl, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self else { return }
            self.avatar.sd_setImage(with: change.newValue as? URL, placeholderImage: self.cardData?.avatarImage)
        }

        genderStringObservation = data.observe(\.genderString, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            if newValue == TUISwift.timCommonLocalizableString("Male") {
                self.genderIcon.image = TUISwift.tuiContactCommonBundleImage("male")
            } else if newValue == TUISwift.timCommonLocalizableString("Female") {
                self.genderIcon.image = TUISwift.tuiContactCommonBundleImage("female")
            } else {
                self.genderIcon.image = nil
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
        let headSize = TUISwift.tPersonalCommonCell_Image_Size()

        avatar.snp.remakeConstraints { make in
            make.size.equalTo(headSize)
            make.top.equalTo(CGFloat(TPersonalCommonCell_Margin))
            make.leading.equalTo(CGFloat(TPersonalCommonCell_Margin))
        }

        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            avatar.layer.masksToBounds = true
            avatar.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
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
            make.width.greaterThanOrEqualTo(identifier.frame.size.width > 80 ? identifier.frame.size.width : 80)
            make.height.greaterThanOrEqualTo(identifier.frame.size.height)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
        }

        if cardData?.showSignature == true {
            signature.sizeToFit()
            signature.snp.remakeConstraints { make in
                make.leading.equalTo(name)
                make.top.equalTo(identifier.snp.bottom).offset(5)
                make.width.greaterThanOrEqualTo(signature.frame.size.width > 80 ? signature.frame.size.width : 80)
                make.height.greaterThanOrEqualTo(signature.frame.size.height)
                make.trailing.lessThanOrEqualTo(contentView.snp.trailing).offset(-1)
            }
        } else {
            signature.frame = .zero
        }
    }

    @objc private func onTapAvatar() {
        delegate?.didTapOnAvatar(cell: self)
    }
}
