import UIKit

enum TUIMessageStatus: Int {
    case unknown
    case sending
    case sendSuccess
    case somePeopleRead
    case allPeopleRead
}

open class TUIMessageCell_Minimalist: TUIMessageCell {
    public var replyLineView: UIImageView = .init(frame: .zero)
    public var replyAvatarImageViews: [UIImageView] = []
    public var msgStatusView: UIImageView = .init(frame: .zero)
    public var msgTimeLabel: UILabel = .init(frame: .zero)
    private var status: TUIMessageStatus = .unknown
    private var animationImages: [UIImage] = []

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        replyLineView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(replyLineView)

        messageModifyRepliesButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        messageModifyRepliesButton.contentHorizontalAlignment = TUISwift.isRTL() ? .right : .left
        messageModifyRepliesButton.setTitleColor(TUISwift.rgba(0, g: 95, b: 255, a: 1), for: .normal)

        msgStatusView.contentMode = .scaleAspectFit
        msgStatusView.layer.zPosition = .greatestFiniteMagnitude
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onJumpToMessageInfoPage))
        msgStatusView.addGestureRecognizer(tapGesture)
        msgStatusView.isUserInteractionEnabled = true
        container.addSubview(msgStatusView)

        msgTimeLabel.textColor = TUISwift.rgba(102, g: 102, b: 102, a: 1)
        msgTimeLabel.font = UIFont.systemFont(ofSize: 12)
        msgTimeLabel.rtlAlignment = .trailing
        msgTimeLabel.layer.zPosition = CGFloat(Int.max)
        container.addSubview(msgTimeLabel)

        for i in 1 ... 45 {
            let imageName = "msg_status_sending_\(i)"
            if let image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist(imageName)) {
                animationImages.append(image)
            }
        }
    }

    func prepareReactTagUI(_ containerView: UIView) {
        let param: [String: Any] = ["TUICore_TUIChatExtension_ChatMessageReactPreview_Delegate": self]
        _ = TUICore.raiseExtension("TUICore_TUIChatExtension_ChatMessageReactPreview_MinimalistExtensionID", parentView: containerView, param: param)
    }

    override open func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUIMessageCellData else { return }
        readReceiptLabel.isHidden = true
        messageModifyRepliesButton.isHidden = true
        messageModifyRepliesButton.setImage(nil, for: .normal)
        prepareReactTagUI(contentView)

        if !replyAvatarImageViews.isEmpty {
            for imageView in replyAvatarImageViews {
                imageView.removeFromSuperview()
            }
            replyAvatarImageViews.removeAll()
        }
        replyLineView.isHidden = true
        if data.showMessageModifyReplies {
            replyLineView.isHidden = false
            messageModifyRepliesButton.isHidden = false

            let lineImage: UIImage?
            if data.direction == .incoming {
                lineImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_reply_line_income"))
            } else {
                lineImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_reply_line_outcome"))
            }
            replyLineView.image = lineImage?.rtlImageFlippedForRightToLeftLayoutDirection().resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0), resizingMode: .stretch)

            var avatarCount = 0
            let avatarMaxCount = 4
            var existSenderMap: [String: String] = [:]
            if let replies = data.messageModifyReplies {
                for senderMap in replies {
                    guard let sender = senderMap["messageSender"] as? String else { continue }
                    let userModel = data.additionalUserInfoResult[sender]
                    let headUrl = URL(string: userModel?.faceURL ?? "")

                    if existSenderMap["messageSender"] == sender {
                        continue
                    }
                    let avatarView = UIImageView()
                    if avatarCount < avatarMaxCount - 1 {
                        existSenderMap["messageSender"] = sender
                        avatarView.sd_setImage(with: headUrl, placeholderImage: TUISwift.defaultAvatarImage())
                    } else {
                        avatarView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_reply_more_icon"))
                    }
                    replyAvatarImageViews.append(avatarView)
                    contentView.addSubview(avatarView)

                    if avatarCount >= avatarMaxCount {
                        break
                    }
                    avatarCount += 1
                }
            }
        }

        msgTimeLabel.text = TUITool.convertDate(toHMStr: data.innerMessage?.timestamp)

        indicator.isHidden = true
        msgStatusView.isHidden = true
        readReceiptLabel.isHidden = true
        if data.direction == .outgoing {
            status = .unknown
            if data.status == .sending || data.status == .sending2 {
                updateMessageStatus(.sending)
            } else if data.status == .success {
                updateMessageStatus(.sendSuccess)
            }
            updateReadLabelText()
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    @objc private func onJumpToMessageInfoPage() {
        guard let messageData = messageData else { return }
        delegate?.onJumpToMessageInfoPage(messageData, selectCell: self)
    }

    override public func updateReadLabelText() {
        guard let messageData = messageData else { return }
        if let groupID = messageData.innerMessage?.groupID, !groupID.isEmpty {
            guard let messageReceipt = messageData.messageReceipt else { return }
            let readCount = messageReceipt.readCount
            let unreadCount = messageReceipt.unreadCount
            if unreadCount == 0 {
                updateMessageStatus(.allPeopleRead)
            } else if readCount > 0 {
                updateMessageStatus(.somePeopleRead)
            }
        } else {
            if messageData.messageReceipt?.isPeerRead == true {
                updateMessageStatus(.allPeopleRead)
            }
        }
    }

    private func updateMessageStatus(_ status: TUIMessageStatus) {
        if status.rawValue <= self.status.rawValue {
            return
        }

        if let messageData = messageData, let innerMessage = messageData.innerMessage {
            if messageData.showReadReceipt && messageData.direction == .outgoing && innerMessage.needReadReceipt && ((innerMessage.userID?.count ?? 0) != 0 || (innerMessage.groupID?.count ?? 0) != 0) {
                msgStatusView.isHidden = false
                msgStatusView.image = nil
            }
        }

        if msgStatusView.isAnimating {
            msgStatusView.stopAnimating()
            msgStatusView.animationImages = nil
        }
        switch status {
        case .sending:
            msgStatusView.animationImages = animationImages
            msgStatusView.startAnimating()
        case .sendSuccess:
            msgStatusView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_send_succ"))
        case .somePeopleRead:
            msgStatusView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_some_people_read"))
        case .allPeopleRead:
            msgStatusView.image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_status_all_people_read"))
        default:
            break
        }
        self.status = status
    }

    override open class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override open func updateConstraints() {
        super.updateConstraints()

        guard let messageData = messageData else { return }
        let cellLayout = messageData.cellLayout ?? TUIMessageCellLayout(isIncoming: true)
        let isInComing = (messageData.direction == .incoming)

        nameLabel.snp.remakeConstraints { make in
            if isInComing {
                make.leading.equalTo(container.snp.leading).offset(7)
            } else {
                make.trailing.equalTo(container.snp.trailing)
            }
            if messageData.showName {
                make.width.greaterThanOrEqualTo(20)
                make.height.greaterThanOrEqualTo(20)
            } else {
                make.height.equalTo(0)
            }
            make.top.equalTo(avatarView.snp.top)
        }

        selectedIcon.snp.remakeConstraints { make in
            make.leading.equalTo(contentView.snp.leading).offset(3)
            make.centerY.equalTo(container.snp.centerY)
            if messageData.showCheckBox {
                make.width.equalTo(20)
                make.height.equalTo(20)
            } else {
                make.size.equalTo(CGSize.zero)
            }
        }

        timeLabel.sizeToFit()
        timeLabel.snp.updateConstraints { make in
            if messageData.showMessageTime {
                make.width.equalTo(timeLabel.frame.size.width)
                make.height.equalTo(timeLabel.frame.size.height)
            } else {
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
        }

        let csize = type(of: self).getContentSize(messageData)
        let contentWidth = csize.width
        let contentHeight = csize.height

        if messageData.direction == .incoming {
            avatarView.isHidden = !messageData.showAvatar
            avatarView.snp.remakeConstraints { make in
                if messageData.showCheckBox {
                    make.leading.equalTo(selectedIcon.snp.trailing).offset(cellLayout.avatarInsets.left)
                } else {
                    make.leading.equalTo(contentView.snp.leading).offset(cellLayout.avatarInsets.left)
                }
                make.top.equalTo(cellLayout.avatarInsets.top)
                make.size.equalTo(cellLayout.avatarSize)
            }

            container.snp.remakeConstraints { make in
                make.leading.equalTo(avatarView.snp.trailing).offset(cellLayout.messageInsets.left)
                make.top.equalTo(nameLabel.snp.bottom).offset(cellLayout.messageInsets.top)
                make.width.equalTo(contentWidth)
                make.height.equalTo(contentHeight)
            }

            let indicatorFrame = indicator.frame
            indicator.snp.remakeConstraints { make in
                make.leading.equalTo(container.snp.trailing).offset(8)
                make.centerY.equalTo(container.snp.centerY)
                make.size.equalTo(indicatorFrame.size)
            }
            retryView.frame = indicator.frame
            readReceiptLabel.isHidden = true
        } else {
            if !messageData.showAvatar {
                cellLayout.avatarSize = .zero
            }
            avatarView.snp.remakeConstraints { make in
                make.trailing.equalTo(contentView.snp.trailing).offset(-cellLayout.avatarInsets.right)
                make.top.equalTo(cellLayout.avatarInsets.top)
                make.size.equalTo(cellLayout.avatarSize)
            }

            container.snp.remakeConstraints { make in
                make.trailing.equalTo(avatarView.snp.leading).offset(-cellLayout.messageInsets.right)
                make.top.equalTo(nameLabel.snp.bottom).offset(cellLayout.messageInsets.top)
                make.width.equalTo(contentWidth)
                make.height.equalTo(contentHeight)
            }

            let indicatorFrame = indicator.frame
            indicator.snp.remakeConstraints { make in
                make.trailing.equalTo(container.snp.leading).offset(-8)
                make.centerY.equalTo(container.snp.centerY)
                make.size.equalTo(indicatorFrame.size)
            }

            retryView.frame = indicator.frame

            readReceiptLabel.sizeToFit()
            readReceiptLabel.snp.remakeConstraints { make in
                make.bottom.equalTo(container.snp.bottom)
                make.trailing.equalTo(container.snp.leading).offset(-8)
                make.size.equalTo(readReceiptLabel.frame.size)
            }
        }

        if !messageModifyRepliesButton.isHidden {
            messageModifyRepliesButton.mm_sizeToFit()
            let repliesBtnTextWidth = messageModifyRepliesButton.frame.size.width
            messageModifyRepliesButton.snp.remakeConstraints { make in
                if isInComing {
                    make.leading.equalTo(container.snp.leading)
                } else {
                    make.trailing.equalTo(container.snp.trailing)
                }
                make.top.equalTo(container.snp.bottom)
                make.size.equalTo(CGSize(width: repliesBtnTextWidth + 10, height: 30))
            }
        }

        if messageData.showMessageModifyReplies && replyAvatarImageViews.count > 0 {
            let lineViewW: CGFloat = 17
            let avatarSize: CGFloat = 16
            let repliesBtnW = TUISwift.kScale390(54)
            let avatarY = contentView.mm_h - (messageData.sameToNextMsgSender ? avatarSize : avatarSize * 2)

            if messageData.direction == .incoming {
                var preAvatarImageView: UIImageView?
                for i in 0..<replyAvatarImageViews.count {
                    let avatarView = replyAvatarImageViews[i]
                    avatarView.snp.remakeConstraints { make in
                        if i == 0 {
                            make.leading.equalTo(replyLineView.snp.trailing)
                        } else {
                            make.leading.equalTo(preAvatarImageView!.snp.centerX)
                        }
                        make.top.equalTo(avatarY)
                        make.width.height.equalTo(avatarSize)
                    }
                    avatarView.layer.masksToBounds = true
                    avatarView.layer.cornerRadius = avatarSize / 2.0
                    preAvatarImageView = avatarView
                }
            } else {
                var preAvatarImageView: UIImageView?
                let count = replyAvatarImageViews.count
                for i in (0..<count).reversed() {
                    let avatarView = replyAvatarImageViews[i]
                    avatarView.snp.remakeConstraints { make in
                        if preAvatarImageView == nil {
                            make.trailing.equalTo(messageModifyRepliesButton.snp.leading)
                        } else {
                            make.trailing.equalTo(preAvatarImageView!.snp.centerX)
                        }
                        make.top.equalTo(avatarY)
                        make.width.height.equalTo(avatarSize)
                    }
                    avatarView.layer.masksToBounds = true
                    avatarView.layer.cornerRadius = avatarSize / 2.0
                    preAvatarImageView = avatarView
                }
            }

            let lastAvatarImageView = replyAvatarImageViews.last!

            messageModifyRepliesButton.snp.remakeConstraints { make in
                if messageData.direction == .incoming {
                    make.leading.equalTo(lastAvatarImageView.snp.trailing)
                } else {
                    make.trailing.equalTo(replyLineView.snp.leading)
                }
                make.top.equalTo(avatarY)
                make.size.equalTo(CGSize(width: repliesBtnW, height: avatarSize))
            }

            replyLineView.snp.remakeConstraints { make in
                if messageData.direction == .incoming {
                    make.leading.equalTo(container.snp.leading).offset(-1)
                } else {
                    make.trailing.equalTo(container.snp.trailing)
                }
                make.top.equalTo(container.frame.maxY - 14)
                make.width.equalTo(lineViewW)
                make.bottom.equalTo(messageModifyRepliesButton.snp.centerY)
            }
        } else {
            replyLineView.frame = .zero
            messageModifyRepliesButton.frame = .zero
        }

        msgTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(messageData.msgStatusSize.height)
            make.bottom.equalTo(container).offset(-TUISwift.kScale390(9))
            make.trailing.equalTo(container).offset(-TUISwift.kScale390(16))
        }

        msgStatusView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(messageData.msgStatusSize.height)
            make.bottom.equalTo(msgTimeLabel)
            make.trailing.equalTo(msgTimeLabel.snp.leading)
        }
    }

    override open class func getHeight(_ data: TUIMessageCellData, withWidth width: CGFloat) -> CGFloat {
        var height = super.getHeight(data, withWidth: width)
        if let cellLayout = data.cellLayout, data.sameToNextMsgSender {
            height -= TUISwift.kScale375(16)
        }
        return height
    }
}
