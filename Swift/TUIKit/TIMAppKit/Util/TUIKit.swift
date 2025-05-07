//
//  TUIKit.swift
//
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.
//

import ImSDK_Plus
import TIMCommon
import UIKit

@objc public enum TUIUserStatus: UInt {
    case forceOffline // TUser_Status_ForceOffline
    case reConnFailed // TUser_Status_ReConnFailed
    case sigExpired // TUser_Status_SigExpired
}

@objcMembers
public class TUIKit: NSObject {
    private var _sdkAppId: UInt32 = 0
    private var _userID: String?
    private var _userSig: String?
    private var _nickName: String?
    private var config: TUIConfig?
    
    public static let instance: TUIKit = .init()
    
    public class func sharedInstance() -> TUIKit {
        return instance
    }
    
    override private init() {
        super.init()
        config = TUIConfig.default()
    }
    
    /**
     *  Receiving an audio or video call invitation push
     */
    public func onReceiveGroupCallAPNs(_ signalingInfo: V2TIMSignalingInfo) {
        let param: [AnyHashable: Any] = [
            "TUICore_TUICallingService_ShowCallingViewMethod_SignalingInfo": signalingInfo
        ]
        TUICore.callService("TUICore_TUICallingService", method: "TUICore_TUICallingService_ReceivePushCallingMethod", param: param)
    }
    
    /**
     *  IMSDK sdkAppId
     */
    public var sdkAppId: UInt32 {
        return _sdkAppId
    }
    
    /**
     *  userID
     */
    public var userID: String? {
        return _userID
    }
    
    /**
     *  userSig
     */
    public var userSig: String? {
        return _userSig
    }
    
    /**
     * faceUrl
     */
    public var faceUrl: String? {
        return TUILogin.getFaceUrl()
    }
    
    /**
     * nickName
     */
    public var nickName: String? {
        return TUILogin.getNickName()
    }
    
    /**
     * Setup with appId.
     */
    public func setup(withAppId sdkAppId: UInt32) {
        _sdkAppId = sdkAppId
        
        setupConfig()
        TUILogin.initWithSdkAppID(Int32(sdkAppId))
    }
    
    /**
     * Setup config.
     */
    private func setupConfig() {
        config?.avatarType = .TAvatarTypeRadiusCorner
        config?.avatarCornerRadius = 5
    }
}
