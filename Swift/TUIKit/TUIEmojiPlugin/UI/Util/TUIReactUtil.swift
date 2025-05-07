//
//  TUIReactUtil.swift
//  Masonry
//
//  Created by cologne on 2023/12/26.
//

import Foundation
import ImSDK_Plus
import TIMCommon

public class TUIReactUtil: NSObject {
    public static let TUIReactCommercialAbility: Int64 = 1 << 48
    private static var gEnableReact: Bool = false
    private static let sharedInstanceVar: TUIReactUtil = .init()
    
    @objc public class func sharedInstance() -> TUIReactUtil {
        return sharedInstanceVar
    }
    
    override public init() {
        super.init()
    }
    
    @objc public class func reportTUIReactComponentUsage() {
        var param: [String: Any] = [:]
        param["UIComponentType"] = 18
        param["UIStyleType"] = 0
        
        if let dataParam = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted),
           let strParam = String(data: dataParam, encoding: .utf8)
        {
            V2TIMManager.sharedInstance().callExperimentalAPI(api: "reportTUIComponentUsage", param: strParam as NSObject, succ: { (_: Any?) in
                NSLog("success")
            }, fail: { _, _ in
                // do nothing
            })
        }
    }
    
    @objc public class func checkCommercialAbility() {
        TUITool.checkCommercialAbility(TUIReactCommercialAbility, succ: { (enabled: Bool) in
            self.gEnableReact = enabled
            if self.gEnableReact {
                self.reportTUIReactComponentUsage()
                let userDefaults = UserDefaults.standard
                userDefaults.set(true, forKey: "TUIReactionCommercialAbility")
                userDefaults.synchronize()
            }
        }, fail: { _, _ in
            self.gEnableReact = false
        })
    }
    
    @objc public class func isReactServiceSupported() -> Bool {
        return gEnableReact
    }
}
