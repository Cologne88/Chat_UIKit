import Foundation
import TUICore
import UIKit

public class TUISearchExtensionObserver: NSObject, TUIExtensionProtocol {
    static let sharedInstance = TUISearchExtensionObserver()
    
    @objc public class func swiftLoad() {
        TUICore.registerExtension("TUICore_TUIConversationExtension_ConversationListBanner_ClassicExtensionID", object: TUISearchExtensionObserver.sharedInstance)
    }
    
    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        if extensionID == "TUICore_TUIConversationExtension_ConversationListBanner_ClassicExtensionID" {
            guard let modalVC = param?["TUICore_TUIConversationExtension_ConversationListBanner_ModalVC"] as? UIViewController,
                  let sizeStr = param?["TUICore_TUIConversationExtension_ConversationListBanner_BannerSize"] as? String
            else {
                return false
            }
            
            let size = NSCoder.cgSize(for: sizeStr)
            let searchBar = TUISearchBar()
            searchBar.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            searchBar.parentVC = modalVC
            searchBar.setEntrance(true)
            parentView.addSubview(searchBar)
            return true
        }
        
        return false
    }
}
