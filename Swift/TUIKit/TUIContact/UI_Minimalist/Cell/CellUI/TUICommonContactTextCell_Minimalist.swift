//  TUICommonContactTextCell_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon
import TUICore

class TUICommonContactTextCellData_Minimalist: TUICommonCellData {
    var key: String?
    var value: String?
    var showAccessory: Bool = false
    var keyColor: UIColor?
    var valueColor: UIColor?
    var enableMultiLineValue: Bool = false
    var keyEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

    override init() {
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        var height = super.height(ofWidth: width)
        if enableMultiLineValue, let str = value {
            let attribute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)]
            let size = (str as NSString).boundingRect(with: CGSize(width: 280, height: 999),
                                                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                      attributes: attribute,
                                                      context: nil).size
            height = size.height + 30
        }
        return height
    }
}

class TUICommonContactTextCell_Minimalist: TUICommonTableViewCell {
    private var textData: TUICommonContactTextCellData_Minimalist?
    private let keyLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#f9f9f9")

        keyLabel.textColor = TUISwift.timCommonDynamicColor("form_key_text_color", defaultColor: "#444444")
        keyLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentView.addSubview(keyLabel)
        keyLabel.rtlAlignment = .trailing

        valueLabel.textColor = TUISwift.timCommonDynamicColor("form_value_text_color", defaultColor: "#000000")
        valueLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentView.addSubview(valueLabel)
        valueLabel.rtlAlignment = .trailing

        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with textData: TUICommonCellData) {
        guard let textData = textData as? TUICommonContactTextCellData_Minimalist else { return }

        super.fill(with: textData)
        self.textData = textData

        keyLabel.text = textData.key
        valueLabel.text = textData.value

        accessoryType = textData.showAccessory ? .disclosureIndicator : .none

        if let keyColor = textData.keyColor {
            keyLabel.textColor = keyColor
        }

        if let valueColor = textData.valueColor {
            valueLabel.textColor = valueColor
        }

        valueLabel.numberOfLines = textData.enableMultiLineValue ? 0 : 1

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        keyLabel.sizeToFit()
        keyLabel.snp.remakeConstraints { make in
            make.size.equalTo(keyLabel.frame.size)
            make.leading.equalTo(contentView).offset(textData?.keyEdgeInsets.left ?? 0)
            make.centerY.equalTo(contentView)
        }

        valueLabel.sizeToFit()
        valueLabel.snp.remakeConstraints { make in
            make.leading.equalTo(keyLabel.snp.trailing).offset(10)
            make.trailing.equalTo(contentView).offset(textData?.showAccessory == true ? -10 : -20)
            make.centerY.equalTo(contentView)
        }
    }
}
