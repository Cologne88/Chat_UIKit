import SDWebImage
import SnapKit
import TIMCommon
import TUICore
import UIKit

class TUIGroupMemberCell: UICollectionViewCell {
    let head: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 5
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let name: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.gray
        label.textAlignment = .center
        return label
    }()
    
    var data: TUIGroupMemberCellData? {
        didSet {
            guard let data = data else { return }
            
            if !data.avatarUrl.isEmpty {
                let image: UIImage? = data.avatarImage
                head.sd_setImage(with: URL(string: data.avatarUrl), placeholderImage: image ?? TUISwift.defaultAvatarImage())
            } else {
                if let avatarImage = data.avatarImage as UIImage? {
                    head.image = data.avatarImage
                } else {
                    head.image = TUISwift.defaultAvatarImage()
                }
            }
            
            name.text = data.name.isEmpty ? data.identifier : data.name
            
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(head)
        contentView.addSubview(name)
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let headSize = TUIGroupMemberCell.getSize()
        head.snp.remakeConstraints { make in
            make.leading.top.equalTo(contentView)
            make.width.height.equalTo(headSize.width)
        }
        name.snp.remakeConstraints { make in
            make.leading.equalTo(head)
            make.top.equalTo(head.snp.bottom).offset(CGFloat(TGroupMemberCell_Margin))
            make.width.equalTo(headSize.width)
            make.height.equalTo(CGFloat(TGroupMemberCell_Name_Height))
        }
        
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            head.layer.cornerRadius = head.frame.size.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            head.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
    }
    
    class func getSize() -> CGSize {
        var headSize = TUISwift.tGroupMemberCell_Head_Size()
        
        let headMargin = CGFloat(TGroupMembersCell_Margin * (TGroupMembersCell_Column_Count + 1))
        let headWidth = CGFloat(headSize.width) * CGFloat(TGroupMembersCell_Column_Count) + headMargin
        
        if headWidth > TUISwift.screen_Width() {
            let width = (CGFloat(TUISwift.screen_Width()) - headMargin) / CGFloat(TGroupMembersCell_Column_Count)
            headSize = CGSize(width: width, height: width)
        }
        
        let heightMargin = CGFloat(TGroupMemberCell_Name_Height + TGroupMemberCell_Margin)
        return CGSize(width: headSize.width, height: headSize.height + heightMargin)
    }
}
