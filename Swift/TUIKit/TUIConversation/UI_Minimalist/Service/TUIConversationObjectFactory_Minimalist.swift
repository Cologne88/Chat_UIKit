import Foundation
import TIMCommon
import TUICore

/**
 * TUIConversationService currently provides two services:
 * 1. Create a conversation list
 * 2. Create a conversation selector
 *
 * You can call the service through the [TUICore createObject:..] method. The different service parameters are as follows:
 * > Create a conversation list:
 * factoryName: TUICore_TUIConversationObjectFactory_Minimalist
 * key: TUICore_TUIConversationObjectFactory_GetConversationControllerMethod
 *
 * > Create conversation selector:
 * factoryName: TUICore_TUIConversationObjectFactory_Minimalist
 * key: TUICore_TUIConversationObjectFactory_ConversationSelectVC_Minimalist
 *
 */
public class TUIConversationObjectFactory_Minimalist: NSObject, TUIObjectProtocol {
    @objc public class func swiftLoad() {
        TUICore.registerObjectFactory(TUICore_TUIConversationObjectFactory_Minimalist, objectFactory: shared)
    }

    static let shared: TUIConversationObjectFactory_Minimalist = {
        let instance = TUIConversationObjectFactory_Minimalist()
        return instance
    }()

    override private init() {}

    public func onCreateObject(_ method: String, param: [AnyHashable: Any]?) -> Any? {
        if method == TUICore_TUIConversationObjectFactory_GetConversationControllerMethod {
            return createConversationController()
        } else if method == TUICore_TUIConversationObjectFactory_ConversationSelectVC_Minimalist {
            return createConversationSelectController()
        }
        return nil
    }

    func createConversationController() -> UIViewController {
        return TUIConversationListController_Minimalist()
    }

    func createConversationSelectController() -> UIViewController {
        return TUIConversationSelectController_Minimalist()
    }
}
