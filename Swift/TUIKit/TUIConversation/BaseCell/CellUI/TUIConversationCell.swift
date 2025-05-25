import SDWebImage
import SnapKit
import TIMCommon
import TUICore
import UIKit

public class TUIConversationCell: UITableViewCell {
    var headImageView: UIImageView!
    var titleLabel: UILabel!
    var subTitleLabel: UILabel!
    var timeLabel: UILabel!
    var notDisturbRedDot: UIView!
    var notDisturbView: UIImageView!
    var unReadView: TUIUnReadView!
    var selectedIcon: UIImageView!
    var onlineStatusIcon: UIImageView!
    var lastMessageStatusImageView: UIImageView!
    
    private var titleObservation: NSKeyValueObservation?
    private var faceUrlObservation: NSKeyValueObservation?
    public var displayOnlineStatusIconObservation: NSKeyValueObservation?
    
    @objc dynamic var convData: TUIConversationCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = TUISwift.tuiConversationDynamicColor("conversation_cell_bg_color", defaultColor: "#FFFFFF")
        
        headImageView = UIImageView()
        contentView.addSubview(headImageView)
        
        timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = TUISwift.timCommonDynamicColor("form_desc_color", defaultColor: "#BBBBBB")
        timeLabel.layer.masksToBounds = true
        timeLabel.rtlAlignment = .leading
        contentView.addSubview(timeLabel)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel.layer.masksToBounds = true
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)
        
        unReadView = TUIUnReadView()
        contentView.addSubview(unReadView)
        
        subTitleLabel = UILabel()
        subTitleLabel.layer.masksToBounds = true
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = TUISwift.timCommonDynamicColor("form_subtitle_color", defaultColor: "#888888")
        subTitleLabel.textAlignment = .left
        contentView.addSubview(subTitleLabel)
        
        notDisturbRedDot = UIView()
        notDisturbRedDot.backgroundColor = .red
        notDisturbRedDot.layer.cornerRadius = CGFloat(TConversationCell_Margin_Disturb_Dot) / 2.0
        notDisturbRedDot.layer.masksToBounds = true
        contentView.addSubview(notDisturbRedDot)
        
        notDisturbView = UIImageView()
        contentView.addSubview(notDisturbView)
        
        separatorInset = UIEdgeInsets(top: 0, left: CGFloat(TConversationCell_Margin), bottom: 0, right: 0)
        selectionStyle = .none
        
        selectedIcon = UIImageView()
        contentView.addSubview(selectedIcon)
        
        onlineStatusIcon = UIImageView()
        contentView.addSubview(onlineStatusIcon)
        
        lastMessageStatusImageView = UIImageView()
        contentView.addSubview(lastMessageStatusImageView)
        lastMessageStatusImageView.isHidden = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        titleObservation?.invalidate()
        titleObservation = nil
        faceUrlObservation?.invalidate()
        faceUrlObservation = nil
        displayOnlineStatusIconObservation?.invalidate()
        displayOnlineStatusIconObservation = nil
    }
    
    public func fill(with convData: TUIConversationCellData) {
        self.convData = convData
        
        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        if let cellTitleLabelFont = TUIConversationConfig.shared.cellTitleLabelFont {
            titleLabel.font = cellTitleLabelFont
        }
        
        subTitleLabel.attributedText = convData.subTitle
        if let cellSubtitleLabelFont = TUIConversationConfig.shared.cellSubtitleLabelFont {
            subTitleLabel.font = cellSubtitleLabelFont
        }
        
        timeLabel.text = TUITool.convertDate(toStr: convData.time)
        if let cellTimeLabelFont = TUIConversationConfig.shared.cellTimeLabelFont {
            timeLabel.font = cellTimeLabelFont
        }
        
        if convData.showCheckBox {
            selectedIcon.isHidden = false
        } else {
            selectedIcon.isHidden = true
        }
        configRedPoint(convData)
        
        if convData.isOnTop {
            contentView.backgroundColor = TUISwift.tuiConversationDynamicColor("conversation_cell_top_bg_color", defaultColor: "#F4F4F4")
        } else {
            contentView.backgroundColor = TUISwift.tuiConversationDynamicColor("conversation_cell_bg_color", defaultColor: "#FFFFFF")
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = headImageView.frame.size.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
        
        titleLabel.text = convData.title
        titleObservation = convData.observe(\.title, options: [.new, .initial], changeHandler: { [weak self] _, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.titleLabel.text = newValue
            // tell constraints they need updating
            setNeedsUpdateConstraints()

            // update constraints now so we can animate the change
            updateConstraintsIfNeeded()

            layoutIfNeeded()
        })
        
        if let groupID = convData.groupID {
            if TUIConfig.default().enableGroupGridAvatar {
                let key = "TUIConversationLastGroupMember_\(groupID)"
                let member = UserDefaults.standard.integer(forKey: key)
                if let avatar = TUIGroupAvatar.getCacheAvatar(forGroup: groupID, number: UInt32(member)) {
                    convData.avatarImage = avatar
                } else {
                    convData.avatarImage = TUISwift.defaultGroupAvatarImage(byGroupType: convData.groupType)
                }
            }
        }
        
        let faceUrl = convData.faceUrl
        if let _ = convData.groupID {
            // Group avatar
            if let faceUrl = faceUrl {
                // The group avatar has been manually set externally
                headImageView.sd_setImage(with: URL(string: faceUrl), placeholderImage: convData.avatarImage)
            } else {
                // The group avatar has not been set externally. If the synthetic avatar is allowed, the synthetic avatar will be used; otherwise, the default avatar will be used.
                if TUIConfig.default().enableGroupGridAvatar {
                    // If the synthetic avatar is allowed, the synthetic avatar will be used
                    // 1. Asynchronously obtain the cached synthetic avatar according to the number of group members
                    // 2. If the cache is hit, use the cached synthetic avatar directly
                    // 3. If the cache is not hit, recompose a new avatar
                    
                    // 1. Obtain group avatar from cache
                    headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                    guard let getGroupID = convData.groupID else { return }
                    TUIGroupAvatar.getCacheGroupAvatar(getGroupID) { [weak self] avatar, groupID in
                        guard let self = self, groupID == getGroupID else { return }
                        
                        if let avatar = avatar {
                            // 2. Hit the cache and assign directly
                            self.headImageView.sd_setImage(with: nil, placeholderImage: avatar)
                        } else {
                            // 3. Synthesize new avatars asynchronously without hitting cache
                            self.headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                            TUIGroupAvatar.fetchGroupAvatars(getGroupID, placeholder: convData.avatarImage ?? UIImage()) { [weak self] success, image, groupID in
                                guard let self = self, groupID == convData.groupID else { return }
                                
                                if success, !image.size.equalTo(CGSizeZero) {
                                    // callback, cell is not reused
                                    self.headImageView.sd_setImage(with: nil, placeholderImage: image)
                                } else {
                                    // callback, cell has been reused to other groupIDs. Since a new callback will be triggered when the new groupID synthesizes new avatar, it is ignored here
                                    self.headImageView.sd_setImage(with: nil, placeholderImage: TUISwift.defaultGroupAvatarImage(byGroupType: self.convData?.groupType))
                                }
                            }
                        }
                    }
                } else {
                    // Synthetic avatars are not allowed, use the default avatar directly
                    headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                }
            }
        } else {
            // Personal avatar
            headImageView.sd_setImage(with: URL(string: faceUrl ?? ""), placeholderImage: convData.avatarImage)
        }
        
        if convData.showCheckBox {
            let imageName: String
            if convData.disableSelected {
                imageName = TUISwift.timCommonImagePath("icon_select_selected_disable")
            } else if convData.selected {
                imageName = TUISwift.timCommonImagePath("icon_select_selected")
            } else {
                imageName = TUISwift.timCommonImagePath("icon_select_normal")
            }
            selectedIcon.image = UIImage.safeImage(imageName)
        }
        
        configOnlineStatusIcon(convData)
        configDisplayLastMessageStatusImage(convData)
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    func configDisplayLastMessageStatusImage(_ convData: TUIConversationCellData) {
        if let image = getDisplayLastMessageStatusImage(convData) {
            lastMessageStatusImageView.image = image
        }
    }
    
    func getDisplayLastMessageStatusImage(_ convData: TUIConversationCellData) -> UIImage? {
        if convData.draftText == nil, convData.lastMessage?.status == .MSG_STATUS_SENDING || convData.lastMessage?.status == .MSG_STATUS_SEND_FAIL {
            if convData.lastMessage?.status == .MSG_STATUS_SENDING {
                return UIImage.safeImage(TUISwift.tuiConversationImagePath("msg_sending_for_conv"))
            } else {
                return UIImage.safeImage(TUISwift.tuiConversationImagePath("msg_error_for_conv"))
            }
        }
        return nil
    }
    
    func configOnlineStatusIcon(_ convData: TUIConversationCellData) {
        displayOnlineStatusIconObservation = TUIConfig.default().observe(\.displayOnlineStatusIcon, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self else { return }
            if TUIConfig.default().displayOnlineStatusIcon {
                if convData.onlineStatus == .online {
                    onlineStatusIcon.isHidden = false
                    onlineStatusIcon.image = UIImage.safeImage(TUISwift.timCommonImagePath("icon_online_status"))
                } else if convData.onlineStatus == .offline {
                    onlineStatusIcon.isHidden = false
                    onlineStatusIcon.image = UIImage.safeImage(TUISwift.timCommonImagePath("icon_offline_status"))
                } else {
                    onlineStatusIcon.isHidden = true
                    onlineStatusIcon.image = nil
                }
            } else {
                onlineStatusIcon.isHidden = true
                onlineStatusIcon.image = nil
            }
        }
    }
    
    func configRedPoint(_ convData: TUIConversationCellData) {
        if convData.isNotDisturb {
            if convData.unreadCount == 0 {
                notDisturbRedDot.isHidden = true
            } else {
                notDisturbRedDot.isHidden = false
            }
            notDisturbView.isHidden = false
            unReadView.isHidden = true
            notDisturbView.image = TUISwift.tuiConversationBundleThemeImage("conversation_message_not_disturb_img", defaultImage: "message_not_disturb")
        } else {
            notDisturbRedDot.isHidden = true
            notDisturbView.isHidden = true
            unReadView.setNum(convData.unreadCount)
            unReadView.isHidden = convData.unreadCount == 0 ? true : !TUIConversationConfig.shared.showCellUnreadCount
        }
        
        if convData.isMarkAsUnread {
            if convData.isNotDisturb {
                notDisturbRedDot.isHidden = false
            } else {
                unReadView.setNum(1)
                unReadView.isHidden = !TUIConversationConfig.shared.showCellUnreadCount
            }
        }
        
        if convData.isLocalConversationFoldList {
            notDisturbView.isHidden = true
        }
    }
    
    override public class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override public func updateConstraints() {
        super.updateConstraints()
        let height = convData?.height(ofWidth: mm_w) ?? 0
        mm_h = height
        
        if convData?.isOnTop == true {
            contentView.backgroundColor = TUIConversationConfig.shared.pinnedCellBackgroundColor ?? TUISwift.tuiConversationDynamicColor("conversation_cell_top_bg_color", defaultColor: "#F4F4F4")
        } else {
            contentView.backgroundColor = TUIConversationConfig.shared.cellBackgroundColor ?? TUISwift.tuiConversationDynamicColor("conversation_cell_bg_color", defaultColor: "#FFFFFF")
        }
        
        let selectedIconSize: CGFloat = 20
        selectedIcon.snp.remakeConstraints { make in
            if convData?.showCheckBox == true {
                make.width.height.equalTo(selectedIconSize)
                make.leading.equalTo(contentView).offset(10)
                make.centerY.equalTo(contentView)
            }
        }
        
        let imgHeight = height - 2 * CGFloat(TConversationCell_Margin)
        headImageView.snp.remakeConstraints { make in
            make.size.equalTo(imgHeight)
            make.centerY.equalTo(contentView)
            if convData?.showCheckBox == true {
                make.leading.equalTo(selectedIcon.snp.trailing).offset(Int(TConversationCell_Margin) + 3)
            } else {
                make.leading.equalTo(contentView).offset(Int(TConversationCell_Margin) + 3)
            }
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = imgHeight / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        let titleLabelHeight: CGFloat = 30
        if convData?.isLiteMode == true {
            titleLabel.sizeToFit()
            titleLabel.snp.remakeConstraints { make in
                make.width.greaterThanOrEqualTo(titleLabelHeight)
                make.top.equalTo((height - titleLabelHeight) / 2)
                make.leading.equalTo(headImageView.snp.trailing).offset(CGFloat(TConversationCell_Margin))
                make.trailing.equalTo(contentView).offset(-2 * Int(TConversationCell_Margin_Text))
            }
            timeLabel.isHidden = true
            lastMessageStatusImageView.isHidden = true
            subTitleLabel.isHidden = true
            unReadView.isHidden = true
            notDisturbRedDot.isHidden = true
            notDisturbView.isHidden = true
            onlineStatusIcon.isHidden = true
        } else {
            timeLabel.sizeToFit()
            timeLabel.snp.remakeConstraints { make in
                make.width.equalTo(timeLabel)
                make.height.greaterThanOrEqualTo(timeLabel.font.lineHeight)
                make.top.equalTo(contentView).offset(CGFloat(TConversationCell_Margin_Text))
                make.trailing.equalTo(contentView).offset(-CGFloat(TConversationCell_Margin_Text))
            }
            
            lastMessageStatusImageView.snp.remakeConstraints { make in
                make.width.equalTo(TUISwift.kScale390(14))
                make.height.equalTo(14)
                make.trailing.equalTo(contentView).offset(-(TUISwift.kScale390(1) + CGFloat(TConversationCell_Margin_Disturb) + TUISwift.kScale390(8)))
                make.bottom.equalTo(contentView).offset(TUISwift.kScale390(16))
            }
            
            titleLabel.sizeToFit()
            titleLabel.snp.remakeConstraints { make in
                make.height.greaterThanOrEqualTo(titleLabelHeight)
                make.top.equalTo(contentView).offset(CGFloat(TConversationCell_Margin_Text) - 5)
                make.leading.equalTo(headImageView.snp.trailing).offset(CGFloat(TConversationCell_Margin))
                make.trailing.lessThanOrEqualTo(timeLabel).offset(-2 * CGFloat(TConversationCell_Margin_Text))
            }
            
            subTitleLabel.sizeToFit()
            subTitleLabel.snp.remakeConstraints { make in
                make.height.greaterThanOrEqualTo(subTitleLabel.frame.height)
                make.bottom.equalTo(contentView).offset(-CGFloat(TConversationCell_Margin_Text))
                make.leading.equalTo(titleLabel)
                make.trailing.equalTo(contentView).offset(-2 * CGFloat(TConversationCell_Margin_Text))
            }
            
            unReadView.unReadLabel.sizeToFit()
            unReadView.snp.remakeConstraints { make in
                make.trailing.equalTo(headImageView).offset(TUISwift.kScale375(5))
                make.top.equalTo(headImageView).offset(-TUISwift.kScale375(5))
                make.width.equalTo(TUISwift.kScale375(20))
                make.height.equalTo(TUISwift.kScale375(20))
            }
            
            unReadView.unReadLabel.snp.remakeConstraints { make in
                make.center.equalTo(unReadView)
                make.size.equalTo(unReadView.unReadLabel)
            }
            unReadView.layer.cornerRadius = TUISwift.kScale375(10)
            unReadView.layer.masksToBounds = true
            
            notDisturbRedDot.snp.remakeConstraints { make in
                make.trailing.equalTo(headImageView).offset(3)
                make.top.equalTo(headImageView).offset(1)
                make.width.height.equalTo(CGFloat(TConversationCell_Margin_Disturb_Dot))
            }
            
            notDisturbView.snp.remakeConstraints { make in
                make.width.height.equalTo(CGFloat(TConversationCell_Margin_Disturb))
                make.trailing.equalTo(timeLabel)
                make.bottom.equalTo(contentView).offset(-15)
            }
            
            onlineStatusIcon.snp.remakeConstraints { make in
                make.width.height.equalTo(TUISwift.kScale375(15))
                make.leading.equalTo(headImageView.snp.trailing).offset(-TUISwift.kScale375(15))
                make.bottom.equalTo(headImageView).offset(-TUISwift.kScale375(1))
            }
            onlineStatusIcon.layer.cornerRadius = 0.5 * TUISwift.kScale375(15)
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
}
