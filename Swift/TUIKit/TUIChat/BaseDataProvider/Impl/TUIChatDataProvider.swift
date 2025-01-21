import ImSDK_Plus
import TIMCommon
import TUICore

class TUISplitEmojiData: NSObject {
    var start: Int = 0
    var end: Int = 0
}

class TUIChatDataProvider: TUIChatBaseDataProvider {
    private var customInputMoreActionItemList: [TUICustomActionSheetItem] = []
    private var builtInInputMoreActionItemList: [TUICustomActionSheetItem] = []

    lazy var welcomeInputMoreMenu: TUIInputMoreCellData = {
        var welcomeInputMoreMenu = TUIInputMoreCellData()
        welcomeInputMoreMenu.priority = 0
        welcomeInputMoreMenu.title = TUISwift.timCommonLocalizableString("TUIKitMoreLink")
        welcomeInputMoreMenu.image = TUISwift.tuiChatBundleThemeImage("chat_more_link_img", defaultImage: "chat_more_link_img")
        welcomeInputMoreMenu.onClicked = { [weak self] _ in
            guard let self = self else { return }
            let text = TUISwift.timCommonLocalizableString("TUIKitWelcome") ?? ""
            var link = TUITencentCloudHomePageEN
            let language = TUIGlobalization.getPreferredLanguage() ?? ""
            if language.contains("zh-") {
                link = TUITencentCloudHomePageCN
            }
            do {
                let param: [String: Any] = [BussinessID: BussinessID_TextLink, "text": text, "link": link]
                let data = try JSONSerialization.data(withJSONObject: param, options: [])
                let message = TUIMessageDataProvider.getCustomMessageWithJsonData(data, desc: text, extensionInfo: text)
                self.delegate?.dataProvider?(self, sendMessage: message)
            } catch {
                print("[\(self)] Post Json Error")
            }
        }
        return welcomeInputMoreMenu
    }()

    lazy var customInputMoreMenus: [TUIInputMoreCellData] = {
        var customInputMoreMenus = [TUIInputMoreCellData]()
        return customInputMoreMenus
    }()

