import TIMCommon
import UIKit

public class TUICustomActionSheetItem: NSObject {
    public var priority: Int = 0
    public var title: String
    public var leftMark: UIImage
    public var actionStyle: UIAlertAction.Style
    public var actionHandler: ((UIAlertAction) -> Void)?
    
    public init(title: String, leftMark: UIImage, actionHandler: ((UIAlertAction) -> Void)?) {
        self.title = title
        self.leftMark = leftMark
        self.actionStyle = .default
        self.actionHandler = actionHandler
    }
}

extension UIAlertController {
    func configItems(_ items: [TUICustomActionSheetItem]) {
        let padding: CGFloat = 10
        let itemHeight: CGFloat = 57
        let lineHeight: CGFloat = 0.5
        let alertVCWidth = view.frame.size.width - 2 * padding
        
        for (index, item) in items.enumerated() {
            let itemView = UIView()
            itemView.frame = CGRect(x: padding, y: (itemHeight + lineHeight) * CGFloat(index), width: alertVCWidth - 2 * padding, height: itemHeight)
            itemView.isUserInteractionEnabled = false
            view.addSubview(itemView)
            
            let icon = UIImageView()
            itemView.addSubview(icon)
            icon.contentMode = .scaleAspectFit
            icon.frame = CGRect(x: TUISwift.kScale390(20), y: itemHeight * 0.5 - TUISwift.kScale390(30) * 0.5, width: TUISwift.kScale390(30), height: TUISwift.kScale390(30))
            icon.image = item.leftMark
            
            let label = UILabel()
            label.frame = CGRect(x: icon.frame.origin.x + icon.frame.size.width + padding + TUISwift.kScale390(15), y: 0, width: alertVCWidth * 0.5, height: itemHeight)
            label.text = item.title
            label.font = UIFont.systemFont(ofSize: 17)
            label.textAlignment = TUISwift.isRTL() ? .right : .left
            label.textColor = .systemBlue
            label.isUserInteractionEnabled = false
            itemView.addSubview(label)
            
            if TUISwift.isRTL() {
                icon.resetFrameToFitRTL()
                label.resetFrameToFitRTL()
            }
        }
        
        for item in items {
            let action = UIAlertAction(title: "", style: item.actionStyle, handler: item.actionHandler)
            addAction(action)
        }
    }
}
