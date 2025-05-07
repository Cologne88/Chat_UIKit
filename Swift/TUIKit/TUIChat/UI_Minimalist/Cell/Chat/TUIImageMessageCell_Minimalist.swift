import TIMCommon
import UIKit

class TUIImageMessageCell_Minimalist: TUIMessageCell_Minimalist {
    private var imageData: TUIImageMessageCellData?
    private var thumbImageObservation: NSKeyValueObservation?
    private var thumbProgressObservation: NSKeyValueObservation?
    var thumb: UIImageView!
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

        msgTimeLabel.textColor = TUISwift.rgb(255, g: 255, b: 255)
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

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let imageData = data as? TUIImageMessageCellData else {
            assertionFailure("data must be kind of TUIImageMessageCellData")
            return
        }
        self.imageData = imageData
        thumb.image = nil

        if let hasRiskContent = messageData?.innerMessage?.hasRiskContent, hasRiskContent {
            thumb.image = TUISwift.timCommonBundleThemeImage("", defaultImage: "icon_security_strike")
            progress.isHidden = true
            return
        }

        if imageData.thumbImage == nil {
            imageData.downloadImage(type: TUIImageType.thumb)
        }

        thumbImageObservation?.invalidate()
        thumbImageObservation = imageData.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.thumb.image = thumbImage
            self.setNeedsUpdateConstraints()
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }

        if imageData.direction == .incoming {
            thumbProgressObservation?.invalidate()
            thumbProgressObservation = imageData.observe(\.thumbProgress, options: [.new, .initial]) { [weak self] _, change in
                guard let self = self, let progress = change.newValue else { return }
                self.progress.text = "\(progress)%"
                self.progress.isHidden = (progress >= 100 || progress == 0)

                self.setNeedsUpdateConstraints()
                self.updateConstraintsIfNeeded()
                self.layoutIfNeeded()
            }
        }

        if imageData.thumbImage == nil {
            imageData.downloadImage(type: .thumb)
        }
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

        let height = container.mm_h

        let hasRiskContent = messageData?.innerMessage?.hasRiskContent ?? false
        thumb.snp.remakeConstraints { make in
            if hasRiskContent {
                make.top.equalTo(self.container).offset(12)
                make.size.equalTo(CGSize(width: 150, height: 150))
                make.centerX.equalTo(self.container)
            } else {
                make.height.equalTo(height)
                make.width.equalTo(self.container.snp.width)
                make.top.equalTo(self.container).offset(0)
                make.leading.equalTo(self.container)
            }
        }

        progress.snp.remakeConstraints { make in
            make.edges.equalTo(container)
        }

        msgTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(messageData?.msgStatusSize.height ?? 0)
            make.bottom.equalTo(container).offset(-TUISwift.kScale390(9))
            make.trailing.equalTo(container).offset(-TUISwift.kScale390(8))
        }

        msgStatusView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(messageData?.msgStatusSize.height ?? 0)
            make.bottom.equalTo(msgTimeLabel)
            make.trailing.equalTo(msgTimeLabel.snp.leading)
        }

        selectedView.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override open func highlightWhenMatchKeyword(_ keyword: String?) {
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
        return 139.0
    }

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let imageCellData = data as? TUIImageMessageCellData else {
            assertionFailure("data must be kind of TUIImageMessageCellData")
            return CGSize.zero
        }

        if let hasRishContent = imageCellData.innerMessage?.hasRiskContent, hasRishContent {
            return CGSizeMake(150, 150)
        }

        var size = CGSize.zero
        if let path = imageCellData.path {
            var isDir = ObjCBool(false)
            if !path.isEmpty && FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue {
                size = UIImage(contentsOfFile: path)?.size ?? CGSize.zero
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
            for item in imageCellData.items {
                if item.type == .large {
                    size = item.size
                }
            }
        }

        if size == .zero {
            for item in imageCellData.items {
                if item.type == .thumb {
                    size = item.size
                }
            }
        }

        if size == .zero {
            return size
        }

        let widthMax = TUISwift.kScale390(250)
        let heightMax = TUISwift.kScale390(250)
        if size.height > size.width {
            size.width = size.width / size.height * heightMax
            size.height = heightMax
        } else {
            size.height = size.height / size.width * widthMax
            size.width = widthMax
        }

        return size
    }
}
