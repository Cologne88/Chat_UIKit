import Foundation
import UIKit

class TUICaptureTimer {
    var gcdTimer: DispatchSourceTimer?
    var captureDuration: CGFloat = 0.0
    var maxCaptureTime: CGFloat = 15.0
    var progressBlock: ((CGFloat, CGFloat) -> Void)?
    var progressFinishBlock: ((CGFloat, CGFloat) -> Void)?
    var progressCancelBlock: (() -> Void)?

    init() {
        self.maxCaptureTime = 15.0
    }

    func startTimer() {
        gcdTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        
        let delayTime: TimeInterval = 0.0
        let timeInterval: TimeInterval = 0.1
        gcdTimer?.schedule(deadline: .now() + delayTime, repeating: timeInterval)
        
        gcdTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.captureDuration += CGFloat(timeInterval)
            
            DispatchQueue.main.async {
                if let progressBlock = self.progressBlock {
                    progressBlock(self.captureDuration / self.maxCaptureTime, self.captureDuration)
                }
            }
            
            if self.captureDuration >= self.maxCaptureTime {
                let ratio = self.captureDuration / self.maxCaptureTime
                let recordTime = self.captureDuration
                self.cancel()
                DispatchQueue.main.async {
                    if let progressFinishBlock = self.progressFinishBlock {
                        progressFinishBlock(ratio, recordTime)
                    }
                }
            }
        }
        
        gcdTimer?.resume()
    }

    func stopTimer() {
        cancel()
        DispatchQueue.main.async {
            if let progressCancelBlock = self.progressCancelBlock {
                progressCancelBlock()
            }
        }
    }

    private func cancel() {
        gcdTimer?.cancel()
        gcdTimer = nil
        captureDuration = 0
    }
}
