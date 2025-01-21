import ReactiveObjC
import SDWebImage
import TIMCommon
import UIKit

class TUIConversationCell_Minimalist: TUIConversationCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(14))
        titleLabel.textColor = TUISwift.tuiDynamicColor("", module: TUIThemeModule.core_Minimalist, defaultColor: "#000000")
        subTitleLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        lastMessageStatusImageView.isHidden = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func fill(with convData: TUIConversationCellData) {
        self.convData = convData;
        
        titleLabel.textColor = TUISwift.tuiDynamicColor("", module: TUIThemeModule.core_Minimalist, defaultColor: "#000000")
        if let cellTitleLabelFont = TUIConversationConfig.sharedConfig.cellTitleLabelFont {
            titleLabel.font = cellTitleLabelFont
        }
        
        subTitleLabel.attributedText = convData.subTitle
        if let cellSubtitleLabelFont = TUIConversationConfig.sharedConfig.cellSubtitleLabelFont {
            subTitleLabel.font = cellSubtitleLabelFont
        }
        
        timeLabel.text = TUITool.convertDate(toStr: convData.time)
        if let cellTimeLabelFont = TUIConversationConfig.sharedConfig.cellTimeLabelFont {
            timeLabel.font = cellTimeLabelFont
        }
        
        configRedPoint(convData)
        configHeadImageView(convData)
        
        self.titleLabel.text = convData.title.value
        
        if let imageName = convData.showCheckBox && convData.selected ? TUISwift.timCommonImagePath("icon_select_selected") : TUISwift.timCommonImagePath("icon_select_normal") {
            selectedIcon.image = UIImage(named: imageName)
        }
        
        let image = TUISwift.tuiDynamicImage("", themeModule: TUIThemeModule.conversation_Minimalist, defaultImg: UIImage(named: TUISwift.tuiConversationImagePath_Minimalist("message_not_disturb")))
        notDisturbView.image = image
        
        configOnlineStatusIcon(convData)
        configDisplayLastMessageStatusImage(convData)
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    func configHeadImageView(_ convData: TUIConversationCellData) {
        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = headImageView.frame.size.height / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        if let groupID = convData.groupID {
            var avatar: UIImage? = nil
            if TUIConfig.default().enableGroupGridAvatar {
                let key = "TUIConversationLastGroupMember_\(groupID)"
                let member = UserDefaults.standard.integer(forKey: key)
                avatar = TUIGroupAvatar.getCacheAvatar(forGroup: groupID, number: UInt32(member))
            }
            convData.avatarImage = avatar ?? TUISwift.defaultGroupAvatarImage(byGroupType: convData.groupType)
        }
        
        let faceUrl = convData.faceUrl.value
        if let _ = self.convData?.groupID {
            // Group avatar
            if !faceUrl.isEmpty {
                // The group avatar has been manually set externally
                self.headImageView.sd_setImage(with: URL(string: faceUrl), placeholderImage: convData.avatarImage)
            } else {
                /**
                 * The group avatar has not been set externally. If the synthetic avatar is allowed, the synthetic avatar will be used; otherwise, the default
                 * avatar will be used.
                 */
                if TUIConfig.default().enableGroupGridAvatar {
                    /**
                     *
                     * If the synthetic avatar is allowed, the synthetic avatar will be used
                     * 1. Asynchronously obtain the cached synthetic avatar according to the number of group members
                     * 2. If the cache is hit, use the cached synthetic avatar directly
                     * 3. If the cache is not hit, recompose a new avatar
                     *
                     * Note:
                     * 1. Since "asynchronously obtaining cached avatars" and "synthesizing avatars" take a long time, it is easy to cause cell reuse problems, so
                     * it is necessary to confirm whether to assign values directly according to groupID.
                     * 2. Use SDWebImage to implement placeholder, because SDWebImage has already dealt with the problem of cell reuse
                     */

                    // 1. Obtain group avatar from cache

                    // fix: The getCacheGroupAvatar needs to request the
                    // network. When the network is disconnected, since the headImageView is not set, the current conversation sends a message, the conversation
                    // is moved up, and the avatar of the first conversation is reused, resulting in confusion of the avatar.
                    self.headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                    guard let getGroupID = convData.groupID else { return }
                    TUIGroupAvatar.getCacheGroupAvatar(getGroupID) { [weak self] avatar, groupID in
                        guard let self = self, groupID == self.convData?.groupID else { return }
                        
                        if !avatar.size.equalTo(CGSizeZero) {
                            // 2. Hit the cache and assign directly
                            self.headImageView.sd_setImage(with: nil, placeholderImage: avatar)
                        } else {
                            // 3. Synthesize new avatars asynchronously without hitting cache
                            self.headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                            TUIGroupAvatar.fetchGroupAvatars(getGroupID, placeholder: convData.avatarImage ?? UIImage()) { [weak self] success, image, groupID in
                                guard let self = self else { return }
                                
                                if groupID == self.convData?.groupID {
                                    // callback, cell is not reused
                                    self.headImageView.sd_setImage(with: nil, placeholderImage: success ? image : TUISwift.defaultGroupAvatarImage(byGroupType: convData.groupType))
                                } else {
                                    // When the callback is invoked, the cell has been reused to other groupIDs.
                                    // Since a new callback will be triggered when the new groupID synthesizes new avatar, it is
                                    // ignored here
                                }
                            }
                        }
                    }
                } else {
                    /**
                     * Synthetic avatars are not allowed, use the default avatar directly
                     */
                    self.headImageView.sd_setImage(with: nil, placeholderImage: convData.avatarImage)
                }
            }
        } else {
            // Personal avatar
            self.headImageView.sd_setImage(with: URL(string: faceUrl), placeholderImage: convData.avatarImage)
        }
    }
    
    override func configRedPoint(_ convData: TUIConversationCellData) {
        if convData.isNotDisturb {
            notDisturbRedDot.isHidden = convData.unreadCount == 0
            notDisturbView.isHidden = false
            unReadView.isHidden = true
            notDisturbView.image = TUISwift.tuiConversationBundleThemeImage("conversation_message_not_disturb_img", defaultImageName: "message_not_disturb")
        } else {
            notDisturbRedDot.isHidden = true
            notDisturbView.isHidden = true
            unReadView.setNum(convData.unreadCount)
            unReadView.isHidden = convData.unreadCount == 0 ? true : !TUIConversationConfig.sharedConfig.showCellUnreadCount
        }
        
        if convData.isMarkAsUnread {
            if convData.isNotDisturb {
                notDisturbRedDot.isHidden = false
            } else {
                unReadView.setNum(1)
                unReadView.isHidden = !TUIConversationConfig.sharedConfig.showCellUnreadCount
            }
        }
        
        if convData.isLocalConversationFoldList {
            notDisturbView.isHidden = true
        }
    }
    
    override func configOnlineStatusIcon(_ convData: TUIConversationCellData) {
        TUISwift.racObserveTUIConfig_displayOnlineStatusIcon(self) { [weak self] _ in
            guard let self = self else { return }
            if convData.onlineStatus == .online && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = false
                self.onlineStatusIcon.image = TUISwift.timCommonDynamicImage("icon_online_status", defaultImage: UIImage(named: TUISwift.timCommonImagePath("icon_online_status"))!)
            } else if convData.onlineStatus == .offline && TUIConfig.default().displayOnlineStatusIcon {
                self.onlineStatusIcon.isHidden = true
                self.onlineStatusIcon.image = nil
            } else {
                self.onlineStatusIcon.isHidden = true
                self.onlineStatusIcon.image = nil
            }
        }
    }
    
    override func configDisplayLastMessageStatusImage(_ convData: TUIConversationCellData) {
        let image = getDisplayLastMessageStatusImage(convData)
        lastMessageStatusImageView.image = image
    }
    
    override func getDisplayLastMessageStatusImage(_ convData: TUIConversationCellData) -> UIImage? {
        var image: UIImage? = nil
        if let lastMessage = convData.lastMessage {
            if lastMessage.status == V2TIMMessageStatus.MSG_STATUS_SENDING || lastMessage.status == V2TIMMessageStatus.MSG_STATUS_SEND_FAIL {
                if lastMessage.status == V2TIMMessageStatus.MSG_STATUS_SENDING {
                    image = UIImage(named: TUISwift.tuiConversationImagePath_Minimalist("icon_sendingmark"))
                } else {
                    image = UIImage(named: TUISwift.tuiConversationImagePath_Minimalist("msg_error_for_conv"))
                }
            }
        }
        return image
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        guard let convData = convData else { return }
        
        let height = convData.height(ofWidth: mm_w)
        mm_h = height
        let imgHeight = height - 2 * TUISwift.kScale390(12)
        
        if convData.isOnTop {
            contentView.backgroundColor = TUIConversationConfig.sharedConfig.pinnedCellBackgroundColor ?? TUISwift.tuiConversationDynamicColor("conversation_cell_top_bg_color", defaultColor: "#F4F4F4")
        } else {
            contentView.backgroundColor = TUIConversationConfig.sharedConfig.cellBackgroundColor ?? TUISwift.tuiConversationDynamicColor("conversation_cell_bg_color", defaultColor: "#FFFFFF")
        }
        
        let selectedIconSize: CGFloat = 20
        if convData.showCheckBox {
            selectedIcon.isHidden = false
        } else {
            selectedIcon.isHidden = true
        }
        
        selectedIcon.snp.remakeConstraints { make in
            if convData.showCheckBox {
                make.width.height.equalTo(selectedIconSize)
                make.leading.equalTo(contentView).offset(10)
                make.centerY.equalTo(contentView)
            }
        }
        
        headImageView.snp.remakeConstraints { make in
            make.size.equalTo(imgHeight)
            make.centerY.equalTo(contentView)
            if convData.showCheckBox {
                make.leading.equalTo(selectedIcon.snp.trailing).offset(TUISwift.kScale390(16))
            } else {
                make.leading.equalTo(contentView).offset(TUISwift.kScale390(16))
            }
        }
        
        if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRounded {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = imgHeight / 2
        } else if TUIConfig.default().avatarType == TUIKitAvatarType.TAvatarTypeRadiusCorner {
            headImageView.layer.masksToBounds = true
            headImageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        
        timeLabel.sizeToFit()
        timeLabel.snp.remakeConstraints { make in
            make.width.equalTo(timeLabel.frame.size.width)
            make.height.greaterThanOrEqualTo(timeLabel.font.lineHeight)
            make.top.equalTo(subTitleLabel)
            make.trailing.equalTo(contentView).offset(-TUISwift.kScale390(8))
        }
        
        lastMessageStatusImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale390(14))
            make.trailing.equalTo(timeLabel.snp.leading).offset(-(TUISwift.kScale390(1) + TUISwift.kScale390(8)))
            make.bottom.equalTo(timeLabel)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.width.greaterThanOrEqualTo(120)
            make.height.greaterThanOrEqualTo(titleLabel.font.lineHeight)
            make.top.equalTo(contentView).offset(TUISwift.kScale390(14))
            make.leading.equalTo(headImageView.snp.trailing).offset(TUISwift.kScale390(8))
            make.trailing.equalTo(timeLabel).offset(-2 * TUISwift.kScale390(14))
        }
        
        subTitleLabel.sizeToFit()
        subTitleLabel.snp.remakeConstraints { make in
            make.height.greaterThanOrEqualTo(subTitleLabel)
            make.bottom.equalTo(contentView).offset(-TUISwift.kScale390(14))
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(timeLabel.snp.leading).offset(-TUISwift.kScale390(8))
        }
        
        unReadView.unReadLabel.sizeToFit()
        unReadView.snp.remakeConstraints { make in
            make.trailing.equalTo(timeLabel)
            make.top.equalTo(titleLabel)
            make.width.equalTo(TUISwift.kScale375(18))
            make.height.equalTo(TUISwift.kScale375(18))
        }
        
        unReadView.unReadLabel.snp.remakeConstraints { make in
            make.center.equalTo(unReadView)
            make.size.equalTo(unReadView.unReadLabel)
        }
        
        unReadView.layer.cornerRadius = TUISwift.kScale375(18) * 0.5
        unReadView.layer.masksToBounds = true
        
        notDisturbRedDot.snp.remakeConstraints { make in
            make.trailing.equalTo(headImageView).offset(3)
            make.top.equalTo(headImageView).offset(1)
            make.width.height.equalTo(TConversationCell_Margin_Disturb_Dot)
        }
        
        notDisturbView.snp.remakeConstraints { make in
            make.width.height.equalTo(TConversationCell_Margin_Disturb)
            make.trailing.equalTo(timeLabel)
            make.top.equalTo(titleLabel)
        }
        
        onlineStatusIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(TUISwift.kScale375(15))
            make.leading.equalTo(headImageView.snp.trailing).offset(-TUISwift.kScale375(10))
            make.bottom.equalTo(headImageView).offset(-TUISwift.kScale375(1))
        }
        
        onlineStatusIcon.layer.cornerRadius = 0.5 * TUISwift.kScale375(15)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