    lazy var builtInInputMoreMenus: [TUIInputMoreCellData] = {
        var menus = self.createBuiltInInputMoreMenusWithConversationModel(conversationModel: nil)
        return menus
    }()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onChangeLanguage), name: NSNotification.Name(rawValue: TUIChangeLanguageNotification), object: nil)
    }

    // MARK: - Public

    // For Classic Edition.
    func getMoreMenuCellDataArray(groupID: String, userID: String, conversationModel: TUIChatConversationModel, actionController: TIMInputViewMoreActionProtocol) -> [TUIInputMoreCellData] {
        self.builtInInputMoreMenus = self.createBuiltInInputMoreMenusWithConversationModel(conversationModel: conversationModel)
        var moreMenus: [TUIInputMoreCellData] = []
        moreMenus.append(contentsOf: self.builtInInputMoreMenus)

        let isNeedWelcomeCustomMessage = TUIChatConfig.shared.enableWelcomeCustomMessage && conversationModel.enableWelcomeCustomMessage
        if isNeedWelcomeCustomMessage {
            if !self.customInputMoreMenus.contains(self.welcomeInputMoreMenu) {
                self.customInputMoreMenus.append(self.welcomeInputMoreMenu)
            }
        }
        moreMenus.append(contentsOf: self.customInputMoreMenus)

        // Extension items
        let isNeedVideoCall = TUIChatConfig.shared.enableVideoCall && conversationModel.enableVideoCall
        let isNeedAudioCall = TUIChatConfig.shared.enableAudioCall && conversationModel.enableAudioCall
        let isNeedRoom = TUIChatConfig.shared.showRoomButton && conversationModel.enableRoom
        let isNeedPoll = TUIChatConfig.shared.showPollButton && conversationModel.enablePoll
        let isNeedGroupNote = TUIChatConfig.shared.showGroupNoteButton && conversationModel.enableGroupNote

        var extensionParam: [String: Any] = [:]
        if !userID.isEmpty {
            extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_UserID] = userID
        } else if !groupID.isEmpty {
            extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_GroupID] = groupID
        }
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_FilterVideoCall] = !isNeedVideoCall
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_FilterAudioCall] = !isNeedAudioCall
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_FilterRoom] = !isNeedRoom
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_FilterPoll] = !isNeedPoll
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_FilterGroupNote] = !isNeedGroupNote
        extensionParam[TUICore_TUIChatExtension_InputViewMoreItem_ActionVC] = actionController
        let extensionList = TUICore.getExtensionList(TUICore_TUIChatExtension_InputViewMoreItem_ClassicExtensionID, param: extensionParam)
        for info in extensionList {
            assert(info.icon != nil && info.text != nil && info.onClicked != nil, "extension for input view is invalid, check icon/text/onclick")
            if let icon = info.icon, let text = info.text, let onClicked = info.onClicked {
                let data = TUIInputMoreCellData()
                data.priority = info.weight
                data.image = icon
                data.title = text
                data.onClicked = onClicked
                moreMenus.append(data)
            }
        }

        // Customized items
        if let items = conversationModel.customizedNewItemsInMoreMenu as? [TUIInputMoreCellData], items.count > 0 {
            moreMenus.append(contentsOf: items)
        }

        // Sort with priority
        let sortedMenus = moreMenus.sorted { $0.priority > $1.priority }
        return sortedMenus
    }

    // For Minimalist Edition.
    func getInputMoreActionItemList(userID: String, groupID: String, conversationModel: TUIChatConversationModel, pushVC: UINavigationController?, actionController: TIMInputViewMoreActionProtocol) -> [TUICustomActionSheetItem] {
        var result: [TUICustomActionSheetItem] = []
        result.append(contentsOf: self.createBuiltInInputMoreActionItemList(model: conversationModel))
        result.append(contentsOf: self.createCustomInputMoreActionItemList(model: conversationModel))

        // Extension items
        var items: [TUICustomActionSheetItem] = []
        var param: [String: Any] = [:]
        if !userID.isEmpty {
            param[TUICore_TUIChatExtension_InputViewMoreItem_UserID] = userID
        } else if !groupID.isEmpty {
            param[TUICore_TUIChatExtension_InputViewMoreItem_GroupID] = groupID
        }
        param[TUICore_TUIChatExtension_InputViewMoreItem_FilterVideoCall] = !TUIChatConfig.shared.enableVideoCall
        param[TUICore_TUIChatExtension_InputViewMoreItem_FilterAudioCall] = !TUIChatConfig.shared.enableAudioCall
        if let pushVC = pushVC {
            param[TUICore_TUIChatExtension_InputViewMoreItem_PushVC] = pushVC
        }
        param[TUICore_TUIChatExtension_InputViewMoreItem_ActionVC] = actionController
        let extensionList = TUICore.getExtensionList(TUICore_TUIChatExtension_InputViewMoreItem_MinimalistExtensionID, param: param)
        for info in extensionList {
            if let icon = info.icon, let text = info.text, let onClicked = info.onClicked {
                let item = TUICustomActionSheetItem(title: text, leftMark: icon) { _ in
                    onClicked(param)
                }
                item.priority = info.weight
                items.append(item)
            }
        }
        if items.count > 0 {
            result.append(contentsOf: items)
        }

        // Sort with priority
        let sorted = result.sorted { $0.priority > $1.priority }
        return sorted
    }

    // MARK: - Private

    @objc private func onChangeLanguage() {
        self.customInputMoreActionItemList = []
        self.builtInInputMoreActionItemList = []
    }

    // MARK: - - Classic

    private func createBuiltInInputMoreMenusWithConversationModel(conversationModel: TUIChatConversationModel?) -> [TUIInputMoreCellData] {
        var isNeedRecordVideo = true
        var isNeedTakePhoto = true
        var isNeedAlbum = true
        var isNeedFile = true
        if let conversationModel = conversationModel {
            isNeedRecordVideo = TUIChatConfig.shared.showRecordVideoButton && conversationModel.enableRecordVideo
            isNeedTakePhoto = TUIChatConfig.shared.showTakePhotoButton && conversationModel.enableTakePhoto
            isNeedAlbum = TUIChatConfig.shared.showAlbumButton && conversationModel.enableAlbum
            isNeedFile = TUIChatConfig.shared.showFileButton && conversationModel.enableFile
        }

        let albumData = TUIInputMoreCellData()
        albumData.priority = 1000
        albumData.title = TUISwift.timCommonLocalizableString("TUIKitMorePhoto")
        albumData.image = TUISwift.tuiChatBundleThemeImage("chat_more_picture_img", defaultImage: "more_picture")
        albumData.onClicked = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onSelectPhotoMoreCellData?()
        }

        let takePictureData = TUIInputMoreCellData()
        takePictureData.priority = 900
        takePictureData.title = TUISwift.timCommonLocalizableString("TUIKitMoreCamera")
        takePictureData.image = TUISwift.tuiChatBundleThemeImage("chat_more_camera_img", defaultImage: "more_camera")
        takePictureData.onClicked = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onTakePictureMoreCellData?()
        }

        let videoData = TUIInputMoreCellData()
        videoData.priority = 800
        videoData.title = TUISwift.timCommonLocalizableString("TUIKitMoreVideo")
        videoData.image = TUISwift.tuiChatBundleThemeImage("chat_more_video_img", defaultImage: "more_video")
        videoData.onClicked = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onTakeVideoMoreCellData?()
        }

        let fileData = TUIInputMoreCellData()
        fileData.priority = 700
        fileData.title = TUISwift.timCommonLocalizableString("TUIKitMoreFile")
        fileData.image = TUISwift.tuiChatBundleThemeImage("chat_more_file_img", defaultImage: "more_file")
        fileData.onClicked = { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.onSelectFileMoreCellData?()
        }

        var formatArray: [TUIInputMoreCellData] = []
        if isNeedAlbum {
            formatArray.append(albumData)
        }
        if isNeedTakePhoto {
            formatArray.append(takePictureData)
        }
        if isNeedRecordVideo {
            formatArray.append(videoData)
        }
        if isNeedFile {
            formatArray.append(fileData)
        }
        return formatArray
    }

    // MARK: - - Minimalist

    private func createBuiltInInputMoreActionItemList(model: TUIChatConversationModel) -> [TUICustomActionSheetItem] {
        if self.builtInInputMoreActionItemList.isEmpty {
            self.builtInInputMoreActionItemList = []

            let showTakePhoto = TUIChatConfig.shared.showTakePhotoButton && model.enableTakePhoto
            let showAlbum = TUIChatConfig.shared.showAlbumButton && model.enableAlbum
            let showRecordVideo = TUIChatConfig.shared.showRecordVideoButton && model.enableRecordVideo
            let showFile = TUIChatConfig.shared.showFileButton && model.enableFile

            if showAlbum {
                let album = TUICustomActionSheetItem(title: TUISwift.timCommonLocalizableString("TUIKitMorePhoto"), leftMark: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_more_photo"))!) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.onSelectPhotoMoreCellData?()
                }
                album.priority = 1000
                self.builtInInputMoreActionItemList.append(album)
            }

            if showTakePhoto {
                let takePhoto = TUICustomActionSheetItem(title: TUISwift.timCommonLocalizableString("TUIKitMoreCamera"), leftMark: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_more_camera"))!) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.onTakePictureMoreCellData?()
                }
                takePhoto.priority = 900
                self.builtInInputMoreActionItemList.append(takePhoto)
            }

            if showRecordVideo {
                let recordVideo = TUICustomActionSheetItem(title: TUISwift.timCommonLocalizableString("TUIKitMoreVideo"), leftMark: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_more_video"))!) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.onTakeVideoMoreCellData?()
                }
                recordVideo.priority = 800
                self.builtInInputMoreActionItemList.append(recordVideo)
            }

            if showFile {
                let file = TUICustomActionSheetItem(title: TUISwift.timCommonLocalizableString("TUIKitMoreFile"), leftMark: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_more_document"))!) { [weak self] _ in
                    guard let self = self else { return }
                    self.delegate?.onSelectFileMoreCellData?()
                }
                file.priority = 700
                self.builtInInputMoreActionItemList.append(file)
            }
        }
        return self.builtInInputMoreActionItemList
    }

    private func createCustomInputMoreActionItemList(model: TUIChatConversationModel) -> [TUICustomActionSheetItem] {
        if self.customInputMoreActionItemList.isEmpty {
            var arrayM: [TUICustomActionSheetItem] = []

            let showCustom = TUIChatConfig.shared.enableWelcomeCustomMessage && model.enableWelcomeCustomMessage
            if showCustom {
                let link = TUICustomActionSheetItem(title: TUISwift.timCommonLocalizableString("TUIKitMoreLink"), leftMark: UIImage(named: TUISwift.tuiChatImagePath_Minimalist("icon_more_custom"))!) { [weak self] _ in
                    guard let self else { return }
                    let text = TUISwift.timCommonLocalizableString("TUIKitWelcome") ?? ""
                    var homePageLink = TUITencentCloudHomePageEN
                    let language = TUIGlobalization.getPreferredLanguage() ?? ""
                    if language.contains("zh-") {
                        homePageLink = TUITencentCloudHomePageCN
                    }
                    do {
                        let param: [String: Any] = [BussinessID: BussinessID_TextLink, "text": text, "link": homePageLink]
                        let data = try JSONSerialization.data(withJSONObject: param, options: [])
                        let message = TUIMessageDataProvider.getCustomMessageWithJsonData(data, desc: text, extensionInfo: text)
                        self.delegate?.dataProvider?(self, sendMessage: message)
                    } catch {
                        print("[\(self)] Post Json Error")
                    }
                }
                link.priority = 100
                arrayM.append(link)
            }

            if let items = model.customizedNewItemsInMoreMenu as? [TUICustomActionSheetItem], items.count > 0 {
                arrayM.append(contentsOf: items)
            }
            self.customInputMoreActionItemList = arrayM
        }
        return self.customInputMoreActionItemList
    }

    // MARK: - - Override

    override func abstractDisplay(withMessage msg: V2TIMMessage) -> String {
        var desc = ""
        if let nickName = msg.nickName, !nickName.isEmpty {
            desc = nickName
        } else if let sender = msg.sender, !sender.isEmpty {
            desc = sender
        }
        var display = self.delegate?.dataProvider(self, mergeForwardMsgAbstactForMessage: msg) ?? ""

        if display.isEmpty {
            display = Self.parseAbstractDisplayWStringFromMessageElement(message: msg)
        }
        let splitStr = "\u{202C}:"

        let nameFormat = "\(desc)\(splitStr)"
        return Self.alignEmojiStringWithUserName(userName: nameFormat, text: display)
    }

    static func parseAbstractDisplayWStringFromMessageElement(message: V2TIMMessage) -> String {
        var str: String?
        if message.elemType == .ELEM_TYPE_TEXT, let textElem = message.textElem {
            str = textElem.text
        } else {
            str = TUIMessageDataProvider.getDisplayString(message)
        }
        return str ?? ""
    }

    static func alignEmojiStringWithUserName(userName: String, text: String) -> String {
        let textList = Self.splitEmojiText(text: text)
        let forwardMsgLength = 98
        var sb = userName
        var length = userName.count
        for textItem in textList {
            let isFaceChar = Self.isFaceStrKey(strkey: textItem)
            if isFaceChar {
                if length + textItem.count < forwardMsgLength {
                    sb += textItem
                    length += textItem.count
                } else {
                    sb += "..."
                    break
                }
            } else {
                if length + textItem.count < forwardMsgLength {
                    sb += textItem
                    length += textItem.count
                } else {
                    sb += textItem
                    break
                }
            }
        }
        return sb
    }

    static func isFaceStrKey(strkey: String) -> Bool {
        guard let service = TIMCommonMediator.share().getObject(TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol else {
            return false
        }
        if let groups = service.getFaceGroup() as? [TUIFaceGroup], let firstGroup = groups.first, firstGroup.facesMap[strkey] != nil {
            return true
        } else {
            return false
        }
    }

    static func splitEmojiText(text: String) -> [String] {
        var text = text
        let regex = "\\[(\\S+?)\\]"
        let regexExp = try? NSRegularExpression(pattern: regex, options: [])
        let matches = regexExp?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        var emojiDataList: [TUISplitEmojiData] = []
        var lastMentionIndex = -1
        for match in matches {
            let emojiKey = (text as NSString).substring(with: match.range)
            let start: Int
            if lastMentionIndex != -1 {
                start = (text as NSString).range(of: emojiKey, options: [], range: NSRange(location: lastMentionIndex, length: text.count - lastMentionIndex)).location
            } else {
                start = (text as NSString).range(of: emojiKey).location
            }
            let end = start + emojiKey.count
            lastMentionIndex = end

            if !Self.isFaceStrKey(strkey: emojiKey) {
                continue
            }
            let emojiData = TUISplitEmojiData()
            emojiData.start = start
            emojiData.end = end
            emojiDataList.append(emojiData)
        }
        var stringList: [String] = []
        var offset = 0
        for emojiData in emojiDataList {
            let start = emojiData.start - offset
            let end = emojiData.end - offset
            let startStr = (text as NSString).substring(to: start)
            let middleStr = (text as NSString).substring(with: NSRange(location: start, length: end - start))
            text = (text as NSString).substring(from: end)
            if !startStr.isEmpty {
                stringList.append(startStr)
            }
            stringList.append(middleStr)
            offset += startStr.count + middleStr.count
        }
        if !text.isEmpty {
            stringList.append(text)
        }
        return stringList
    }
}
