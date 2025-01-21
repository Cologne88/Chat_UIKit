import Foundation
import TIMCommon
import TUICore

class TUICommonPendencyCellData_Minimalist: TUICommonCellData {
    let application: V2TIMFriendApplication
    let identifier: String
    let avatarUrl: URL?
    let title: String
    let addSource: String?
    let addWording: String?
    var isAccepted: Bool = false
    var isRejected: Bool = false
    var cbuttonSelector: Selector?
    var cRejectButtonSelector: Selector?
    var hideSource: Bool = false

    init(application: V2TIMFriendApplication) {
        self.application = application
        self.identifier = application.userID ?? ""
        self.title = application.nickName?.isEmpty == false ? application.nickName! : identifier
        if let addSource = application.addSource {
            self.addSource = String(format: TUISwift.timCommonLocalizableString("TUIKitAddFriendSourceFormat"), addSource.dropFirst("AddSource_Type_".count) as CVarArg)
        } else {
            self.addSource = nil
        }
        self.addWording = application.addWording
        self.avatarUrl = URL(string: application.faceUrl ?? "")
    }

    func agree() {
        agreeWithSuccess(success: nil, failure: nil)
    }

    func reject() {
        rejectWithSuccess(success: nil, failure: nil)
    }

    func agreeWithSuccess(success: (() -> Void)?, failure: ((Int, String) -> Void)?) {
        V2TIMManager.sharedInstance().accept(application, type: V2TIMFriendAcceptType.FRIEND_ACCEPT_AGREE_AND_ADD, succ: { _ in
            success?()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitFriendApplicationApproved"))
        }, fail: { code, msg in
            TUITool.makeToastError(Int(code), msg: msg)
            failure?(Int(code), msg ?? "")
        })
    }

    func rejectWithSuccess(success: (() -> Void)?, failure: ((Int, String) -> Void)?) {
        V2TIMManager.sharedInstance().refuse(application, succ: { _ in
            success?()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitFirendRequestRejected"))
        }, fail: { code, msg in
            failure?(Int(code), msg ?? "")
            TUITool.makeToastError(Int(code), msg: msg)
        })
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TUICommonPendencyCellData_Minimalist else { return false }
        return identifier == other.identifier
    }
}
