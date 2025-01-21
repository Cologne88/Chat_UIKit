//  TUICommonPendencyCell_Minimalist.swift
//  TUIContact

import TIMCommon
import UIKit

class TUICommonPendencyCell_Minimalist: TUICommonTableViewCell {
    let avatarView = UIImageView(image: TUISwift.defaultAvatarImage())
    let titleLabel = UILabel(frame: .zero)
    let addSourceLabel = UILabel(frame: .zero)
    let addWordingLabel = UILabel(frame: .zero)
    let agreeButton = UIButton(type: .system)
    let rejectButton = UIButton(type: .system)
    let stackView = UIStackView()
    var pendencyData: TUICommonPendencyCellData_Minimalist?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarView)

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")

        contentView.addSubview(addSourceLabel)
        addSourceLabel.textColor = UIColor.tui_color(withHex: "#000000", alpha: 0.6)
        addSourceLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))

        contentView.addSubview(addWordingLabel)
        addWordingLabel.textColor = UIColor.tui_color(withHex: "#000000", alpha: 0.6)
        addWordingLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))

        agreeButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        agreeButton.addTarget(self, action: #selector(agreeClick), for: .touchUpInside)

        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        rejectButton.addTarget(self, action: #selector(rejectClick), for: .touchUpInside)

        stackView.addArrangedSubview(agreeButton)
        stackView.addArrangedSubview(rejectButton)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.sizeToFit()
        accessoryView = stackView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func fill(with pendencyData: TUICommonCellData) {
        guard let pendencyData = pendencyData as? TUICommonPendencyCellData_Minimalist else { return }

        super.fill(with: pendencyData)
        self.pendencyData = pendencyData
        titleLabel.text = pendencyData.title
        addSourceLabel.text = pendencyData.addSource
        addWordingLabel.text = pendencyData.addWording
        avatarView.image = TUISwift.defaultAvatarImage()
        if let avatarUrl = pendencyData.avatarUrl {
            avatarView.sd_setImage(with: avatarUrl)
        }
        if pendencyData.isAccepted {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agreed"), for: .normal)
            agreeButton.isEnabled = false
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.layer.cornerRadius = TUISwift.kScale390(10)
            agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
            agreeButton.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        } else {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agree"), for: .normal)
            agreeButton.isEnabled = true
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.layer.borderWidth = 1
            agreeButton.layer.cornerRadius = TUISwift.kScale390(10)
            agreeButton.setTitleColor(.white, for: .normal)
            agreeButton.backgroundColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
        }

        if pendencyData.isRejected {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Disclined"), for: .normal)
            rejectButton.isEnabled = false
            rejectButton.layer.borderColor = UIColor.clear.cgColor
            rejectButton.layer.cornerRadius = TUISwift.kScale390(10)
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#999999"), for: .normal)
            rejectButton.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9")
        } else {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Discline"), for: .normal)
            rejectButton.isEnabled = true
            rejectButton.layer.borderColor = TUISwift.timCommonDynamicColor("", defaultColor: "#DDDDDD").cgColor
            rejectButton.layer.borderWidth = 1
            rejectButton.layer.cornerRadius = TUISwift.kScale390(10)
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#FF584C"), for: .normal)
        }
        if pendencyData.isRejected && !pendencyData.isAccepted {
            agreeButton.isHidden = true
            rejectButton.isHidden = false
        } else if pendencyData.isAccepted && !pendencyData.isRejected {
            agreeButton.isHidden = false
            rejectButton.isHidden = true
        } else {
            agreeButton.isHidden = false
            rejectButton.isHidden = false
        }

        addSourceLabel.isHidden = pendencyData.hideSource

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
            make.leading.equalTo(TUISwift.kScale390(16))
            make.centerY.equalTo(contentView)
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(TUISwift.kScale390(8))
            make.leading.equalTo(avatarView.snp.trailing).offset(TUISwift.kScale390(12))
            make.height.equalTo(20)
            make.width.equalTo(120)
        }

        addWordingLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.height.equalTo(15)
            make.width.equalTo(120)
        }

        agreeButton.sizeToFit()
        stackView.bounds = CGRect(x: 0, y: 0, width: TUISwift.kScale390(69) + TUISwift.kScale390(76) + 10, height: agreeButton.frame.height)
    }

    @objc func agreeClick() {
        if let selector = pendencyData?.cbuttonSelector {
            let vc = mm_viewController
            if vc?.responds(to: selector) == true {
                vc?.perform(selector, with: self)
            }
        }
    }

    @objc func rejectClick() {
        if let selector = pendencyData?.cRejectButtonSelector {
            let vc = mm_viewController
            if vc?.responds(to: selector) == true {
                vc?.perform(selector, with: self)
            }
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view == agreeButton {
            return false
        } else if touch.view == rejectButton {
            return false
        }
        return true
    }
}
