import TIMCommon
import UIKit

enum TUIEmojiFaceType: UInt {
    case keyBoard = 0
    case popDetail = 1
    case popContextDetail = 2
}

public class TUIEmojiConfig: NSObject {
    public static let shared = TUIEmojiConfig()
    
    /**
     * In respect for the copyright of the emoji design, the Chat Demo/TUIKit project does not include the cutouts of large emoji elements. Please replace them
     * with your own designed or copyrighted emoji packs before the official launch for commercial use. The default small yellow face emoji pack is copyrighted by
     * Tencent Cloud and can be authorized for a fee. If you wish to obtain authorization, please submit a ticket to contact us.
     *
     * submit a ticket url：https://console.cloud.tencent.com/workorder/category?level1_id=29&level2_id=40&source=14&data_title=%E5%8D%B3%E6%97%B6%E9%80%9A%E4%BF%A1%20IM&step=1 (China mainland)
     * submit a ticket url：https://console.tencentcloud.com/workorder/category?level1_id=29&level2_id=40&source=14&data_title=Chat&step=1 (Other regions)
     */
    public var faceGroups: [TUIFaceGroup] = []
    public var chatPopDetailGroups: [TUIFaceGroup] = []
    public var chatContextEmojiDetailGroups: [TUIFaceGroup] = []
    
