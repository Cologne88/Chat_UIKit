import Foundation

public protocol TIMInitializable: AnyObject {
    init()
}

class AnyService {
    private let _init: () -> Any

    init<T: TIMInitializable>(_ type: T.Type) {
        _init = { type.init() }
    }

    func createInstance() -> Any {
        return _init()
    }
}

public class TIMCommonMediator {
    public static let shared = TIMCommonMediator()
    private var map: [String: AnyService] = [:]

    private init() {}

    public func registerService<P>(_ serviceProtocol: P.Type, class cls: TIMInitializable.Type) {
        let key = String(describing: serviceProtocol)
        map[key] = AnyService(cls)
    }

    public func getObject<P>(for serviceProtocol: P.Type) -> P? {
        let key = String(describing: serviceProtocol)
        guard let service = map[key] else { return nil }
        return service.createInstance() as? P
    }
}
