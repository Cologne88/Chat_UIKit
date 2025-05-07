import SDWebImage
import TIMCommon
import UIKit

class TUISearchResultCell_Minimalist: UITableViewCell {
    let avatarView = UIImageView()
    let title_label = UILabel()
    private let detail_title = UILabel()
    private let rowAccessoryView = UIImageView()
    private let separatorView = UIView()
    private var cellModel: TUISearchResultCellModel?
    var avatarUrlObservation: NSKeyValueObservation?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        
        avatarView.contentMode = .scaleAspectFill
        contentView.addSubview(avatarView)
        
        title_label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        title_label.font = UIFont.boldSystemFont(ofSize: 14.0)
        title_label.textAlignment = TUISwift.isRTL() ? .right : .left
        contentView.addSubview(title_label)
        
        detail_title.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        detail_title.font = UIFont.systemFont(ofSize: 12.0)
        detail_title.textAlignment = TUISwift.isRTL() ? .right : .left
        contentView.addSubview(detail_title)
        
        rowAccessoryView.image = UIImage.safeImage(TUISwift.tuiSearchImagePath("right"))
        contentView.addSubview(rowAccessoryView)
        rowAccessoryView.isHidden = true
        
        separatorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        contentView.addSubview(separatorView)
        separatorView.isHidden = true
        
        selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func fillWithData(_ cellModel: TUISearchResultCellModel) {
        self.cellModel = cellModel
        
        title_label.text = nil
        title_label.attributedText = nil
        detail_title.text = nil
        detail_title.attributedText = nil
        
        title_label.text = cellModel.title
        if let titleAttrString = cellModel.titleAttributeString {
            title_label.attributedText = titleAttrString
        }
        detail_title.text = cellModel.details
        if let detailsAttrString = cellModel.detailsAttributeString {
            detail_title.attributedText = detailsAttrString
        }
        
        // Setup default avatar
        if let groupID = cellModel.groupID, !groupID.isEmpty {
            var avatar: UIImage? = nil
            if TUIConfig.default().enableGroupGridAvatar {
                let key = "TUIConversationLastGroupMember_\(groupID)"
                let member = UserDefaults.standard.integer(forKey: key)
                avatar = TUIGroupAvatar.getCacheAvatar(forGroup: groupID, number: UInt32(member))
            }
            if let groupType = cellModel.groupType {
                cellModel.avatarImage = avatar ?? TUISwift.defaultGroupAvatarImage(byGroupType: groupType)
            }
        }

        avatarUrlObservation = cellModel.observe(\.avatarUrl, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            
            if let groupID = cellModel.groupID, !groupID.isEmpty {
                if let faceUrl = cellModel.avatarUrl {
                    avatarView.sd_setImage(with: URL(string: faceUrl), placeholderImage: cellModel.avatarImage)
                } else {
                    if TUIConfig.default().enableGroupGridAvatar {
                        avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                        TUIGroupAvatar.getCacheGroupAvatar(groupID) { [weak self] avatar, groupID in
                            guard let self = self, groupID == self.cellModel?.groupID else { return }
                            let avatar: UIImage? = avatar
                            if let avatar = avatar {
                                self.avatarView.sd_setImage(with: nil, placeholderImage: avatar)
                            } else {
                                self.avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                                TUIGroupAvatar.fetchGroupAvatars(groupID, placeholder: cellModel.avatarImage ?? UIImage()) { [weak self] success, image, groupID in
                                    guard let self = self, groupID == self.cellModel?.groupID else { return }
                                    if let groupType = self.cellModel?.groupType {
                                        self.avatarView.sd_setImage(with: nil, placeholderImage: success ? image : TUISwift.defaultGroupAvatarImage(byGroupType: groupType))
                                    }
                                }
                            }
                        }
                    } else {
                        avatarView.sd_setImage(with: nil, placeholderImage: cellModel.avatarImage)
                    }
                }
            } else {
                avatarView.sd_setImage(with: URL(string: cellModel.avatarUrl ?? ""), placeholderImage: cellModel.avatarImage)
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
        super.updateConstraints()
        
        let headSize = CGSize(width: TUISwift.kScale390(40), height: TUISwift.kScale390(40))
        
        avatarView.snp.remakeConstraints { make in
            make.size.equalTo(headSize)
            make.centerY.equalTo(contentView)
            make.leading.equalTo(TUISwift.kScale390(16))
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = headSize.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        let title = title_label.text ?? title_label.attributedText?.string ?? ""
        let detail = detail_title.text ?? detail_title.attributedText?.string ?? ""
        
        title_label.sizeToFit()
        detail_title.sizeToFit()
        
        if !title.isEmpty && !detail.isEmpty {
            title_label.snp.remakeConstraints { make in
                make.top.equalTo(avatarView.snp.top)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(title_label.frame.height)
            }
            
            detail_title.snp.remakeConstraints { make in
                make.bottom.equalTo(avatarView.snp.bottom)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(detail_title.frame.height)
            }
        } else {
            title_label.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarView.snp.centerY)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(title_label.frame.height)
            }
            detail_title.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarView.snp.centerY)
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
                make.trailing.equalTo(contentView.snp.trailing).offset(-10)
                make.height.greaterThanOrEqualTo(title_label.frame.height)
            }
        }
        
        rowAccessoryView.snp.remakeConstraints { make in
            make.size.equalTo(10)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView.snp.trailing).offset(-10)
        }
        
        separatorView.snp.remakeConstraints { make in
            make.leading.equalTo(detail_title.snp.trailing)
            make.bottom.equalTo(contentView.snp.bottom).offset(-1)
            make.width.equalTo(contentView)
            make.height.equalTo(1)
        }
    }
}
