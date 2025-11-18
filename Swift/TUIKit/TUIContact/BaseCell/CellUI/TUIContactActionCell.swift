import TIMCommon
import TUICore
import UIKit

let kContactCellReuseId = "ContactCellReuseId"
let kContactActionCellReuseId = "ContactActionCellReuseId"

class TUIContactActionCell: TUICommonTableViewCell {
    var readNumObservation: NSKeyValueObservation?
    
    let avatarView: UIImageView = {
        let imageView = UIImageView(image: TUISwift.defaultAvatarImage())
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()
    
    let unRead: TUIUnReadView = .init()
    
    private(set) var actionData: TUIContactActionCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(avatarView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(unRead)
        selectionStyle = .none
        accessoryType = .disclosureIndicator
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        readNumObservation?.invalidate()
        readNumObservation = nil
    }

    func fill(withData actionData: TUIContactActionCellData) {
        super.fill(with: actionData)
        self.actionData = actionData

        titleLabel.text = actionData.title
        if let icon = actionData.icon {
            avatarView.image = icon
        }
        
        readNumObservation = self.actionData?.observe(\.readNum, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let newNum = change.newValue else { return }
            self.unRead.setNum(newNum)
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        let imgWidth = TUISwift.kScale390(34)
        
        avatarView.snp.remakeConstraints { make in
            make.width.height.equalTo(imgWidth)
            make.centerY.equalTo(contentView.snp.centerY)
            make.leading.equalTo(TUISwift.kScale390(12))
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = imgWidth / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.height.equalTo(20)
            make.trailing.lessThanOrEqualTo(contentView.snp.trailing)
        }
        
        unRead.unReadLabel.sizeToFit()
        unRead.snp.remakeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.trailing.equalTo(contentView.snp.trailing).offset(-5)
            make.width.height.equalTo(TUISwift.kScale375(20))
        }
        
        unRead.unReadLabel.snp.remakeConstraints { make in
            make.center.equalTo(unRead)
            make.size.equalTo(unRead.unReadLabel)
        }
        
        unRead.layer.cornerRadius = TUISwift.kScale375(10)
        unRead.layer.masksToBounds = true
        
        super.updateConstraints()
    }
}
