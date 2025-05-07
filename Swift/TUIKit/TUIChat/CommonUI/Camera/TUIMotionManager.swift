//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

import AVFoundation
import CoreMotion
import UIKit

class TUIMotionManager {
    var motionManager: CMMotionManager?
    var deviceOrientation: UIDeviceOrientation = .unknown
    var videoOrientation: AVCaptureVideoOrientation = .portrait

    init() {
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1 / 15.0
        if !(motionManager?.isDeviceMotionAvailable ?? false) {
            motionManager = nil
            return
        }
        motionManager?.startDeviceMotionUpdates(to: .current!, withHandler: { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            self.handleDeviceMotion(motion)
        })
    }

    private func handleDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        let x = deviceMotion.gravity.x
        let y = deviceMotion.gravity.y
        if abs(y) >= abs(x) {
            if y >= 0 {
                deviceOrientation = .portraitUpsideDown
                videoOrientation = .portraitUpsideDown
            } else {
                deviceOrientation = .portrait
                videoOrientation = .portrait
            }
        } else {
            if x >= 0 {
                deviceOrientation = .landscapeRight
                videoOrientation = .landscapeRight
            } else {
                deviceOrientation = .landscapeLeft
                videoOrientation = .landscapeLeft
            }
        }
    }

    deinit {
        motionManager?.stopDeviceMotionUpdates()
    }
}
