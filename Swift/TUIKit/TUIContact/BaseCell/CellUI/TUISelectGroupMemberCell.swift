import TIMCommon
import TUICore
import UIKit

class TUISelectGroupMemberCell: UITableViewCell {
    private let selectedMark = UIImageView()
    private let userImg = UIImageView()
    private let nameLabel = UILabel()
    private var userModel: TUIUserModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#F2F3F5")

        addSubview(selectedMark)
        addSubview(userImg)

        nameLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        addSubview(nameLabel)

        self.selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fill(with model: TUIUserModel, isSelect: Bool) {
        userModel = model
        selectedMark.image = isSelect ? UIImage(named: TUISwift.tuiContactImagePath("ic_selected")) : UIImage(named: TUISwift.tuiContactImagePath("ic_unselect"))
        userImg.sd_setImage(with: URL(string: model.avatar), placeholderImage: TUISwift.defaultAvatarImage())
        nameLabel.text = model.name

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        selectedMark.snp.remakeConstraints { make in
            make.width.height.equalTo(20)
            make.leading.equalTo(contentView).offset(12)
            make.centerY.equalTo(contentView)
        }

        userImg.snp.remakeConstraints { make in
            make.width.height.equalTo(32)
            make.leading.equalTo(selectedMark.snp.trailing).offset(12)
            make.centerY.equalTo(contentView)
        }

        nameLabel.sizeToFit()
        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(userImg.snp.trailing).offset(12)
            make.trailing.equalTo(contentView)
            make.height.equalTo(contentView)
            make.centerY.equalTo(contentView)
        }

        super.updateConstraints()
    }
}
