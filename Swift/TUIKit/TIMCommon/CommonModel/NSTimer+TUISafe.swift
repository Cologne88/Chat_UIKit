import Foundation

extension Timer {
    public static func tui_scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        return scheduledTimer(timeInterval: interval, target: self, selector: #selector(tui_callBlock(_:)), userInfo: block, repeats: repeats)
    }

    @objc private static func tui_callBlock(_ timer: Timer) {
        if let block = timer.userInfo as? (Timer) -> Void {
            block(timer)
        }
    }
}
