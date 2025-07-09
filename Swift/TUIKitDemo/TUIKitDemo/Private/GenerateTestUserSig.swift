import CommonCrypto
import Foundation
import TIMCommon
import TUICore
import zlib

// SDKAppID and SecretKey definitions
let SDKAPPID = GenerateTestUserSig.currentSDKAppid()
let SECRETKEY = GenerateTestUserSig.currentSecretkey()

/**
 * Chat SDKAppID, which uniquely identifies a Chat account.
 * You can get your SDKAppID after creating an application on the [Chat console](https://console.trtc.io/).
 */
let public_SDKAPPID = <#your SDKAppID#>

/**
 * Chat SecretKey, which is coresponding to the SDKAppID above.
 * This method is for testing only. Please migrate the UserSig calculation code and key to your backend server to prevent key disclosure and traffic stealing before release your app.
 */
let public_SECRETKEY = "<#your SDKSecretKey#>"

/**
 *  Signature validity period, which should not be set too short
 *
 *  Time unit: second
 *  Default value: 604800 (7 days)
 */
let EXPIRETIME = 604800

class GenerateTestUserSig {
    static func currentSDKAppid() -> UInt {
        return UInt(public_SDKAPPID)
    }

    static func currentSecretkey() -> String {
        return public_SECRETKEY
    }

    class func genTestUserSig(identifier: String) -> String {
        let current = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970
        let TLSTime = CLong(floor(current))
        var obj: [String: Any] = [
            "TLS.ver": "2.0",
            "TLS.identifier": identifier,
            "TLS.sdkappid": currentSDKAppid(),
            "TLS.expire": EXPIRETIME,
            "TLS.time": TLSTime
        ]
        let keyOrder = [
            "TLS.identifier",
            "TLS.sdkappid",
            "TLS.time",
            "TLS.expire"
        ]
        var stringToSign = ""
        for key in keyOrder {
            if let value = obj[key] {
                stringToSign += "\(key):\(value)\n"
            }
        }
        print("string to sign: \(stringToSign)")
        let sig = hmac(stringToSign)
        obj["TLS.sig"] = sig!
        print("sig: \(String(describing: sig))")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: obj, options: .sortedKeys) else { return "" }

        let bytes = jsonData.withUnsafeBytes { result -> UnsafePointer<Bytef> in
            return result.bindMemory(to: Bytef.self).baseAddress!
        }
        let srcLen = uLongf(jsonData.count)
        let upperBound: uLong = compressBound(srcLen)
        let capacity = Int(upperBound)
        let dest = UnsafeMutablePointer<Bytef>.allocate(capacity: capacity)
        var destLen = upperBound
        let ret = compress2(dest, &destLen, bytes, srcLen, Z_BEST_SPEED)
        if ret != Z_OK {
            print("[Error] Compress Error \(ret), upper bound: \(upperBound)")
            dest.deallocate()
            return ""
        }
        let count = Int(destLen)
        let result = base64URL(data: Data(bytesNoCopy: dest, count: count, deallocator: .free))
        return result
    }

    class func hmac(_ plainText: String) -> String? {
        let cKey = currentSecretkey().cString(using: String.Encoding.ascii)
        let cData = plainText.cString(using: String.Encoding.ascii)

        let cKeyLen = currentSecretkey().lengthOfBytes(using: .ascii)
        let cDataLen = plainText.lengthOfBytes(using: .ascii)

        var cHMAC = [CUnsignedChar](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        let pointer = cHMAC.withUnsafeMutableBufferPointer { unsafeBufferPointer in
            unsafeBufferPointer
        }
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), cKey!, cKeyLen, cData, cDataLen, pointer.baseAddress)
        let data = Data(bytes: pointer.baseAddress!, count: cHMAC.count)
        return data.base64EncodedString(options: [])
    }

    class func base64URL(data: Data) -> String {
        let result = data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        var final = ""
        for char in result {
            switch char {
            case "+":
                final += "*"
            case "/":
                final += "-"
            case "=":
                final += "_"
            default:
                final += "\(char)"
            }
        }
        return final
    }
}
