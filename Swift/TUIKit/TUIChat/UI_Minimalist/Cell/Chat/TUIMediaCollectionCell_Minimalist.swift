import Photos
import TIMCommon
import UIKit

@objc protocol TUIMediaCollectionCellDelegate_Minimalist: NSObjectProtocol {
    @objc optional func onCloseMedia(cell: TUIMediaCollectionCell_Minimalist)
}

class TUIMediaCollectionCell_Minimalist: UICollectionViewCell {
    var imageView: UIImageView!
    var downloadBtn: UIButton!
    
    weak var delegate: TUIMediaCollectionCellDelegate_Minimalist?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fill(with data: TUIMessageCellData) {}
}
