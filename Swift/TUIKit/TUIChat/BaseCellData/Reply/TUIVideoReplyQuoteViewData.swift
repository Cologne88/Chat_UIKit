import TIMCommon
import UIKit

class TUIVideoReplyQuoteViewData: TUIImageReplyQuoteViewData {
    override class func getReplyQuoteViewData(originCellData: TUIMessageCellData?) -> TUIReplyQuoteViewData? {
        guard let originCellData = originCellData as? TUIVideoMessageCellData else {
            return nil
        }

        let myData = TUIVideoReplyQuoteViewData()
        let snapSize = CGSizeMake(
            CGFloat(originCellData.innerMessage.videoElem?.snapshotWidth ?? 0),
            CGFloat(originCellData.innerMessage.videoElem?.snapshotHeight ?? 0)
        )
        myData.imageSize = displaySizeWithOriginSize(originSize: snapSize)
        myData.originCellData = originCellData
        return myData
    }

    override func downloadImage() {
        super.downloadImage()

        if let videoData = originCellData as? TUIVideoMessageCellData {
            videoData.downloadThumb { [weak self] in
                self?.image = videoData.thumbImage
                self?.onFinish?()
            }
        }
    }
}
