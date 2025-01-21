//  TCLoginModel.swift
//  TUIKitDemo

import Foundation
import TUICore

let kKeySavedLoginInfoAppID = "Key_Login_Info_AppID"
let kKeySavedLoginInfoUserID = "Key_Login_UserID"
let kKeySavedLoginInfoUserSig = "Key_Login_Info_UserSig"
let kKeySavedLoginInfoPhone = "Key_Login_Info_Phone"
let kKeySavedLoginInfoToken = "Key_Login_Info_InfoToken"
let kKeySavedLoginInfoIsDirectlyLogin = "Key_Login_Info_IsDirectlyLogin"
let kKeySavedLoginInfoApaasUser = "Key_Login_Info_ApaasUser"

let kKeyLoginInfoService = "service"
let kKeyLoginInfoCaptchaAppID = "captcha_web_appid"
let kKeyLoginInfoSessionID = "sessionId"
let kKeyLoginInfoToken = "token"

let kKeyLoginInfoPhone = "phone"
let kKeyLoginInfoApaasUserID = "apaasUserId"
let kKeyLoginInfoApaasAppID = "apaasAppId"

// Global constants
let kKeyLoginInfoApaasTicket = "ticket"
let kKeyLoginInfoApaasRandStr = "randstr"
let kKeyLoginInfoUserSig = "sdkUserSig"
let kKeyLoginInfoUserID = "userId"

typealias TCSuccess = (_ data: [String: Any]) -> Void
typealias TCFail = (_ errorCode: Int, _ errorMsg: String) -> Void

class TCLoginModel {
    
    static let sharedInstance = TCLoginModel()
    
    private init() {}
    
    private var serviceUrl: String?
    private var apaasUserID: String?
    
    private(set) var captchaAppID: String?
    private(set) var token: String?
    private(set) var userID: String?
    private(set) var userSig: String?
    private(set) var SDKAppID: UInt = 0
    private(set) var sessionID: String?
    
    var ticket: String?
    var randStr: String?
    var phone: String?
    var smsCode: String?
    var isDirectlyLoginSDK: Bool = false {
        didSet {
            UserDefaults.standard.set(isDirectlyLoginSDK, forKey: kKeySavedLoginInfoIsDirectlyLogin)
        }
    }
    
    // MARK: - Public Methods
    
    func getAccessAddress(succeed: TCSuccess?, fail: TCFail?) {
        guard let url = constructURL(host: curDispatchServiceHost(), env:self.curEnv(), path: kGlobalDispatchServicePath, query: nil) else {
            fail?(-2, "construct url failed, check the input params")
            return
        }

        requestURL(url: url) { errorCode, errorMsg, data in
            DispatchQueue.main.async {
                if errorCode == 0, let data = data {
                    self.serviceUrl = data[kKeyLoginInfoService] as? String
                    self.captchaAppID = "\(data[kKeyLoginInfoCaptchaAppID] ?? "")"
                    succeed?(data)
                } else {
                    fail?(errorCode, errorMsg)
                }
            }
        }
    }
    
    func getSmsVerificationCode(succeed: TCSuccess?, fail: TCFail?) {
        let block = {
            guard let url = self.constructURL(host: self.serviceHost(), env:self.curEnv(), path: kGetSmsVerfifyCodePath, query: self.smsVerficationCodeQuery()) else {
                fail?(-2, "construct url failed, check the input params")
                return
            }
            
            self.requestURL(url: url) { errorCode, errorMsg, data in
                DispatchQueue.main.async {
                    if let sessionID = data?[kKeyLoginInfoSessionID] as? String {
                        self.sessionID = sessionID
                        succeed?([kKeyLoginInfoSessionID: sessionID])
                    } else {
                        print("getSmsVerificationCodeWithSucceedBlock failed, error: \(errorCode), errorMsg: \(errorMsg)")
                        fail?(errorCode, errorMsg)
                    }
                }
            }
        }
        
        if serviceHost() == nil {
            getAccessAddress(succeed: { _ in block() }, fail: fail)
            return
        }
        block()
    }
    
