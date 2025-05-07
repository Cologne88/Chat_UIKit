import Foundation
import UIKit
import CommonCrypto

public func IS_NOT_EMPTY_NSSTRING(_ x: Any?) -> Bool {
    if let str = x as? String {
        return str != ""
    }
    return false
}

@objcMembers
public class TUIUtil: NSObject {
    
    private static let tui_letters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    public class func dictionary2JsonData(_ dict: [AnyHashable: Any]?) -> Data? {
        if let dict = dict, JSONSerialization.isValidJSONObject(dict) {
            do {
                let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                return data
            } catch {
                print("[\(self)] Post Json Error")
            }
        } else {
            print("[\(self)] Post Json is not valid")
        }
        return nil
    }
    
    public class func dictionary2JsonStr(_ dict: [AnyHashable: Any]?) -> String? {
        if let data = dictionary2JsonData(dict) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public class func jsonSring2Dictionary(_ jsonString: String?) -> [AnyHashable: Any]? {
        guard let jsonString = jsonString else {
            return nil
        }
        if let data = jsonString.data(using: .utf8) {
            do {
                if let dic = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [AnyHashable: Any] {
                    return dic
                } else {
                    print("Json parse failed: \(jsonString)")
                    return nil
                }
            } catch {
                print("Json parse failed: \(jsonString)")
                return nil
            }
        }
        return nil
    }
    
    public class func jsonData2Dictionary(_ jsonData: Data?) -> [AnyHashable: Any]? {
        guard let jsonData = jsonData else {
            return nil
        }
        do {
            if let dic = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [AnyHashable: Any] {
                return dic
            } else {
                print("Json parse failed")
                return nil
            }
        } catch {
            print("Json parse failed")
            return nil
        }
    }
    
    public class func getFileCachePath(_ fileName: String?) -> String? {
        guard let fileName = fileName else {
            return nil
        }
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if let cacheDirectory = paths.first {
            let fileFullPath = (cacheDirectory as NSString).appendingPathComponent(fileName)
            return fileFullPath
        }
        return nil
    }
    
    public class func getContentLength(_ content: String?) -> UInt {
        guard let content = content else { return 0 }
        var length: UInt = 0
        for ch in content {
            if let scalar = ch.unicodeScalars.first {
                if scalar.value > 0x4e00 && scalar.value < 0x9fff {
                    length += 2
                } else {
                    length += 1
                }
            } else {
                length += 1
            }
        }
        return length
    }
    
    public class func md5Hash(_ data: Data?) -> String? {
        guard let data = data else { return nil }
        var result = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &result)
        }
        let md5String = result.map { String(format: "%02x", $0) }.joined()
        return md5String
    }
    
    public class func transImageURL2HttpsURL(_ httpURL: String?) -> String? {
        guard let httpURL = httpURL, !httpURL.isEmpty else {
            return nil
        }
        guard URL(string: httpURL) != nil else {
            return nil
        }
        var httpsURL = httpURL
        if httpURL.hasPrefix("http:") {
            httpsURL = httpURL.replacingOccurrences(of: "http:", with: "https:")
        } else {
            httpsURL = "https:" + httpURL
        }
        return httpsURL
    }
    
    public class func randomStringWithLength(_ len: Int) -> String {
        var randomString = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(tui_letters.count)))
            let charIndex = tui_letters.index(tui_letters.startIndex, offsetBy: index)
            randomString.append(tui_letters[charIndex])
        }
        return randomString
    }
    
    public class func openLinkWithURL(_ url: URL?) {
        guard let url = url else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Opened url")
                }
            }
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

public func isFirstLaunch() -> Bool {
    struct Static {
        static var first: Int = -1
    }
    if Static.first != -1 {
        return (Static.first == 0)
    }
    if let value = UserDefaults.standard.object(forKey: "kFirstLaunch") as? String, let intValue = Int(value) {
        Static.first = intValue
    } else {
        Static.first = 0
    }
    UserDefaults.standard.set("1", forKey: "kFirstLaunch")
    DispatchQueue.global(qos: .default).async {
        UserDefaults.standard.synchronize()
    }
    return (Static.first == 0)
}
