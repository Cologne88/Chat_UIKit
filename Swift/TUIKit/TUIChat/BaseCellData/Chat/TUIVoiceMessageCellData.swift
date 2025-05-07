import AVFoundation
import Foundation
import TIMCommon

enum TUIVoiceAudioPlaybackStyle: UInt {
    case loudspeaker = 1
    case handset = 2
}

class TUIVoiceMessageCellData: TUIBubbleMessageCellData, AVAudioPlayerDelegate {
    var path: String?
    var uuid: String?
    var duration: Int = 0
    var length: Int = 0
    var isDownloading: Bool = false
    @objc dynamic var isPlaying: Bool = false
    var voiceHeight: CGFloat = 21.0
    @objc dynamic var currentTime: TimeInterval = 0.0
    var voiceAnimationImages: [UIImage] = []
    var voiceImage: UIImage?
    var voiceTop: CGFloat = 12.0

    private var audioPlayer: AVAudioPlayer?
    private var wavPath: String?
    private var timer: Timer?

    static var incommingVoiceTop: CGFloat = 12.0
    static var outgoingVoiceTop: CGFloat = 12.0

    var audioPlayerDidFinishPlayingBlock: (() -> Void)?

    override class func getCellData(message: V2TIMMessage) -> TUIMessageCellData {
        guard let elem = message.soundElem else {
            return TUIVoiceMessageCellData(direction: .incoming)
        }

        let direction: TMsgDirection = message.isSelf ? .outgoing : .incoming
        let soundData = TUIVoiceMessageCellData(direction: direction)
        soundData.duration = Int(elem.duration)
        soundData.length = Int(elem.dataSize)
        soundData.uuid = elem.uuid
        soundData.reuseId = "TVoiceMessaageCell"
        soundData.path = elem.path
        return soundData
    }

    override class func getDisplayString(message: V2TIMMessage) -> String {
        return TUISwift.timCommonLocalizableString("TUIKitMessageTypeVoice")
    }

    override func getReplyQuoteViewDataClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIVoiceReplyQuoteViewData")
    }

    override func getReplyQuoteViewClass() -> AnyClass? {
        return NSClassFromString("TUIChat.TUIVoiceReplyQuoteView")
    }

    override init(direction: TMsgDirection) {
        super.init(direction: direction)

        if direction == .incoming {
            self.cellLayout = TUIMessageCellLayout.incomingVoiceMessageLayout
            self.voiceImage = TUISwift.tuiChatDynamicImage("chat_voice_message_receiver_voice_normal_img", defaultImage: TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("message_voice_receiver_normal")) ?? UIImage())
            self.voiceImage = voiceImage?.rtlImageFlippedForRightToLeftLayoutDirection()
            self.voiceAnimationImages = [
                Self.formatImageByName("message_voice_receiver_playing_1"),
                Self.formatImageByName("message_voice_receiver_playing_2"),
                Self.formatImageByName("message_voice_receiver_playing_3")
            ]
            self.voiceTop = Self.incommingVoiceTop
        } else {
            self.cellLayout = TUIMessageCellLayout.outgoingVoiceMessageLayout
            self.voiceImage = TUISwift.tuiChatDynamicImage("chat_voice_message_sender_voice_normal_img", defaultImage: TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("message_voice_sender_normal")) ?? UIImage())
            self.voiceImage = voiceImage?.rtlImageFlippedForRightToLeftLayoutDirection()
            self.voiceAnimationImages = [
                Self.formatImageByName("message_voice_sender_playing_1"),
                Self.formatImageByName("message_voice_sender_playing_2"),
                Self.formatImageByName("message_voice_sender_playing_3")
            ]
            self.voiceTop = Self.outgoingVoiceTop
        }
    }

    static func formatImageByName(_ imgName: String) -> UIImage {
        let path = TUISwift.tuiChatImagePath(imgName)
        let img = TUIImageCache.sharedInstance().getResourceFromCache(path) ?? UIImage()
        return img.rtlImageFlippedForRightToLeftLayoutDirection()
    }

    func getVoicePath(isExist: inout Bool) -> String {
        var voicePath = ""
        var isDir = ObjCBool(false)
        isExist = false

        if let path = path, let lastComp = URL(string: path)?.lastPathComponent, direction == .outgoing {
            voicePath = "\(TUISwift.tuiKit_Voice_Path())\(lastComp)"
            if FileManager.default.fileExists(atPath: voicePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        if !isExist, let uuid = uuid, !uuid.isEmpty {
            voicePath = "\(TUISwift.tuiKit_Voice_Path())\(uuid).amr"
            if FileManager.default.fileExists(atPath: voicePath, isDirectory: &isDir), !isDir.boolValue {
                isExist = true
            }
        }

        return voicePath
    }

    func getIMSoundElem() -> V2TIMSoundElem? {
        let message: V2TIMMessage? = innerMessage
        guard let imMsg = message, imMsg.elemType == .ELEM_TYPE_SOUND else { return nil }
        return imMsg.soundElem
    }

    func playVoiceMessage() {
        if isPlaying {
            stopVoiceMessage()
            return
        }
        isPlaying = true

        if (innerMessage?.localCustomInt ?? 0) == 0 {
            innerMessage?.localCustomInt = 1
        }

        guard let imSound = getIMSoundElem() else { return }
        var isExist = false
        if uuid == nil || uuid!.isEmpty {
            uuid = imSound.uuid
        }
        let path = getVoicePath(isExist: &isExist)
        if isExist {
            playInternal(path: path)
        } else {
            if isDownloading {
                return
            }
            isDownloading = true
            imSound.downloadSound(
                path: path,
                progress: { _, _ in },
                succ: { [weak self] in
                    self?.isDownloading = false
                    self?.playInternal(path: path)
                },
                fail: { [weak self] _, _ in
                    self?.isDownloading = false
                    self?.stopVoiceMessage()
                }
            )
        }
    }

    private func playInternal(path: String) {
        guard isPlaying else { return }

        let playbackStyle = TUIVoiceMessageCellData.getAudioplaybackStyle()
        if playbackStyle == .handset {
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }

        let url = URL(fileURLWithPath: path)
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        let result = audioPlayer?.play() ?? false
        if !result {
            if let pathWithoutExtension = URL(string: path)?.deletingPathExtension().path {
                wavPath = pathWithoutExtension + ".wav"
            }
            if let path = wavPath {
                let url = URL(fileURLWithPath: path)
                audioPlayer?.stop()
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.play()
            }
        }

        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateProgress()
            }
        }
    }

    static func getAudioplaybackStyle() -> TUIVoiceAudioPlaybackStyle {
        let style = UserDefaults.standard.string(forKey: "tui_audioPlaybackStyle")
        if style == "1" {
            return .loudspeaker
        } else if style == "2" {
            return .handset
        }
        return .loudspeaker
    }

    static func changeAudioPlaybackStyle() {
        let style = getAudioplaybackStyle()
        if style == .loudspeaker {
            UserDefaults.standard.set("2", forKey: "tui_audioPlaybackStyle")
        } else {
            UserDefaults.standard.set("1", forKey: "tui_audioPlaybackStyle")
        }
        UserDefaults.standard.synchronize()
    }

    private func updateProgress() {
        DispatchQueue.main.async { [weak self] in
            self?.currentTime = self?.audioPlayer?.currentTime ?? 0
        }
    }

    func stopVoiceMessage() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            audioPlayer = nil
        }
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopVoiceMessage()
        if let wavPath = wavPath {
            try? FileManager.default.removeItem(atPath: wavPath)
        }
        audioPlayerDidFinishPlayingBlock?()
    }
}