    func loginByPhone(succeed: TCSuccess?, fail: TCFail?) {
        guard let url = constructURL(host: serviceHost(), env:self.curEnv(), path: kLoginByPhonePath, query: loginByPhoneQuery()) else {
            fail?(-2, "construct url failed, check the input params")
            return
        }
        
        requestURL(url: url) { errorCode, errorMsg, data in
            DispatchQueue.main.async {
                if errorCode == 0, let data = data {
                    self.saveLoginedInfo(data: data)
                    succeed?(data)
                } else {
                    fail?(errorCode, errorMsg)
                }
            }
        }
    }
    
    func loginByToken(succeed: TCSuccess?, fail: TCFail?) {
        let block = {
            guard let url = self.constructURL(host: self.serviceHost(), env:self.curEnv(), path: kLoginByTokenPath, query: self.loginByTokenQuery()) else {
                fail?(-2, "construct url failed, check the input params")
                return
            }
            
            self.requestURL(url: url) { errorCode, errorMsg, data in
                DispatchQueue.main.async {
                    if errorCode == 0, let data = data {
                        self.saveLoginedInfo(data: data)
                        self.token = data[kKeyLoginInfoToken] as? String
                        succeed?(data)
                    } else {
                        fail?(errorCode, errorMsg)
                    }
                }
            }
        }
        
        if serviceHost() == nil {
            getAccessAddress(succeed: { _ in block() }, fail: fail)
            return
        }
        block()
    }
    
    func autoLogin(succeed: TCSuccess?, fail: TCFail?) {
        loadIsDirectlyLogin()
        loadLastLoginInfo()
        
        if isDirectlyLoginSDK {
            let data: [String: Any] = [
                kKeyLoginInfoUserSig: userSig ?? "",
                kKeyLoginInfoUserID: userID ?? ""
            ]
            succeed?(data)
            return
        }
        
        loginByToken(succeed: succeed, fail: fail)
    }
    
    func logout(succeed: TCSuccess?, fail: TCFail?) {
        if isDirectlyLoginSDK {
            clearDirectlyLoginedInfo()
            succeed?([:])
            return
        }
        
        guard let url = constructURL(host: serviceHost(), env:self.curEnv(), path: kLogoutPath, query: logoutQuery()) else {
            fail?(-2, "construct url failed, check the input params")
            return
        }
        
        requestURL(url: url) { errorCode, errorMsg, data in
            DispatchQueue.main.async {
                if errorCode == 0 {
                    self.clearLoginedInfo()
                    succeed?(data!)
                } else {
                    fail?(errorCode, errorMsg)
                }
            }
        }
    }
    
    func deleteUser(succeed: TCSuccess?, fail: TCFail?) {
        if isDirectlyLoginSDK {
            clearDirectlyLoginedInfo()
            succeed?([:])
            return
        }
        
        guard let url = constructURL(host: serviceHost(), env:self.curEnv(), path: kDeleteUserPath, query: deleteUserQuery()) else {
            fail?(-2, "construct url failed, check the input params")
            return
        }
        
        requestURL(url: url) { errorCode, errorMsg, data in
            DispatchQueue.main.async {
                if errorCode == 0 {
                    self.clearLoginedInfo()
                    succeed?(data!)
                } else {
                    fail?(errorCode, errorMsg)
                }
            }
        }
    }
    
    func clearLoginedInfo() {
        userID = nil
        isDirectlyLoginSDK = false
        token = nil
        sessionID = nil
        ticket = nil
        randStr = nil
        phone = nil
        smsCode = nil
        userSig = nil
        SDKAppID = 0
        apaasUserID = nil
        clearSavedLoginedInfo()
    }
    
    func saveLoginedInfo(userID: String, userSig: String) {
        guard !userID.isEmpty, !userSig.isEmpty else { return }
        saveLoginedInfo(data: [
            kKeyLoginInfoUserID: userID,
            kKeyLoginInfoUserSig: userSig
        ])
    }
    
