// TUIContactAcceptRejectCell_Minimalist.swift
// TUIContact

import TIMCommon
import TUICore

class TUIContactAcceptRejectCell_Minimalist: TUICommonTableViewCell {
    var acceptRejectData: TUIContactAcceptRejectCellData_Minimalist?
    var agreeButton: UIButton = UIButton(type: .system)
    var rejectButton: UIButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        agreeButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        agreeButton.addTarget(self, action: #selector(agreeClick), for: .touchUpInside)

        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: TUISwift.kScale390(14))
        rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000"), for: .normal)
        rejectButton.addTarget(self, action: #selector(rejectClick), for: .touchUpInside)

        contentView.addSubview(agreeButton)
        contentView.addSubview(rejectButton)
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUIContactAcceptRejectCellData_Minimalist else { return }

        super.fill(with: data)
        acceptRejectData = data

        if data.isAccepted {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agreed"), for: .normal)
            agreeButton.isEnabled = false
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.layer.cornerRadius = TUISwift.kScale390(10)
            agreeButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#999999"), for: .normal)
            agreeButton.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        } else {
            agreeButton.setTitle(TUISwift.timCommonLocalizableString("Agree"), for: .normal)
            agreeButton.isEnabled = true
            agreeButton.layer.borderColor = UIColor.clear.cgColor
            agreeButton.layer.borderWidth = 1
            agreeButton.layer.cornerRadius = TUISwift.kScale390(10)
            agreeButton.setTitleColor(.white, for: .normal)
            agreeButton.backgroundColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
        }

        if data.isRejected {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Disclined"), for: .normal)
            rejectButton.isEnabled = false
            rejectButton.layer.borderColor = UIColor.clear.cgColor
            rejectButton.layer.cornerRadius = TUISwift.kScale390(10)
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#999999"), for: .normal)
            rejectButton.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
        } else {
            rejectButton.setTitle(TUISwift.timCommonLocalizableString("Discline"), for: .normal)
            rejectButton.isEnabled = true
            rejectButton.layer.borderColor = TUISwift.timCommonDynamicColor("", defaultColor: "#DDDDDD").cgColor
            rejectButton.layer.borderWidth = 1
            rejectButton.layer.cornerRadius = TUISwift.kScale390(10)
            rejectButton.setTitleColor(TUISwift.timCommonDynamicColor("", defaultColor: "#FF584C"), for: .normal)
            rejectButton.backgroundColor = UIColor.tui_color(withHex: "#f9f9f9")
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
        let margin = TUISwift.kScale390(25)
        let padding = TUISwift.kScale390(20)
        let btnWidth = (contentView.frame.size.width - 2 * margin - padding) * 0.5
        let btnHeight = TUISwift.kScale390(42)

        agreeButton.snp.remakeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(margin)
            make.trailing.equalTo(rejectButton.snp.leading).offset(-padding)
            make.top.equalTo(contentView)
            make.height.equalTo(btnHeight)
        }
        rejectButton.snp.remakeConstraints { make in
            make.width.equalTo(agreeButton)
            make.trailing.equalTo(contentView.snp.trailing).offset(-margin)
            make.top.equalTo(contentView)
            make.height.equalTo(btnHeight)
        }
        if acceptRejectData?.isRejected == true && acceptRejectData?.isAccepted == false {
            agreeButton.isHidden = true
            rejectButton.isHidden = false
            rejectButton.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leading).offset(margin)
                make.trailing.equalTo(contentView.snp.trailing).offset(-margin)
                make.top.equalTo(contentView)
                make.height.equalTo(btnHeight)
            }
        } else if acceptRejectData?.isAccepted == true && acceptRejectData?.isRejected == false {
            agreeButton.isHidden = false
            rejectButton.isHidden = true
            agreeButton.snp.remakeConstraints { make in
                make.leading.equalTo(contentView.snp.leading).offset(margin)
                make.trailing.equalTo(contentView.snp.trailing).offset(-margin)
                make.top.equalTo(contentView)
                make.height.equalTo(btnHeight)
            }
        } else {
            agreeButton.isHidden = false
            rejectButton.isHidden = false
        }
    }

    @objc private func agreeClick() {
        acceptRejectData?.agreeClickCallback?()
    }

    @objc private func rejectClick() {
        acceptRejectData?.rejectClickCallback?()
    }
}
