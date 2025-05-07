import TIMCommon
import TUICore
import UIKit

class TUIFoldListViewController: UIViewController, TUINavigationControllerDelegate, TUIConversationListControllerListener {
    var dismissCallback: ((NSMutableAttributedString, [TUIConversationCellData], [String]) -> Void)?
    var titleView: TUINaviBarIndicatorView?
    var mainTitle: String?

    lazy var conv: TUIConversationListController = {
        var conv = TUIConversationListController()
        conv.isShowConversationGroup = false
        conv.isShowBanner = false
        conv.tipsMsgWhenNoConversation = TUISwift.timCommonLocalizableString("TUIKitContactNoGroupChats")
        conv.disableMoreActionExtension = true
        conv.dataProvider = TUIFoldConversationListDataProvider()
        conv.dataProvider!.delegate = conv
        conv.delegate = self
        return conv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(conv)
        view.addSubview(conv.view)

        setupNavigator()
    }

    func setTitle(_ title: String) {
        mainTitle = title
    }

    func setupNavigator() {
        guard let naviController = navigationController as? TUINavigationController else { return }
        naviController.uiNaviDelegate = self
        titleView = TUINaviBarIndicatorView()
        navigationItem.titleView = titleView
        titleView?.setTitle(TUISwift.timCommonLocalizableString("TUIKitConversationMarkFoldGroups"))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let naviController = navigationController as? TUINavigationController else { return }
        naviController.uiNaviDelegate = self
    }

    // MARK: - TUINavigationControllerDelegate

    func navigationControllerDidClickLeftButton(_ controller: TUINavigationController) {
        excuteDismissCallback()
    }

    func navigationControllerDidSideSlideReturn(_ controller: TUINavigationController, from fromViewController: UIViewController) {
        excuteDismissCallback()
    }

    func excuteDismissCallback() {
        guard let dismissCallback = dismissCallback else { return }
        var foldSubTitle = NSMutableAttributedString(string: "")
        guard let foldProvider = conv.dataProvider as? TUIFoldConversationListDataProvider else { return }
        let needRemoveFromCacheMapArray = foldProvider.needRemoveConversationList
        if var sortArray = conv.dataProvider?.conversationList as? [TUIConversationCellData] {
            sortDataList(&sortArray)
            if let lastItem = sortArray.first {
                foldSubTitle = lastItem.foldSubTitle ?? NSMutableAttributedString()
            }
            dismissCallback(foldSubTitle, sortArray, needRemoveFromCacheMapArray)
        } else {
            dismissCallback(foldSubTitle, [], needRemoveFromCacheMapArray)
        }
    }

    func sortDataList(_ dataList: inout [TUIConversationCellData]) {
        dataList.sort { $0.orderKey > $1.orderKey }
    }

    // MARK: TUIConversationListControllerListener

    func getConversationDisplayString(_ conversation: V2TIMConversation) -> String? {
        guard let msg = conversation.lastMessage, let customElem = msg.customElem, let data = customElem.data else { return nil }
        guard let param = TUITool.jsonData2Dictionary(data) as? [String: Any] else { return nil }
        guard let businessID = param["businessID"] as? String else { return nil }
        if businessID == "text_link" || (param["text"] as? String)?.count ?? 0 > 0 && (param["link"] as? String)?.count ?? 0 > 0 {
            guard let desc = param["text"] as? String else { return nil }
            if msg.status == V2TIMMessageStatus.MSG_STATUS_LOCAL_REVOKED {
                if msg.hasRiskContent {
                    return TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallRiskContent")
                } else if let info = msg.revokerInfo, let userName = info.nickName {
                    return String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
                } else if msg.isSelf {
                    return TUISwift.timCommonLocalizableString("TUIKitMessageTipsYouRecallMessage")
                } else if let _ = msg.userID {
                    return TUISwift.timCommonLocalizableString("TUIKitMessageTipsOthersRecallMessage")
                } else if let _ = msg.groupID {
                    let userName = msg.nameCard ?? msg.nickName ?? msg.sender ?? ""
                    return String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), userName)
                }
            }
            return desc
        }
        return nil
    }

    func conversationListController(_ conversationController: UIViewController, didSelectConversation conversation: TUIConversationCellData) -> Bool {
        let param: [String: Any] = [
            "TUICore_TUIChatObjectFactory_ChatViewController_ConversationID": conversation.conversationID ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_UserID": conversation.userID ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_GroupID": conversation.groupID ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_Title": conversation.title ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_AvatarUrl": conversation.faceUrl ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_AvatarImage": conversation.avatarImage ?? UIImage(),
            "TUICore_TUIChatObjectFactory_ChatViewController_Draft": conversation.draftText ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_AtTipsStr": conversation.atTipsStr ?? "",
            "TUICore_TUIChatObjectFactory_ChatViewController_AtMsgSeqs": conversation.atMsgSeqs ?? []
        ]
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Classic", param: param, forResult: nil)
        return true
    }
}
