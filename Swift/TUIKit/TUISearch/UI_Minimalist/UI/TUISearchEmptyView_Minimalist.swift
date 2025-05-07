import TIMCommon
import UIKit

class TUISearchEmptyView_Minimalist: UIView {
    private let midImage: UIImageView
    private let tipsLabel: UILabel
    
    init(image: UIImage, text: String) {
        self.midImage = UIImageView(image: image)
        self.tipsLabel = UILabel()
        super.init(frame: .zero)
        tipsLabel.text = text
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        tipsLabel.textColor = UIColor.tui_color(withHex: "#999999")
        tipsLabel.font = UIFont.systemFont(ofSize: 14.0)
        tipsLabel.textAlignment = .center
        
        addSubview(tipsLabel)
        addSubview(midImage)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        midImage.frame = CGRect(x: (bounds.size.width - TUISwift.kScale390(105)) * 0.5, y: 0, width: TUISwift.kScale390(105), height: TUISwift.kScale390(105))
        tipsLabel.sizeToFit()
        tipsLabel.frame = CGRect(x: (bounds.size.width - tipsLabel.frame.size.width) * 0.5,
                                 y: midImage.frame.origin.y + midImage.frame.size.height + TUISwift.kScale390(10),
                                 width: tipsLabel.frame.size.width,
                                 height: tipsLabel.frame.size.height)
    }
}
