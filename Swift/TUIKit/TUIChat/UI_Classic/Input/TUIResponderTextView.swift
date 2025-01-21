import UIKit

protocol TUIResponderTextViewDelegate: UITextViewDelegate {
    func onDeleteBackward(_ textView: TUIResponderTextView)
}

class TUIResponderTextView: UITextView {
    weak var overrideNextResponder: UIResponder?

    override var text: String? {
        didSet {
            delegate?.textViewDidChange?(self)
        }
    }

    override var next: UIResponder? {
        if let overrideNextResponder = overrideNextResponder {
            return overrideNextResponder
        } else {
            return super.next
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if self.overrideNextResponder != nil {
            return false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        if #available(iOS 16.0, *) {
            builder.remove(menu: .lookup)
        }
        super.buildMenu(with: builder)
    }

    override func deleteBackward() {
        if let delegate = delegate as? TUIResponderTextViewDelegate {
            delegate.onDeleteBackward(self)
        }
        super.deleteBackward()
    }

    override func copy(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = self.textStorage.attributedSubstring(from: selectedRange).tui_getPlainString()
    }

    override func cut(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = self.textStorage.attributedSubstring(from: selectedRange).tui_getPlainString()
        let textFont = UIFont.systemFont(ofSize: 16.0)
        let spaceString = NSAttributedString(string: "", attributes: [.font: textFont])
        textStorage.replaceCharacters(in: selectedRange, with: spaceString)
    }
}
