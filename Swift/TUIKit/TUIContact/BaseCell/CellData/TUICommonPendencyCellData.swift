import TIMCommon

class TUICommonPendencyCellData: TUICommonCellData {
    var application: V2TIMFriendApplication
    var identifier: String
    var avatarUrl: URL?
    var title: String
    var addSource: String?
    var addWording: String?
    var isAccepted: Bool = false
    var isRejected: Bool = false
    var cbuttonSelector: Selector?
    var cRejectButtonSelector: Selector?
    var hideSource: Bool = false

    init(application: V2TIMFriendApplication) {
        self.application = application
        self.identifier = application.userID.safeValue
        self.title = application.nickName.isNilOrEmpty ? application.userID.safeValue : application.nickName.safeValue
        if let addSource = application.addSource {
            let prefixLength = "AddSource_Type_".count
            if addSource.count > prefixLength {
                let trimmedSource = String(addSource.dropFirst(prefixLength))
                self.addSource = String(format: TUISwift.timCommonLocalizableString("TUIKitAddFriendSourceFormat"), trimmedSource)
            }
        }
        self.addWording = application.addWording
        self.avatarUrl = URL(string: application.faceUrl.safeValue)
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
}
