import TIMCommon
import UIKit

class TUIFaceMessageCell_Minimalist: TUIBubbleMessageCell_Minimalist {
    var face: UIImageView!
    var faceData: TUIFaceMessageCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        face = UIImageView()
        face.contentMode = .scaleAspectFit
        bubbleView.addSubview(face)
        face.mm_fill()
        face.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        face.backgroundColor = .clear
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        let topMargin: CGFloat = 5
        face.snp.remakeConstraints { make in
            make.height.equalTo(TUISwift.kScale390(88))
            make.centerX.equalTo(container)
            make.top.equalTo(topMargin)
            make.width.equalTo(TUISwift.kScale390(90))
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func fill(with data: TUIBubbleMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIFaceMessageCellData else {
            assertionFailure("data must be kind of TUIFaceMessageCellData")
            return
        }
        faceData = data
        if let path = data.path {
            var image: UIImage? = TUIImageCache.sharedInstance().getFaceFromCache(path)
            if image == nil {
                image = UIImage(named: TUISwift.tuiChatFaceImagePath("ic_unknown_image"))
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

        var image: UIImage? = TUIImageCache.sharedInstance().getFaceFromCache(faceCellData.path.safeValue)
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
        imageWidth += TUISwift.kScale390(30)
        imageHeight += TUISwift.kScale390(30)
        return CGSize(width: imageWidth, height: imageHeight)
    }
}
