import TIMCommon
import UIKit

class TUICommonContactTextCellData: TUICommonCellData {
    @objc dynamic var key: String?
    @objc dynamic var value: String?
    var showAccessory: Bool = false
    var keyColor: UIColor?
    var valueColor: UIColor?
    var enableMultiLineValue: Bool = false
    var keyEdgeInsets: UIEdgeInsets = .init(top: 0, left: 20, bottom: 0, right: 0)
}

class TUICommonContactTextCell: TUICommonTableViewCell {
    let keyLabel = UILabel()
    let valueLabel = UILabel()
    private(set) var textData: TUICommonContactTextCellData?

    var textDataKeyObservation: NSKeyValueObservation?
    var textDataValueObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")

        keyLabel.textColor = TUISwift.timCommonDynamicColor("form_key_text_color", defaultColor: "#444444")
        keyLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentView.addSubview(keyLabel)
        keyLabel.rtlAlignment = TUITextRTLAlignment.trailing

        valueLabel.textColor = TUISwift.timCommonDynamicColor("form_value_text_color", defaultColor: "#000000")
        valueLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentView.addSubview(valueLabel)
        valueLabel.rtlAlignment = TUITextRTLAlignment.trailing

        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUICommonContactTextCellData else { return }

        super.fill(with: data)
        textData = data

        textDataKeyObservation = data.observe(\.key, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let text = change.newValue else { return }
            self.keyLabel.text = text
        }

        textDataValueObservation = data.observe(\.value, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let text = change.newValue else { return }
            self.valueLabel.text = text
        }

        accessoryType = data.showAccessory ? .disclosureIndicator : .none

        if let keyColor = data.keyColor {
            keyLabel.textColor = keyColor
        }

        if let valueColor = data.valueColor {
            valueLabel.textColor = valueColor
        }

        valueLabel.numberOfLines = data.enableMultiLineValue ? 0 : 1

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
            if textData?.showAccessory == true {
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
            } else {
                make.trailing.equalTo(contentView.snp.trailing).offset(-20)
            }
            make.centerY.equalTo(contentView)
        }
    }
}
