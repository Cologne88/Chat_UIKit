import TIMCommon
import TUICore
import UIKit

class TUIMenuCell_Minimalist: UICollectionViewCell {
    var menu: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_controller_bg_color", defaultColor: "#EBF0F6")
        menu = UIImageView()
        menu.backgroundColor = .clear
        addSubview(menu)
    }
    
    private func defaultLayout() {
        // Default layout implementation
    }
    
    func setData(_ data: TUIMenuCellData?) {
        guard let data = data else { return }
        
        menu.image = TUIImageCache.sharedInstance().getFaceFromCache(data.path ?? "")
        if data.isSelected {
            backgroundColor = TUISwift.tuiChatDynamicColor("chat_face_menu_select_color", defaultColor: "#FFFFFF")
        } else {
            backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")
        }
        
        let size = frame.size
        let menuCellMargin = TUISwift.tMenuCell_Margin()
        menu.frame = CGRect(x: menuCellMargin, y: menuCellMargin, width: size.width - 2 * menuCellMargin, height: size.height - 2 * menuCellMargin)
        menu.contentMode = .scaleAspectFit
    }
}
