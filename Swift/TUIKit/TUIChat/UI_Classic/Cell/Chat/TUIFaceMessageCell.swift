import TIMCommon
import UIKit

class TUIFaceMessageCell: TUIBubbleMessageCell {
    var face: UIImageView!
    var faceData: TUIFaceMessageCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        face = UIImageView()
        face.contentMode = .scaleAspectFit
        container.addSubview(face)
        face.mm__fill()
        face.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        face.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        var topMargin: CGFloat = 0
        var height = container.frame.height

        if (messageData?.messageContainerAppendSize.height ?? 0) > 0 {
            topMargin = 10
            let tagViewTopPadding: CGFloat = 6
            height = container.frame.height - topMargin - (messageData?.messageContainerAppendSize.height ?? 0) - tagViewTopPadding
            bubbleView.isHidden = false
        } else {
            bubbleView.isHidden = true
        }

        face.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.centerX.equalTo(container)
            make.top.equalTo(topMargin)
            make.width.equalTo(container)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func fill(with data: TUICommonCellData) {
        super.fill(with: data)
        guard let data = data as? TUIFaceMessageCellData else {
            assertionFailure("data must be kind of TUIFaceMessageCellData")
            return
        }
        faceData = data
        if let path = data.path {
            var image: UIImage? = TUIImageCache.sharedInstance().getFaceFromCache(path)
            if image == nil {
                image = UIImage.safeImage(TUISwift.tuiChatFaceImagePath("ic_unknown_image"))
            }
            face.image = image
        }

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    // MARK: - TUIMessageCellProtocol

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let faceCellData = data as? TUIFaceMessageCellData else {
            return CGSize.zero
        }

        var image: UIImage? = TUIImageCache.sharedInstance().getFaceFromCache(faceCellData.path ?? "")
        if image == nil {
            image = UIImage(contentsOfFile: TUISwift.tuiChatFaceImagePath("ic_unknown_image"))
        }

        guard let image = image else { return CGSize.zero }
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        if imageHeight > TUISwift.tFaceMessageCell_Image_Height_Max() {
            imageHeight = TUISwift.tFaceMessageCell_Image_Height_Max()
            imageWidth = image.size.width / image.size.height * imageHeight
        }
        if imageWidth > TUISwift.tFaceMessageCell_Image_Width_Max() {
            imageWidth = TUISwift.tFaceMessageCell_Image_Width_Max()
            imageHeight = image.size.height / image.size.width * imageWidth
        }
        return CGSize(width: imageWidth, height: imageHeight)
    }
}
