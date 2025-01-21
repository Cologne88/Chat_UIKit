//  TUIFriendProfileHeaderView_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon
import TUICore

class TUIFriendProfileHeaderItemView: UIView {
    let iconView: UIImageView
    let textLabel: UILabel
    var messageBtnClickBlock: (() -> Void)?

    override init(frame: CGRect) {
        iconView = UIImageView(image: TUISwift.defaultAvatarImage())
        textLabel = UILabel()
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(iconView)
        iconView.isUserInteractionEnabled = true
        iconView.contentMode = .scaleAspectFit

        textLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(16))
        textLabel.textColor = UIColor.tui_color(withHex: "#000000")
        textLabel.textAlignment = TUISwift.isRTL() ? .right : .center
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
        super.updateConstraints()
    }

    @objc private func click() {
        messageBtnClickBlock?()
    }
}

class TUIFriendProfileHeaderView_Minimalist: UIView {
    let headImg: UIImageView
    let descriptionLabel: UILabel
    let functionListView: UIView

    override init(frame: CGRect) {
        headImg = UIImageView(image: TUISwift.defaultAvatarImage())
        descriptionLabel = UILabel()
        functionListView = UIView()
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(headImg)
        headImg.isUserInteractionEnabled = true
        headImg.contentMode = .scaleAspectFit

        descriptionLabel.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(24))
        addSubview(descriptionLabel)

        addSubview(functionListView)
    }

    func setItemViewList(_ itemList: [TUIFriendProfileHeaderItemView]) {
        functionListView.subviews.forEach { $0.removeFromSuperview() }

        if !itemList.isEmpty {
            itemList.forEach { functionListView.addSubview($0) }
            let width = TUISwift.kScale390(92)
            let height = TUISwift.kScale390(95)
            let space = TUISwift.kScale390(24)
            let contentWidth = CGFloat(itemList.count) * width + CGFloat(itemList.count - 1) * space
            var x = 0.5 * (bounds.size.width - contentWidth)
            itemList.forEach {
                $0.frame = CGRect(x: x, y: 0, width: width, height: height)
                x = $0.frame.maxX + space
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
        let imgWidth = TUISwift.kScale390(94)
        headImg.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(TUISwift.kScale390(42))
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            headImg.layer.masksToBounds = true
            headImg.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
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

        if !functionListView.subviews.isEmpty {
            functionListView.snp.remakeConstraints { make in
                make.leading.equalTo(0)
                make.width.equalTo(bounds.size.width)
                make.height.equalTo(TUISwift.kScale390(95))
                make.top.equalTo(descriptionLabel.snp.bottom).offset(TUISwift.kScale390(18))
            }
        }
        super.updateConstraints()
    }
}
