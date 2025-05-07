import AVFoundation
import CoreLocation
import Foundation
import UIKit

public struct TUIChatAuthControlType: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let micro = TUIChatAuthControlType(rawValue: 1 << 0)
    static let camera = TUIChatAuthControlType(rawValue: 1 << 1)
    static let photo = TUIChatAuthControlType(rawValue: 1 << 2)
}

public class TUIUserAuthorizationCenter {
    public static var isEnableCameraAuthorization: Bool {
        if #available(iOS 7.0, *) {
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        } else {
            return true
        }
    }

    public static var isEnableMicroAuthorization: Bool {
        if #available(iOS 7.0, *) {
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        } else {
            return true
        }
    }

    public static func cameraStateActionWithPopCompletion(completion: (() -> Void)?) {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    completion?()
                }
            }
        } else {
            showAlert(type: .camera)
        }
    }

    public static func microStateActionWithPopCompletion(completion: (() -> Void)?) {
        #if !targetEnvironment(macCatalyst)
        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    completion?()
                }
            }
        } else {
            showAlert(type: .micro)
        }
        #endif
    }

    public static func openSettingPage() {
        if #available(iOS 8.0, *) {
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }

    public static func showAlert(type: TUIChatAuthControlType) {
        var title = ""
        var message = ""
        var laterMessage = ""
        var openSettingMessage = ""

        if type == TUIChatAuthControlType.micro {
            title = TUISwift.timCommonLocalizableString("TUIKitInputNoMicTitle")
            message = TUISwift.timCommonLocalizableString("TUIKitInputNoMicTips")
            laterMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoMicOperateLater")
            openSettingMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoMicOperateEnable")
        } else if type == TUIChatAuthControlType.camera {
            title = TUISwift.timCommonLocalizableString("TUIKitInputNoCameraTitle")
            message = TUISwift.timCommonLocalizableString("TUIKitInputNoCameraTips")
            laterMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoCameraOperateLater")
            openSettingMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoCameraOperateEnable")
        } else if type == TUIChatAuthControlType.photo {
            title = TUISwift.timCommonLocalizableString("TUIKitInputNoPhotoTitle")
            message = TUISwift.timCommonLocalizableString("TUIKitInputNoPhotoTips")
            laterMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoPhotoOperateLater")
            openSettingMessage = TUISwift.timCommonLocalizableString("TUIKitInputNoPhotoerateEnable")
        } else {
            return
        }

        if #available(iOS 8.0, *) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: laterMessage, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: openSettingMessage, style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            DispatchQueue.main.async {
                TUITool.applicationKeywindow()?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
