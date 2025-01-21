import TIMCommon
import UIKit

class TUICommonContactSwitchCellData: TUICommonCellData {
    var title: String?
    var desc: String?
    var isOn: Bool = false
    var margin: CGFloat = 20.0
    var cswitchSelector: Selector?
}

class TUICommonContactSwitchCell: TUICommonTableViewCell {
    var titleLabel: UILabel!  // main title label
    var descLabel: UILabel! // detail title label below the main title label, used for explaining details
    var switcher: UISwitch!

    private(set) var switchData: TUICommonContactSwitchCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel = UILabel()
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_key_text_color", defaultColor: "#444444")
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        contentView.addSubview(titleLabel)

        descLabel = UILabel()
        descLabel.textColor = TUISwift.timCommonDynamicColor("group_modify_desc_color", defaultColor: "#888888")
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.numberOfLines = 0
        descLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        descLabel.isHidden = true
        contentView.addSubview(descLabel)

        switcher = UISwitch()
        switcher.onTintColor = TUISwift.timCommonDynamicColor("common_switch_on_color", defaultColor: "#147AFF")
        accessoryView = switcher
        contentView.addSubview(switcher)
        switcher.addTarget(self, action: #selector(switchClick), for: .valueChanged)

        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with data: TUICommonCellData) {
        guard let data = data as? TUICommonContactSwitchCellData else { return }

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

        if let desc = switchData?.desc, !desc.isEmpty {
            descLabel.text = desc
            descLabel.isHidden = false

            let attribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let size = (desc as NSString).boundingRect(with: CGSize(width: 264, height: 999),
                                                       options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                       attributes: attribute,
                                                       context: nil).size

            titleLabel.snp.remakeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(24)
                make.leading.equalTo(switchData?.margin ?? 0)
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
                make.leading.equalTo(switchData?.margin ?? 0)
                make.centerY.equalTo(contentView)
            }
        }
    }

    @objc func switchClick() {
        if let selector = switchData?.cswitchSelector {
            let vc = mm_viewController
            if vc?.responds(to: selector) == true {
                vc?.perform(selector, with: self)
            }
        }
    }
}
