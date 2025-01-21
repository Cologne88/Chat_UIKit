import TIMCommon
import TUICore
import UIKit

class TUIGroupNoticeCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = TUISwift.timCommonDynamicColor("form_key_text_color", defaultColor: "#888888")
        label.font = UIFont.systemFont(ofSize: 16.0)
        return label
    }()

    let descLabel: UILabel = {
        let label = UILabel()
        label.text = "neirong"
        label.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#BBBBBB")
        label.font = UIFont.systemFont(ofSize: 12.0)
        return label
    }()

    var cellData: TUIGroupNoticeCellData? {
        didSet {
            guard let cellData = cellData else { return }
            nameLabel.text = cellData.name
            descLabel.text = cellData.desc
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        selectionStyle = .none
        accessoryType = .disclosureIndicator
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        tapRecognizer.delegate = self
        tapRecognizer.cancelsTouchesInView = false
        contentView.addGestureRecognizer(tapRecognizer)
    }

    @objc private func tapGesture(_ gesture: UIGestureRecognizer) {
        if let selector = cellData?.selector, let target = cellData?.target, target.responds(to: selector) {
            _ = target.perform(selector)
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        nameLabel.sizeToFit()
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(20)
            make.top.equalTo(12)
            make.trailing.lessThanOrEqualTo(contentView).offset(-20)
            make.size.equalTo(nameLabel.frame.size)
        }
        descLabel.sizeToFit()
        descLabel.snp.remakeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(contentView).offset(-30)
            make.size.equalTo(descLabel.frame.size)
        }
        super.updateConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
