import Foundation
import ImSDK_Plus

class TUIAIDenoiseSignatureManager {
    private let kAPIKey = "getAIDenoiseSignature"
    private let kSignatureKey = "signature"
    private let kExpiredTimeKey = "expired_time"
    private var expiredTime: TimeInterval = 0

    public var signature: String?
    public static let sharedInstance = TUIAIDenoiseSignatureManager()
    
    public func updateSignature() {
        let currentTime = Date().timeIntervalSince1970
        if currentTime < expiredTime {
            return
        }
        
       V2TIMManager.sharedInstance().callExperimentalAPI(api: kAPIKey, param: nil, succ: { [weak self] result in
            guard let self = self else { return }
            guard let dict = result as? [String: Any] else {
                return
            }
            
            if let signature = dict[kSignatureKey] as? String {
                self.signature = signature
            }
            
            if let expiredTime = dict[kExpiredTimeKey] as? NSNumber {
                self.expiredTime = expiredTime.doubleValue
            }
        }, fail: { code, desc in
            print("getAIDenoiseSignature failed, code: \(code), desc: \(desc)")
        })
    }
    
    func getSignature() -> String? {
        updateSignature()
        return signature
    }
}
