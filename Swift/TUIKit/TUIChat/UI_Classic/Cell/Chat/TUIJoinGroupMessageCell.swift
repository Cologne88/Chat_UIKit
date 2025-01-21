import TIMCommon
import UIKit

@objc protocol TUIJoinGroupMessageCellDelegate: AnyObject {
    @objc optional func didTapOnNameLabel(_ cell: TUIJoinGroupMessageCell)
    @objc optional func didTapOnSecondNameLabel(_ cell: TUIJoinGroupMessageCell)
    @objc optional func didTapOnRestNameLabel(_ cell: TUIJoinGroupMessageCell, withIndex index: Int)
}

class TUIJoinGroupMessageCell: TUISystemMessageCell, UITextViewDelegate {
    var joinData: TUIJoinGroupMessageCellData?
    weak var joinGroupDelegate: TUIJoinGroupMessageCellDelegate?
    private var textView: UITextView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTextView() {
        textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textColor = UIColor.d_systemGray()
        textView.textContainerInset = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
        textView.layer.cornerRadius = 3
        textView.delegate = self
        textView.textAlignment = .left

        messageLabel.removeFromSuperview()
        container.addSubview(textView)
        textView.delaysContentTouches = false
    }

    override func fill(with data: TUISystemMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIJoinGroupMessageCellData else { return }

        joinData = data
        nameLabel.isHidden = true
        avatarView.isHidden = true
        retryView.isHidden = true
        indicator.stopAnimating()

        let attributeString = NSMutableAttributedString(string: data.content)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributeDict: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: messageLabel.font as Any,
            NSAttributedString.Key.foregroundColor: UIColor.d_systemGray(),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]
        attributeString.setAttributes(attributeDict, range: NSRange(location: 0, length: attributeString.length))

        if let userNameList = data.userNameList, (data.userNameList?.count ?? 0) > 0 {
            let nameRangeList = findRightRangeOfAllString(stringList: userNameList, inText: attributeString.string)
            var i = 0
            for nameRange in nameRangeList {
                attributeString.addAttribute(.link, value: "\(i)", range: nameRange)
                i += 1
            }
        }
        textView.attributedText = attributeString

        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        container.snp.remakeConstraints { make in
            make.center.equalTo(contentView)
            make.size.equalTo(contentView)
        }
        if textView.superview != nil {
            textView.snp.remakeConstraints { make in
                make.center.equalTo(container)
                make.size.equalTo(contentView)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.tui_mm_center()
        textView.mm_fill()
    }

    private func onSelectUserName(_ index: Int) {
        joinGroupDelegate?.didTapOnRestNameLabel?(self, withIndex: index)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        guard let userNames = joinData?.userNameList else { return false }
        for (i, _) in userNames.enumerated() {
            if URL.absoluteString == "\(i)" {
                onSelectUserName(i)
            }
        }
        return false
    }

    /**
      To obtain the exact position of the nickname in the text content, the following properties are used: the storage order of userName in the array must be the same as the order in which the final text is displayed. For example: the text content is, "A invited B, C, D to join the group", then the storage order of the elements in userName must be ABCD. Therefore, the method of "searching from the beginning and searching in succession" is used.
      For example, find the first element A first, because of the characteristics of rangeOfString, it must find the A at the head position. After finding A at the head position, we remove A from the search range, and the search range becomes "B, C, D are invited to join the group", and then continue to search for the next element, which is B.
     */
    func findRightRangeOfAllString(stringList: [String], inText text: String) -> [NSRange] {
        var rangeList: [NSRange] = []
        var beginLocation = 0

        for string in stringList {
            let newRange = NSRange(location: beginLocation, length: text.utf16.count - beginLocation)
            if let stringRange = text.range(of: string, options: .literal, range: Range(newRange, in: text)) {
                let nsRange = NSRange(stringRange, in: text)
                rangeList.append(nsRange)
                beginLocation = nsRange.location + nsRange.length
            }
        }
        return rangeList
    }
}
