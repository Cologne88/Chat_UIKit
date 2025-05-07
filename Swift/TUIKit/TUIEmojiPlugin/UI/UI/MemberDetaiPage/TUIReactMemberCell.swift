//
//  TUIReactMemberCell.swift
//  TUIChat
//
//  Created by wyl on 2022/5/26.
//  Copyright © 2023 Tencent. All rights reserved.
//

import SDWebImage
import TIMCommon
import UIKit

let Avatar_Size: CGFloat = 40

class TUIReactMemberCell: UITableViewCell {
    let avatar: UIImageView = .init()
    let displayName: UILabel = .init()
    let tapToRemoveLabel: UILabel = .init()
    let emoji: UIImageView = .init()
    
    var data: TUIReactMemberCellData?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        avatar.layer.cornerRadius = Avatar_Size / 2.0
        avatar.layer.masksToBounds = true
        contentView.addSubview(avatar)
        
        displayName.font = UIFont.boldSystemFont(ofSize: TUISwift.kScale390(16))
        displayName.textColor = UIColor.tui_color(withHex: "#666666")
        displayName.textAlignment = TUISwift.isRTL() ? .right : .left
        contentView.addSubview(displayName)
        
        tapToRemoveLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        tapToRemoveLabel.textColor = UIColor.tui_color(withHex: "#666666")
        tapToRemoveLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        contentView.addSubview(tapToRemoveLabel)
        
        contentView.addSubview(emoji)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - UI

    func prepareUI() {
        layer.cornerRadius = 12.0
        layer.masksToBounds = true
    }
    
    func fill(with data: TUIReactMemberCellData?) {
        self.data = data
        
        if let faceURLString = data?.faceURL, let url = URL(string: faceURLString) {
            avatar.sd_setImage(with: url, placeholderImage: TUISwift.defaultAvatarImage())
        } else {
            avatar.image = TUISwift.defaultAvatarImage()
        }
        
        displayName.text = data?.displayName()
        tapToRemoveLabel.text = ""
        if let isCurrentUser = data?.isCurrentUser, isCurrentUser {
            displayName.text = TUISwift.timCommonLocalizableString("You")
            tapToRemoveLabel.text = TUISwift.timCommonLocalizableString("TUIKitChatTap2Remove")
        }
        
        if let emojiName = data?.emojiName {
            emoji.image = emojiName.getEmojiImage()
        } else {
            emoji.image = nil
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
        
        let avatarSize = TUISwift.kScale390(40)
        
        avatar.snp.remakeConstraints { make in
            make.leading.equalTo(TUISwift.kScale390(26))
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(avatarSize)
        }
        
        displayName.snp.remakeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(TUISwift.kScale390(16))
            make.trailing.equalTo(-TUISwift.kScale390(60))
            make.height.equalTo(TUISwift.kScale390(22))
            make.centerY.equalTo(contentView)
        }
        
        if let currentData = data, currentData.isCurrentUser {
            displayName.snp.remakeConstraints { make in
                make.leading.equalTo(avatar.snp.trailing).offset(TUISwift.kScale390(16))
                make.top.equalTo(avatar.snp.top)
                make.trailing.equalTo(-TUISwift.kScale390(60))
                make.height.equalTo(TUISwift.kScale390(22))
            }
            tapToRemoveLabel.snp.remakeConstraints { make in
                make.leading.equalTo(displayName.snp.leading)
                make.top.equalTo(displayName.snp.bottom).offset(TUISwift.kScale390(4))
                make.trailing.equalTo(-TUISwift.kScale390(60))
                make.height.equalTo(TUISwift.kScale390(12))
            }
        }
        
        emoji.snp.remakeConstraints { make in
            make.trailing.equalTo(contentView.snp.trailing).offset(-TUISwift.kScale390(32))
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(TUISwift.kScale390(16))
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
