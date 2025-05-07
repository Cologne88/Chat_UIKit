import Foundation
import TIMCommon
import TUICore
import UIKit

public class TUISearchExtensionObserver_Minimalist: NSObject, TUIExtensionProtocol {
    static let sharedInstance = TUISearchExtensionObserver_Minimalist()

    @objc public class func swiftLoad() {
        TUICore.registerExtension("TUICore_TUIConversationExtension_ConversationListBanner_MinimalistExtensionID", object: sharedInstance)
    }

    // MARK: - TUIExtensionProtocol

    public func onRaiseExtension(_ extensionID: String, parentView: UIView, param: [AnyHashable: Any]?) -> Bool {
        guard extensionID == "TUICore_TUIConversationExtension_ConversationListBanner_MinimalistExtensionID",
              let param = param,
              let modalVC = param["TUICore_TUIConversationExtension_ConversationListBanner_ModalVC"] as? UIViewController,
              let sizeStr = param["TUICore_TUIConversationExtension_ConversationListBanner_BannerSize"] as? String
        else {
            return false
        }

        let size = NSCoder.cgSize(for: sizeStr)
        let searchBar = TUISearchBar_Minimalist()
        searchBar.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        searchBar.parentVC = modalVC
        searchBar.setEntrance(true)
        parentView.addSubview(searchBar)
        return true
    }
}
