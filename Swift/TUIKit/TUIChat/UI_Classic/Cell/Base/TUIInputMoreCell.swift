import UIKit

class TUIInputMoreCell: UICollectionViewCell {
    var image: UIImageView!
    var title: UILabel!
    var data: TUIInputMoreCellData?
    var disableDefaultSelectAction: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        image = UIImageView()
        image.contentMode = .scaleAspectFit
        addSubview(image)
        
        title = UILabel()
        title.font = UIFont.systemFont(ofSize: 10)
        title.textColor = UIColor.gray
        title.textAlignment = .center
        addSubview(title)
    }
    
    func fill(with cellData: TUIInputMoreCellData?) {
        data = cellData
        isHidden = (data == nil)
        image.image = data?.image
        title.text = data?.title
        
        let menuSize = CGSize(width: 65, height: 65)
        image.frame = CGRect(x: 0, y: 0, width: menuSize.width, height: menuSize.height)
        title.frame = CGRect(x: 0, y: image.frame.origin.y + image.frame.size.height, width: image.frame.size.width + 10, height: 20)
        title.center = CGPoint(x: image.center.x, y: title.center.y)
    }
    
    static func getSize() -> CGSize {
        let menuSize = CGSize(width: 65, height: 65)
        return CGSize(width: menuSize.width, height: menuSize.height + 20)
    }
}

class IUChatView: UIView {
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        addSubview(view)
    }
}