    // MARK: - Private Methods
    
    private func clearDirectlyLoginedInfo() {
        userID = nil
        userSig = nil
        isDirectlyLoginSDK = false
        apaasUserID = nil
        clearSavedLoginedInfo()
    }
    
    private func constructURL(host: String?, env:String, path: String, query: [String: String]?) -> URL? {
        guard let host = host, !host.isEmpty, !path.isEmpty else { return nil }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = env + path
        
        if let query = query {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components.url
    }
    
    private func requestURL(url: URL, completion: @escaping (Int, String, [String: Any]?) -> Void) {
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let errorCode = result["errorCode"] as? Int ?? -1
                let data = result["data"] as? [String: Any]
                
                var message = TCLoginErrorCode.messageOfCode(code: errorCode)
                if message.isEmpty, let dict = result["notice"] as? [String: String] {
                    let lang = TUIGlobalization.getPreferredLanguage()
                    message = lang == "zh-Hans" || lang == "zh-Hant" ? dict["zh"] ?? "" : dict["en"] ?? ""
                }
                if message.isEmpty {
                    message = result["errorMessage"] as? String ?? ""
                }
                
                completion(errorCode, message, data)
                print("\n---------------response---------------\nurl: \(url)\ncode: \(errorCode)\nmsg: \(message)\ndata: \(String(describing: data))")
            } else {
                let errorInfo = error as? NSError
                let errorCode = errorInfo?.code ?? -1
                let errorMsg = errorInfo?.localizedDescription ?? "Unknown error"
                completion(errorCode, errorMsg, nil)
                print("\n---------------response---------------\nurl: \(url)\ncode: \(errorCode)\nmsg: \(errorMsg)")
            }
        }
        task.resume()
    }
    
    // MARK: -- Persistence
    
    private func saveLoginedInfo(data: [String: Any]) {
        if let appID = data["sdkAppId"] as? NSNumber {
            SDKAppID = appID.uintValue
            UserDefaults.standard.set(appID, forKey: kKeySavedLoginInfoAppID)
        }
        if let userID = data[kKeyLoginInfoUserID] as? String {
            self.userID = userID
            UserDefaults.standard.set(userID, forKey: kKeySavedLoginInfoUserID)
        }
        if let userSig = data[kKeyLoginInfoUserSig] as? String {
            self.userSig = userSig
            UserDefaults.standard.set(userSig, forKey: kKeySavedLoginInfoUserSig)
        }
        if let phone = data[kKeyLoginInfoPhone] as? String {
            self.phone = phone
            UserDefaults.standard.set(phone, forKey: kKeySavedLoginInfoPhone)
        }
        if let token = data[kKeyLoginInfoToken] as? String {
            self.token = token
            UserDefaults.standard.set(token, forKey: kKeySavedLoginInfoToken)
        }
        if let apaasUserID = data[kKeyLoginInfoApaasUserID] as? String {
            self.apaasUserID = apaasUserID
            UserDefaults.standard.set(apaasUserID, forKey: kKeySavedLoginInfoApaasUser)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    private func clearSavedLoginedInfo() {
        UserDefaults.standard.removeObject(forKey: kKeySavedLoginInfoUserSig)
        UserDefaults.standard.removeObject(forKey: kKeySavedLoginInfoToken)
        UserDefaults.standard.removeObject(forKey: kKeySavedLoginInfoPhone)
        UserDefaults.standard.removeObject(forKey: kKeySavedLoginInfoUserID)
        UserDefaults.standard.removeObject(forKey: kKeySavedLoginInfoApaasUser)
        
        UserDefaults.standard.synchronize()
    }
    
    public func loadLastLoginInfo() {
        SDKAppID = UserDefaults.standard.object(forKey: kKeySavedLoginInfoAppID) as? UInt ?? 0
        userID = UserDefaults.standard.object(forKey: kKeySavedLoginInfoUserID) as? String
        token = UserDefaults.standard.object(forKey: kKeySavedLoginInfoToken) as? String
        userSig = UserDefaults.standard.object(forKey: kKeySavedLoginInfoUserSig) as? String
        apaasUserID = UserDefaults.standard.object(forKey: kKeySavedLoginInfoApaasUser) as? String
    }
    
    public func loadIsDirectlyLogin() {
        isDirectlyLoginSDK = UserDefaults.standard.bool(forKey: kKeySavedLoginInfoIsDirectlyLogin)
    }
    
    // MARK: - Getter
    
    private func smsVerficationCodeQuery() -> [String: String] {
        return [
            "appId": captchaAppID ?? "",
            kKeyLoginInfoApaasTicket: ticket ?? "",
            kKeyLoginInfoApaasRandStr: randStr ?? "",
            kKeyLoginInfoPhone: phone ?? "",
            kKeyLoginInfoApaasAppID: curApaasAppID()
        ]
    }
    
    private func loginByPhoneQuery() -> [String: String] {
        return [
            kKeyLoginInfoSessionID: sessionID ?? "",
            kKeyLoginInfoPhone: phone ?? "",
            "code": smsCode ?? "",
            kKeyLoginInfoApaasAppID: curApaasAppID()
        ]
    }
    
    private func loginByTokenQuery() -> [String: String] {
        return [
            kKeyLoginInfoUserID: userID ?? "",
            kKeyLoginInfoToken: token ?? "",
            kKeyLoginInfoApaasAppID: curApaasAppID(),
            kKeyLoginInfoApaasUserID: apaasUserID ?? ""
        ]
    }
    
    private func logoutQuery() -> [String: String] {
        return loginByTokenQuery()
    }
    
    private func deleteUserQuery() -> [String: String] {
        return loginByTokenQuery()
    }
    
    private func curEnv() -> String {
        return kEnvProd
    }
    
    private func curApaasAppID() -> String {
        #if BUILDINTERNATIONAL
        return kApaasAppID_international
        #else
        return kApaasAppID
        #endif
    }
    
    private func curDispatchServiceHost() -> String {
        #if BUILDINTERNATIONAL
        return kGlobalDispatchServiceHost_international
        #else
        return kGlobalDispatchServiceHost
        #endif
    }
    
    private func serviceHost() -> String? {
        guard let serviceUrl = serviceUrl else { return nil }
        let url = URL(string: serviceUrl)
        return url?.host
    }
}

class TCLoginErrorCode {
    
    static func messageOfCode(code: Int) -> String {
        return errorCodeDict()[code] ?? ""
    }
    
    private static func errorCodeDict() -> [Int: String] {
        return [
            98: NSLocalizedString("TipsSystemVerifyError", comment: ""),
            99: NSLocalizedString("TipsSystemError", comment: ""),
            100: NSLocalizedString("TipsServiceUnavailable", comment: ""),
            101: NSLocalizedString("TipsServiceResponseInvalid", comment: ""),
            102: NSLocalizedString("TipsServiceSmsFailed", comment: ""),
            103: NSLocalizedString("TipsServiceDBFailed", comment: ""),
            104: NSLocalizedString("TipsServiceUnknownError", comment: ""),
            200: NSLocalizedString("TipsUserCodeInvalid", comment: ""),
            201: NSLocalizedString("TipsUserCodeExpired", comment: ""),
            202: NSLocalizedString("TipsUserCodeConsumed", comment: ""),
            203: NSLocalizedString("TipsUserTokenExpired", comment: ""),
            204: NSLocalizedString("TipsUserTokenInvalid", comment: ""),
            205: NSLocalizedString("TipsUseInfoEmpty", comment: ""),
            206: NSLocalizedString("TipsUserNotExists", comment: ""),
            207: NSLocalizedString("TipsUserEmailInvalid", comment: ""),
            208: NSLocalizedString("TipsUserQueryParams", comment: ""),
            209: NSLocalizedString("TipsUserQueryLimit", comment: ""),
            210: NSLocalizedString("TipsUserOAuthParams", comment: "")
        ]
    }
}
