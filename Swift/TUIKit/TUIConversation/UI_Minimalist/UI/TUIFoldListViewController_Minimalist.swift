import TIMCommon
import TUICore
import UIKit

class TUIFoldListViewController_Minimalist: UIViewController, TUINavigationControllerDelegate, TUIConversationListControllerListener {
    var dismissCallback: ((NSMutableAttributedString, [Any], [Any]) -> Void)?

    private var titleView: TUINaviBarIndicatorView?
    private var mainTitle: String?

    lazy var conv: TUIConversationListController_Minimalist = {
        var conv = TUIConversationListController_Minimalist()
        return conv
    }()

    lazy var noDataTipsLabel: UILabel = {
        var noDataTipsLabel = UILabel()
        noDataTipsLabel.textColor = UIColor.tui_color(withHex: "#999999")
        noDataTipsLabel.font = UIFont.systemFont(ofSize: 14.0)
        noDataTipsLabel.textAlignment = .center
        noDataTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitContactNoGroupChats")
        noDataTipsLabel.isHidden = true
        return noDataTipsLabel
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        conv.dataProvider = TUIFoldConversationListDataProvider_Minimalist()
        conv.dataProvider.delegate = conv
        conv.isShowBanner = false
        conv.delegate = self

        conv.dataSourceChanged = { [weak self] count in
            guard let self = self else { return }
            self.noDataTipsLabel.isHidden = count > 0
        }
        addChild(conv)
        view.addSubview(conv.view)

        setupNavigator()
        view.addSubview(noDataTipsLabel)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        noDataTipsLabel.frame = CGRect(x: 10, y: 120, width: view.bounds.size.width - 20, height: 40)
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
        guard let foldProvider = conv.dataProvider as? TUIFoldConversationListDataProvider_Minimalist else { return }
        let needRemoveFromCacheMapArray = foldProvider.needRemoveConversationList
        let conversationList = conv.dataProvider.conversationList
        if !conversationList.isEmpty {
            let sortArray = conversationList.sorted { $0.orderKey > $1.orderKey }
            guard let lastItem = sortArray.first else { return }
            foldSubTitle = lastItem.foldSubTitle ?? NSMutableAttributedString()
            dismissCallback(foldSubTitle, sortArray, needRemoveFromCacheMapArray as [Any])
        } else {
            dismissCallback(foldSubTitle, [], needRemoveFromCacheMapArray as [Any])
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
                } else if let userID = msg.userID, !userID.isEmpty {
                    return TUISwift.timCommonLocalizableString("TUIKitMessageTipsOthersRecallMessage")
                } else if let groupID = msg.groupID, !groupID.isEmpty {
                    return String(format: TUISwift.timCommonLocalizableString("TUIKitMessageTipsRecallMessageFormat"), msg.nameCard ?? msg.nickName ?? msg.sender ?? "")
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
        navigationController?.push("TUICore_TUIChatObjectFactory_ChatViewController_Minimalist", param: param, forResult: nil)
        return true
    }
}