    override private init() {
        super.init()
        updateEmojiGroups()
        NotificationCenter.default.addObserver(self, selector: #selector(onChangeLanguage), name: NSNotification.Name(TUIChangeLanguageNotification), object: nil)
    }
    
    public func appendFaceGroup(_ faceGroup: TUIFaceGroup) {
        faceGroups.append(faceGroup)
    }
    
    @objc private func onChangeLanguage() {
        updateEmojiGroups()
    }
    
    public func updateEmojiGroups() {
        faceGroups = updateFaceGroups(faceGroups, type: .keyBoard)
        chatPopDetailGroups = updateFaceGroups(chatPopDetailGroups, type: .popDetail)
        chatContextEmojiDetailGroups = updateFaceGroups(chatContextEmojiDetailGroups, type: .popContextDetail)
    }
    
    private func updateFaceGroups(_ groups: [TUIFaceGroup], type: TUIEmojiFaceType) -> [TUIFaceGroup] {
        var updatedGroups = groups
        if !updatedGroups.isEmpty {
            updatedGroups.removeFirst()
            if let defaultFaceGroup = findFaceGroupAboutType(type) {
                updatedGroups.insert(defaultFaceGroup, at: 0)
            }
        } else {
            if let defaultFaceGroup = findFaceGroupAboutType(type) {
                updatedGroups.append(defaultFaceGroup)
            }
        }
        return updatedGroups
    }
    
    private func findFaceGroupAboutType(_ type: TUIEmojiFaceType) -> TUIFaceGroup? {
        var emojiFaces: [TUIFaceCellData] = []
        if let emojis = NSArray(contentsOfFile: TUISwift.tuiChatFaceImagePath("emoji/emoji.plist")) as? [[String: String]] {
            for dic in emojis {
                let data = TUIFaceCellData()
                if let name = dic["face_name"], let fileName = dic["face_file"] {
                    let path = "emoji/\(fileName)"
                    let localizableName = TUIGlobalization.getLocalizedString(forKey: name, bundle: "TUIChatFace")
                    data.name = name
                    data.path = TUISwift.tuiChatFaceImagePath(path)
                    data.localizableName = localizableName
                    if let path = data.path {
                        addFaceToCache(path)
                    }
                    emojiFaces.append(data)
                }
            }
        }
        
        if !emojiFaces.isEmpty {
            let emojiGroup = TUIFaceGroup()
            emojiGroup.faces = emojiFaces
            emojiGroup.groupIndex = 0
            emojiGroup.groupPath = TUISwift.tuiChatFaceImagePath("emoji/")
            emojiGroup.menuPath = TUISwift.tuiChatFaceImagePath("emoji/menu")
            emojiGroup.isNeedAddInInputBar = true
            emojiGroup.groupName = TUISwift.timCommonLocalizableString("TUIChatFaceGroupAllEmojiName")
            
            switch type {
            case .keyBoard:
                emojiGroup.rowCount = 4
                emojiGroup.itemCountPerRow = 8
                emojiGroup.needBackDelete = false
            case .popDetail:
                emojiGroup.rowCount = 3
                emojiGroup.itemCountPerRow = 8
                emojiGroup.needBackDelete = false
            case .popContextDetail:
                emojiGroup.rowCount = 20
                emojiGroup.itemCountPerRow = 7
                emojiGroup.needBackDelete = false
            }
            
            if let path = emojiGroup.menuPath {
                addFaceToCache(path)
            }
            addFaceToCache(TUISwift.tuiChatFaceImagePath("del_normal"))
            addFaceToCache(TUISwift.tuiChatFaceImagePath("ic_unknown_image"))
            return emojiGroup
        }
        
        return nil
    }
    
    public func getChatPopMenuRecentQueue() -> TUIFaceGroup? {
        var emojiFaces: [TUIFaceCellData] = []
        if let emojis = getChatPopMenuQueue() {
            for dic in emojis {
                let data = TUIFaceCellData()
                if let name = dic["face_name"] as? String, let fileName = dic["face_file"] as? String {
                    let path = "emoji/\(fileName)"
                    let localizableName = TUIGlobalization.getLocalizedString(forKey: name, bundle: "TUIChatFace")
                    data.name = name
                    data.path = TUISwift.tuiChatFaceImagePath(path)
                    data.localizableName = localizableName
                    emojiFaces.append(data)
                }
            }
        }
        
        if !emojiFaces.isEmpty {
            var ocFaces: [TUIFaceCellData] = []
            for emoji in emojiFaces {
                ocFaces.append(emoji)
            }
            let emojiGroup = TUIFaceGroup()
            emojiGroup.faces = ocFaces
            emojiGroup.groupIndex = 0
            emojiGroup.groupPath = TUISwift.tuiChatFaceImagePath("emoji/")
            emojiGroup.menuPath = TUISwift.tuiChatFaceImagePath("emoji/menu")
            emojiGroup.rowCount = 1
            emojiGroup.itemCountPerRow = 6
            emojiGroup.needBackDelete = false
            emojiGroup.isNeedAddInInputBar = true
            return emojiGroup
        }
        
        return nil
    }
    
    public func updateRecentMenuQueue(_ faceName: String) {
        let emojis = getChatPopMenuQueue() ?? []
        var muArray = emojis
        
        if let index = emojis.firstIndex(where: { ($0["face_name"] as? String) == faceName }) {
            let targetDic = emojis[index]
            muArray.remove(at: index)
            muArray.insert(targetDic, at: 0)
        } else {
            muArray.removeLast()
            if let emojis = NSArray(contentsOfFile: TUISwift.tuiChatFaceImagePath("emoji/emoji.plist")) as? [[String: String]] {
                if let targetDic = emojis.first(where: { $0["face_name"] == faceName }) {
                    muArray.insert(targetDic, at: 0)
                }
            }
        }
        
        UserDefaults.standard.set(muArray, forKey: "TUIChatPopMenuQueue")
        UserDefaults.standard.synchronize()
    }
    
    private func getChatPopMenuQueue() -> [[String: Any]]? {
        if let emojis = UserDefaults.standard.object(forKey: "TUIChatPopMenuQueue") as? [[String: Any]], !emojis.isEmpty {
            if let dic = emojis.last, let fileName = dic["face_file"] as? String {
                let path = "emoji/\(fileName)"
                if UIImage(contentsOfFile: TUISwift.tuiChatFaceImagePath(path)) != nil {
                    return emojis
                }
            }
        }
        return NSArray(contentsOfFile: TUISwift.tuiChatFaceImagePath("emoji/emojiRecentDefaultList.plist")) as? [[String: Any]]
    }
    
    private func addResourceToCache(_ path: String) {
        TUIImageCache.sharedInstance().addResource(toCache: path)
    }
    
    private func addFaceToCache(_ path: String) {
        TUIImageCache.sharedInstance().addFace(toCache: path)
    }
}
