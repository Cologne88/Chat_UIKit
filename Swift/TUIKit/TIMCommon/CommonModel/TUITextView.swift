import UIKit

public protocol TUITextViewDelegate: AnyObject {
    func onLongPressTextViewMessage(_ textView: UITextView)
}

public class TUITextView: UITextView, UIGestureRecognizerDelegate {
    public var longPressGesture: UILongPressGestureRecognizer!
    public weak var tuiTextViewDelegate: TUITextViewDelegate?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.dataDetectorTypes = [.link, .phoneNumber]
        setupLongPressGesture()
        self.tintColor = UIColor(named: "chat_highlight_link_color") ?? UIColor.systemBlue
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.dataDetectorTypes = [.link, .phoneNumber]
        setupLongPressGesture()
        self.tintColor = UIColor(named: "chat_highlight_link_color") ?? UIColor.systemBlue
    }

    override public var canBecomeFirstResponder: Bool {
        return true
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    override public func buildMenu(with builder: UIMenuBuilder) {
        if #available(iOS 16.0, *) {
            builder.remove(menu: .lookup)
        }
        super.buildMenu(with: builder)
    }

    public func disableHighlightLink() {
        dataDetectorTypes = []
    }

    private func setupLongPressGesture() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            tuiTextViewDelegate?.onLongPressTextViewMessage(self)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer && gestureRecognizer != longPressGesture {
            return false
        }
        return true
    }
}
