
import Foundation
import ImSDK_Plus

enum TUIMessageSendingResultType: Int {
    case success = 0
    case failure = 1
}

protocol TUIMessageProgressManagerDelegate: AnyObject {
    func onUploadProgress(msgID: String, progress: Int)
    func onDownloadProgress(msgID: String, progress: Int)
    func onMessageSendingResultChanged(type: TUIMessageSendingResultType, messageID: String)
}

class TUIMessageProgressManager: NSObject, V2TIMSDKListener {
    static let shared = TUIMessageProgressManager()
    
    private var uploadProgress: [String: Int] = [:]
    private var downloadProgress: [String: Int] = [:]
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    private let lock = NSLock()
    
    override private init() {
        super.init()
       V2TIMManager.sharedInstance().addIMSDKListener(listener: self)
    }
    
    func addDelegate(_ delegate: TUIMessageProgressManagerDelegate) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.addDelegate(delegate)
            }
            return
        }
        
        if !delegates.contains(delegate) {
            delegates.add(delegate)
        }
    }
    
    func removeDelegate(_ delegate: TUIMessageProgressManagerDelegate) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.removeDelegate(delegate)
            }
            return
        }
        
        if delegates.contains(delegate) {
            delegates.remove(delegate)
        }
    }
    
    func uploadProgress(forMessage msgID: String) -> Int {
        if !uploadProgress.keys.contains(msgID) {
            return 0
        }
        
        var progress = 0
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        progress = uploadProgress[msgID] ?? 0
        return progress
    }

    func downloadProgress(forMessage msgID: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return downloadProgress[msgID] ?? 0
    }
    
    func appendUploadProgress(_ msgID: String, progress: Int) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.appendUploadProgress(msgID, progress: progress)
            }
            return
        }
        
        guard !msgID.isEmpty else { return }
        
        if uploadProgress.keys.contains(msgID) {
            uploadProgress.removeValue(forKey: msgID)
        }
        
        if progress >= 100 || progress <= 0 {
            uploadCallback(msgID)
            return
        }
        
        uploadProgress[msgID] = progress
        uploadCallback(msgID)
    }
    
    func appendDownloadProgress(_ msgID: String, progress: Int) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.appendDownloadProgress(msgID, progress: progress)
            }
            return
        }
        
        guard !msgID.isEmpty else { return }
        
        if downloadProgress.keys.contains(msgID) {
            downloadProgress.removeValue(forKey: msgID)
        }
        
        if progress >= 100 || progress <= 0 {
            downloadCallback(msgID)
            return
        }
        
        downloadProgress[msgID] = progress
        downloadCallback(msgID)
    }
    
    func notifyMessageSendingResult(_ msgID: String, result: TUIMessageSendingResultType) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? TUIMessageProgressManagerDelegate {
                delegate.onMessageSendingResultChanged(type: result, messageID: msgID)
            }
        }
    }
    
    private func uploadCallback(_ msgID: String) {
        let progress = uploadProgress[msgID] ?? 100
        for delegate in delegates.allObjects {
            if let delegate = delegate as? TUIMessageProgressManagerDelegate {
                delegate.onUploadProgress(msgID: msgID, progress: progress)
            }
        }
    }
    
    private func downloadCallback(_ msgID: String) {
        let progress = downloadProgress[msgID] ?? 100
        for delegate in delegates.allObjects {
            if let delegate = delegate as? TUIMessageProgressManagerDelegate {
                delegate.onDownloadProgress(msgID: msgID, progress: progress)
            }
        }
    }
    
    private func reset() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.reset()
            }
            return
        }
        
        uploadProgress.removeAll()
        downloadProgress.removeAll()
    }
    
    func onConnecting() {
        reset()
    }
}
