//  TUICommonContactSwitchCell_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon

class TUICommonContactSwitchCellData_Minimalist: TUICommonCellData {
    var title: String?
    var desc: String?
    var isOn: Bool = false
    var margin: CGFloat!
    var cswitchSelector: Selector?
    
    override init() {
        super.init()
        margin = 20
    }

    init(title: String, desc: String, isOn: Bool, margin: CGFloat, cswitchSelector: Selector?) {
        self.title = title
        self.desc = desc
        self.isOn = isOn
        self.margin = margin
        self.cswitchSelector = cswitchSelector
        super.init()
    }
    
    override func height(ofWidth width: CGFloat) -> CGFloat {
        var height = super.height(ofWidth: width)
        if let desc = self.desc, !desc.isEmpty {
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let size = (desc as NSString).boundingRect(
                with: CGSize(width: 264, height: 999),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            ).size
            height += size.height + 10
        }
        return height
    }
}

class TUICommonContactSwitchCell_Minimalist: TUICommonTableViewCell {
    var titleLabel: UILabel!  // main title label
    var descLabel: UILabel! // detail title label below the main title label, used for explaining details
    var switcher: UISwitch!

    private(set) var switchData: TUICommonContactSwitchCellData_Minimalist?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
        self.contentView.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")

        titleLabel = UILabel()
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_key_text_color", defaultColor: "#444444")
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)

        descLabel = UILabel()
        descLabel.textColor = TUISwift.timCommonDynamicColor("group_modify_desc_color", defaultColor: "#888888")
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.numberOfLines = 0
        descLabel.textAlignment = .left
        descLabel.isHidden = true
        contentView.addSubview(descLabel)

        switcher = UISwitch()
        switcher.onTintColor = TUISwift.timCommonDynamicColor("common_switch_on_color", defaultColor: "#34C759")
        accessoryView = switcher
        contentView.addSubview(switcher)
        switcher.addTarget(self, action: #selector(switchClick), for: .valueChanged)

        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUICommonContactSwitchCellData_Minimalist else { return }

        super.fill(with: data)
        switchData = data
        titleLabel.text = data.title
        switcher.isOn = data.isOn

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        guard let switchData = switchData else { return }

        if let desc = switchData.desc {
            descLabel.text = switchData.desc
            descLabel.isHidden = false
            
            let attribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let size = (desc as NSString).boundingRect(with: CGSize(width: 264, height: 999),
                                                       options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin, .usesFontLeading],
                                                       attributes: attribute,
                                                       context: nil).size

            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(24)
                make.leading.equalTo(switchData.margin)
                make.top.equalTo(12)
            }
            descLabel.snp.remakeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
                make.leading.equalTo(titleLabel.snp.leading)
                make.top.equalTo(titleLabel.snp.bottom).offset(2)
            }
        } else {
            titleLabel.sizeToFit()
            titleLabel.snp.remakeConstraints { make in
                make.size.equalTo(titleLabel.frame.size)
                make.leading.equalTo(switchData.margin)
                make.centerY.equalTo(contentView)
            }
        }
    }

    @objc func switchClick() {
        guard let switchData = switchData, let cswitchSelector = switchData.cswitchSelector else { return }
        if let vc = self.mm_viewController, vc.responds(to: cswitchSelector) {
            vc.perform(cswitchSelector, with: self)
        }
    }
}
