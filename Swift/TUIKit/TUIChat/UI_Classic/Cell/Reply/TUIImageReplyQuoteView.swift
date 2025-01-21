import UIKit

class TUIImageReplyQuoteView: TUIReplyQuoteView {
    var imageView: UIImageView
    
    override init(frame: CGRect) {
        imageView = UIImageView()
        super.init(frame: frame)
        
        imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        addSubview(imageView)
    }
    
    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)
        
        guard let myData = data as? TUIImageReplyQuoteViewData else {
            return
        }
        imageView.image = myData.image
        if myData.image == nil && myData.imageStatus != .downloading {
            myData.downloadImage()
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
        guard let myData = data as? TUIImageReplyQuoteViewData else {
            return
        }
        
        imageView.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.size.equalTo(myData.imageSize)
        }
    }
    
    override func reset() {
        super.reset()
        imageView.image = nil
        imageView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.origin.y, width: 60, height: 60)
    }
}
