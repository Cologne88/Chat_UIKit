import Foundation
import TIMCommon
import TUICore

public class TUIConversationObjectFactory: NSObject, TUIObjectProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory("TUICore_TUIConversationObjectFactory", objectFactory: TUIConversationObjectFactory.sharedInstance)
    }
    
    static let sharedInstance: TUIConversationObjectFactory = {
        let instance = TUIConversationObjectFactory()
        TUICore.registerObjectFactory("TUICore_TUIConversationObjectFactory", objectFactory: instance)
        return instance
    }()
    
    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        if method == "TUICore_TUIConversationObjectFactory_GetConversationControllerMethod" {
            return createConversationController()
        } else if method == "TUICore_TUIConversationObjectFactory_ConversationSelectVC_Classic" {
            return createConversationSelectController()
        }
        return nil
    }
    
    func createConversationController() -> UIViewController {
        return TUIConversationListController()
    }
    
    func createConversationSelectController() -> UIViewController {
        return TUIConversationSelectController()
    }
}
