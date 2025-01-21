import TIMCommon
import UIKit

class TUIImageMessageCell: TUIBubbleMessageCell {
    var thumb: UIImageView!
    private var imageData: TUIImageMessageCellData?
    private var thumbImageObservation: NSKeyValueObservation?
    private var thumbProgressObservation: NSKeyValueObservation?
    private var progress: UILabel!

    private let animateHighlightView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        thumb = UIImageView()
        thumb.layer.cornerRadius = 5.0
        thumb.layer.masksToBounds = true
        thumb.contentMode = .scaleAspectFit
        thumb.backgroundColor = .clear
        container.addSubview(thumb)

        progress = UILabel()
        progress.textColor = .white
        progress.font = UIFont.systemFont(ofSize: 15)
        progress.textAlignment = .center
        progress.layer.cornerRadius = 5.0
        progress.isHidden = true
        progress.backgroundColor = TUISwift.tImageMessageCell_Progress_Color()
        progress.layer.masksToBounds = true
        container.addSubview(progress)

        makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        thumbProgressObservation?.invalidate()
        thumbProgressObservation = nil
    }

    override func fill(with data: TUIBubbleMessageCellData) {
        super.fill(with: data)
        guard let imageData = data as? TUIImageMessageCellData else {
            assertionFailure("data must be kind of TUIImageMessageCellData")
            return
        }
        self.imageData = imageData
        thumb.image = nil

        let hasRiskContent = messageData.innerMessage.hasRiskContent
        if hasRiskContent {
            thumb.image = TUISwift.timCommonBundleThemeImage("", defaultImage: "icon_security_strike")
            securityStrikeView.textLabel.text = TUISwift.timCommonLocalizableString("TUIKitMessageTypeSecurityStrikeImage")
            progress.isHidden = true
            return
        }

        thumbImageObservation?.invalidate()
        thumbImageObservation = imageData.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.thumb.image = thumbImage
        }

        thumbProgressObservation?.invalidate()
        thumbProgressObservation = imageData.observe(\.thumbProgress, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            self.progress.text = "\(progress)%"
            self.progress.isHidden = (progress >= 100 || progress == 0)
        }

        if imageData.thumbImage == nil {
            imageData.downloadImage(type: .thumb)
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    private func makeConstraints() {
        thumb.snp.makeConstraints { make in
            make.edges.equalTo(container)
        }

        progress.snp.makeConstraints { make in
            make.edges.equalTo(container)
        }
    }

    override func updateConstraints() {
        super.updateConstraints()

        if imageData?.isSuperLongImage == true {
            thumb.contentMode = .scaleToFill
        } else {
            thumb.contentMode = .scaleAspectFit
        }

        var topMargin: CGFloat = 0
        var height = bubbleView.mm_h
        if messageData.messageContainerAppendSize.height > 0 {
            topMargin = 10
            let tagViewTopMargin: CGFloat = 6
            height = bubbleView.mm_h - topMargin - messageData.messageContainerAppendSize.height - tagViewTopMargin
            thumb.snp.remakeConstraints { make in
                make.height.equalTo(height)
                make.width.equalTo(bubbleView)
                make.top.equalTo(bubbleView).offset(topMargin)
                make.leading.equalTo(bubbleView)
            }
        } else {
            thumb.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView).offset(messageData.cellLayout.bubbleInsets.top)
                make.bottom.equalTo(bubbleView).offset(-messageData.cellLayout.bubbleInsets.bottom)
                make.leading.equalTo(bubbleView).offset(messageData.cellLayout.bubbleInsets.left)
                make.trailing.equalTo(bubbleView).offset(-messageData.cellLayout.bubbleInsets.right)
            }
        }

        let hasRiskContent = messageData.innerMessage.hasRiskContent
        if hasRiskContent {
            thumb.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView).offset(12)
                make.size.equalTo(CGSize(width: 150, height: 150))
                make.centerX.equalTo(bubbleView)
            }

            securityStrikeView.snp.remakeConstraints { make in
                make.top.equalTo(thumb.snp.bottom)
                make.width.equalTo(bubbleView)
                make.bottom.equalTo(container).offset(-messageData.messageContainerAppendSize.height)
            }
        }

        progress.snp.remakeConstraints { make in
            make.edges.equalTo(bubbleView)
        }

        selectedView.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }

        selectedIcon.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(3)
            make.top.equalTo(avatarView.snp.centerY).offset(-10)
            if messageData.showCheckBox {
                make.width.equalTo(20)
                make.height.equalTo(20)
            } else {
                make.size.equalTo(CGSize.zero)
            }
        }

        timeLabel.sizeToFit()
        timeLabel.snp.remakeConstraints { make in
            make.trailing.equalTo(contentView).offset(-10)
            make.top.equalTo(avatarView)
            if messageData.showMessageTime {
                make.width.equalTo(timeLabel.frame.size.width)
                make.height.equalTo(timeLabel.frame.size.height)
            } else {
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func highlight(whenMatchKeyword keyword: String?) {
        if let _ = keyword {
            if highlightAnimating {
                return
            }
            animate(times: 3)
        }
    }

    private func animate(times: Int) {
        var times = times
        times -= 1
        if times < 0 {
            animateHighlightView.removeFromSuperview()
            highlightAnimating = false
            return
        }
        highlightAnimating = true
        animateHighlightView.frame = container.bounds
        animateHighlightView.alpha = 0.1
        container.addSubview(animateHighlightView)

        UIView.animate(withDuration: 0.25, animations: {
            self.animateHighlightView.alpha = 0.5
        }, completion: { _ in
            UIView.animate(withDuration: 0.25, animations: {
                self.animateHighlightView.alpha = 0.1
            }, completion: { _ in
                if let imageData = self.imageData, !(imageData.highlightKeyword?.isEmpty ?? false) {
                    self.animate(times: 0)
                    return
                }
                self.animate(times: times)
            })
        })
    }

    // MARK: - TUIMessageCelllProtocol

    override class func getEstimatedHeight(_ data: TUIMessageCellData) -> CGFloat {
        return 186.0
    }

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let imageCellData = data as? TUIImageMessageCellData else {
            assertionFailure("data must be kind of TUIImageMessageCellData")
            return CGSize.zero
        }
        guard let path = imageCellData.path else { return CGSize.zero }

        var size = CGSize.zero
        var isDir = ObjCBool(false)
        if !path.isEmpty && FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue {
            size = UIImage(contentsOfFile: path)?.size ?? CGSize.zero
        }

        if size == .zero {
            for item in imageCellData.items {
                if item.type == .thumb {
                    size = item.size
                }
            }
        }

        if size == .zero {
            for item in imageCellData.items {
                if item.type == .large {
                    size = item.size
                }
            }
        }

        if size == .zero {
            for item in imageCellData.items {
                if item.type == .origin {
                    size = item.size
                }
            }
        }

        if size == .zero {
            return size
        }

        if size.height > size.width {
            if size.height > 5 * size.width {
                size.width = TUISwift.tImageMessageCell_Image_Width_Max()
                size.height = TUISwift.tImageMessageCell_Image_Height_Max()
                imageCellData.isSuperLongImage = true
            } else {
                size.width = size.width / size.height * TUISwift.tImageMessageCell_Image_Height_Max()
                size.height = TUISwift.tImageMessageCell_Image_Height_Max()
            }
        } else {
            size.height = size.height / size.width * TUISwift.tImageMessageCell_Image_Width_Max()
            size.width = TUISwift.tImageMessageCell_Image_Width_Max()
        }

        let hasRiskContent = imageCellData.innerMessage.hasRiskContent
        if hasRiskContent {
            let bubbleTopMargin: CGFloat = 12
            let bubbleBottomMargin: CGFloat = 12
            size.height = max(size.height, 150)
            size.width = max(size.width, 200)
            size.height += bubbleTopMargin
            size.height += kTUISecurityStrikeViewTopLineMargin
            size.height += CGFloat(kTUISecurityStrikeViewTopLineToBottom)
            size.height += bubbleBottomMargin
        }

        return size
    }
}
