import SnapKit
import TIMCommon
import UIKit

class TUIMemberDescribeCell_Minimalist: TUICommonTableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9")
        view.layer.cornerRadius = TUISwift.kScale390(20)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()

    private let icon: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private var cellData: TUIMemberDescribeCellData?

    // MARK: - Life cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(icon)
        containerView.addSubview(titleLabel)

        selectionStyle = .none
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        if let data = data as? TUIMemberDescribeCellData {
            cellData = data

            titleLabel.text = data.title
            icon.image = data.icon

            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        let margin = TUISwift.kScale390(16)

        containerView.snp.remakeConstraints { make in
            make.leading.equalTo(margin)
            make.top.equalTo(0)
            make.trailing.equalTo(-margin)
            make.height.equalTo(TUISwift.kScale390(57))
        }

        icon.snp.remakeConstraints { make in
            make.leading.equalTo(TUISwift.kScale390(20))
            make.centerY.equalTo(containerView)
            make.width.height.equalTo(TUISwift.kScale390(16))
        }

        titleLabel.sizeToFit()
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(containerView)
            make.leading.equalTo(icon.snp.trailing).offset(TUISwift.kScale390(11))
            make.height.equalTo(titleLabel.frame.size.height)
            make.trailing.equalTo(-TUISwift.kScale390(11))
        }
    }
}

let defaultAvatarImage = TUIConfig.default().defaultAvatarImage
class TUIMemberCell_Minimalist: TUICommonTableViewCell {
    private var cellData: TUIMemberCellData?

    private let avatarView: UIImageView = {
        let imageView = UIImageView(image: defaultAvatarImage)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        label.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(14))
        return label
    }()

    private let detailLabel: UILabel = {
        let label = UILabel(frame: CGRectMake(0, 0, 100, 20))
        label.rtlAlignment = .trailing
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")

        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        detailLabel.mm__centerY(avatarView.mm_centerY)

        selectionStyle = .none
        changeColorWhenTouched = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fill(with cellData: TUICommonCellData) {
        super.fill(with: cellData)
        guard let cellData = cellData as? TUIMemberCellData else {
            assertionFailure("data must be kind of TUIMemberCell_Minimalist")
            return
        }

        titleLabel.text = cellData.title
        avatarView.sd_setImage(with: cellData.avatarUrl, placeholderImage: defaultAvatarImage)
        detailLabel.isHidden = cellData.detail?.count == 0
        detailLabel.text = cellData.detail

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        let imgWidth = TUISwift.kScale390(32)

        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(TUISwift.kScale390(24))
        }

        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }

        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(4)
            make.height.equalTo(TUISwift.kScale390(17))
            make.trailing.lessThanOrEqualTo(detailLabel.snp.leading).offset(-5)
        }

        detailLabel.sizeToFit()
        detailLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView)
            make.height.equalTo(20)
            make.trailing.equalTo(contentView).offset(-12)
            make.width.equalTo(detailLabel.frame.size.width)
        }
    }
}
