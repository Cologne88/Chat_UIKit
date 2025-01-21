import SDWebImage
import TIMCommon
import TUICore
import UIKit

class TUIMemberPanelCell: UICollectionViewCell {
    private var imageView: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = TUISwift.timCommonDynamicColor("group_controller_bg_color", defaultColor: "#F2F3F5")
        imageView = UIImageView(frame: bounds)
        imageView!.backgroundColor = .clear
        imageView!.contentMode = .scaleToFill
        addSubview(imageView!)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fillWithData(_ model: TUIUserModel?) {
        guard let model = model else { return }
        if let imageView = imageView {
            imageView.sd_setImage(with: URL(string: model.avatar), placeholderImage: UIImage(named: TUISwift.timCommonImagePath("default_c2c_head")), options: .highPriority)
        }
    }
}
