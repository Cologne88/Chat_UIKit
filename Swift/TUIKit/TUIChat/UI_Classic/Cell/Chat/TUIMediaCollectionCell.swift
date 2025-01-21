import Photos
import TIMCommon
import UIKit

@objc protocol TUIMediaCollectionCellDelegate: NSObjectProtocol {
    @objc optional func onCloseMedia(cell: TUIMediaCollectionCell)
}

class TUIMediaCollectionCell: UICollectionViewCell, V2TIMAdvancedMsgListener {
    var imageView: UIImageView!
    var downloadBtn: UIButton!
    
    weak var delegate: TUIMediaCollectionCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.registerTUIKitNotification()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fill(with data: TUIMessageCellData) {}
    
    // MARK: - V2TIMAdvancedMsgListener

    private func registerTUIKitNotification() {
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
    }
}
