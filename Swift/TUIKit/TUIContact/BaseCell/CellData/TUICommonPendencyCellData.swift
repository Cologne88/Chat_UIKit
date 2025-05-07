import TIMCommon

class TUICommonPendencyCellData: TUICommonCellData {
    var application: V2TIMFriendApplication
    var identifier: String = ""
    var avatarUrl: URL?
    var title: String = ""
    var addSource: String?
    var addWording: String?
    var isAccepted: Bool = false
    var isRejected: Bool = false
    var cbuttonSelector: Selector?
    var cRejectButtonSelector: Selector?
    var hideSource: Bool = false

    init(application: V2TIMFriendApplication) {
        self.application = application
        if let userID = application.userID {
            self.identifier = userID
        }
        if let nickName = application.nickName {
            self.title = nickName
        } else {
            if let userID = application.userID {
                self.title = userID
            }
        }
        if let addSource = application.addSource {
            let prefixLength = "AddSource_Type_".count
            if addSource.count > prefixLength {
                let trimmedSource = String(addSource.dropFirst(prefixLength))
                self.addSource = String(format: TUISwift.timCommonLocalizableString("TUIKitAddFriendSourceFormat"), trimmedSource)
            }
        }
        self.addWording = application.addWording
        self.avatarUrl = URL(string: application.faceUrl ?? "")
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TUICommonPendencyCellData else { return false }
        return identifier == object.identifier
    }

    func agree() {
        agreeWithSuccess(success: nil, failure: nil)
    }

    func reject() {
        rejectWithSuccess(success: nil, failure: nil)
    }

    func agreeWithSuccess(success: (() -> Void)?, failure: ((Int, String) -> Void)?) {
        V2TIMManager.sharedInstance().acceptFriendApplication(application: application, acceptType: .FRIEND_ACCEPT_AGREE_AND_ADD) { _ in
            success?()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitFriendApplicationApproved"))
        } fail: { code, desc in
            TUITool.makeToastError(Int(code), msg: desc)
            failure?(Int(code), desc ?? "")
        }
    }

    func rejectWithSuccess(success: (() -> Void)?, failure: ((Int, String) -> Void)?) {
        V2TIMManager.sharedInstance().refuseFriendApplication(application: application) { _ in
            success?()
            TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitFirendRequestRejected"))
        } fail: { code, desc in
            failure?(Int(code), desc ?? "")
            TUITool.makeToastError(Int(code), msg: desc ?? "")
        }
    }
}
