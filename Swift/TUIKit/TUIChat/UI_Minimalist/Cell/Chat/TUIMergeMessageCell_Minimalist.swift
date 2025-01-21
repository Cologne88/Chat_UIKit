import TIMCommon
import UIKit

class TUIMergeMessageDetailRow_Minimalist: UIView {
    private var abstractNameLimitedWidth: CGFloat = 0

    lazy var abstractName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = UIColor(red: 187 / 255.0, green: 187 / 255.0, blue: 187 / 255.0, alpha: 1.0)
        label.textAlignment = TUISwift.isRTL() ? .right : .left
        return label
    }()

    lazy var abstractBreak: UILabel = {
        let label = UILabel()
        label.text = ":"
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_merge_message_content_color", defaultColor: "#d5d5d5")
        return label
    }()

    lazy var abstractDetail: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = TUISwift.tuiChatDynamicColor("chat_merge_message_content_color", defaultColor: "#d5d5d5")
        label.textAlignment = TUISwift.isRTL() ? .right : .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func setupView() {
        addSubview(abstractName)
        addSubview(abstractBreak)
        addSubview(abstractDetail)
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        abstractName.sizeToFit()
        abstractName.snp.remakeConstraints { make in
            make.leading.top.equalTo(0)
            make.trailing.lessThanOrEqualTo(self.abstractBreak.snp.leading)
            make.width.equalTo(self.abstractNameLimitedWidth)
        }

        abstractBreak.sizeToFit()
        abstractBreak.snp.remakeConstraints { make in
            make.leading.equalTo(self.abstractName.snp.trailing)
            make.top.equalTo(self.abstractName)
            make.size.equalTo(abstractBreak.frame.size)
        }

        abstractDetail.sizeToFit()
        abstractDetail.snp.remakeConstraints { make in
            make.leading.equalTo(self.abstractBreak.snp.trailing)
            make.top.equalTo(0)
            make.trailing.lessThanOrEqualTo(self).offset(-15)
            make.bottom.equalTo(self)
        }
    }

    func fill(with name: NSAttributedString?, _ detailContent: NSAttributedString?) {
        abstractName.attributedText = name
        abstractDetail.attributedText = detailContent

        if let senderStr = name {
            let senderRect = senderStr.boundingRect(with: CGSize(width: 70, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            abstractNameLimitedWidth = ceil(senderRect.size.width) + 2
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
}

class TUIMergeMessageCell_Minimalist: TUIMessageCell_Minimalist {
    var mergeData: TUIMergeMessageCellData?

    lazy var relayTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Chat history"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TUISwift.rgb(0, green: 0, blue: 0, alpha: 0.8)
        return label
    }()

    lazy var contentRowView1: TUIMergeMessageDetailRow_Minimalist = .init()
    lazy var contentRowView2: TUIMergeMessageDetailRow_Minimalist = .init()
    lazy var contentRowView3: TUIMergeMessageDetailRow_Minimalist = .init()

    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        return view
    }()

    lazy var bottomTipsLabel: UILabel = {
        let label = UILabel()
        label.text = TUISwift.timCommonLocalizableString("TUIKitRelayChatHistory")
        label.textColor = TUISwift.rgb(153, green: 153, blue: 153, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        container.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9")
        container.addSubview(relayTitleLabel)
        contentRowView1.setupView()
        container.addSubview(contentRowView1)
        contentRowView2.setupView()
        container.addSubview(contentRowView2)
        contentRowView3.setupView()
        container.addSubview(contentRowView3)

        separatorView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        container.addSubview(separatorView)

        bottomTipsLabel.text = TUISwift.timCommonLocalizableString("TUIKitRelayChatHistory")
        bottomTipsLabel.textColor = UIColor.tui_color(withHex: "#999999")
        bottomTipsLabel.font = UIFont.systemFont(ofSize: 10)
        container.addSubview(bottomTipsLabel)
    }

    override func updateConstraints() {
        super.updateConstraints()

        relayTitleLabel.sizeToFit()
        relayTitleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(container).offset(10)
            make.width.lessThanOrEqualTo(container)
            make.height.equalTo(relayTitleLabel.font.lineHeight)
            make.top.equalTo(container).offset(10)
        }

        contentRowView1.snp.remakeConstraints { make in
            make.leading.equalTo(relayTitleLabel)
            make.top.equalTo(relayTitleLabel.snp.bottom).offset(3)
            make.trailing.equalTo(container)
            make.height.equalTo(mergeData?.abstractRow1Size.height ?? 0)
        }

        contentRowView2.snp.remakeConstraints { make in
            make.leading.equalTo(relayTitleLabel)
            make.top.equalTo(contentRowView1.snp.bottom).offset(3)
            make.trailing.equalTo(container)
            make.height.equalTo(mergeData?.abstractRow2Size.height ?? 0)
        }

        contentRowView3.snp.remakeConstraints { make in
            make.leading.equalTo(relayTitleLabel)
            make.top.equalTo(contentRowView2.snp.bottom).offset(3)
            make.trailing.equalTo(container)
            make.height.equalTo(mergeData?.abstractRow3Size.height ?? 0)
        }

        var lastView: UIView = contentRowView1
        if let count = mergeData?.abstractSendDetailList.count {
            if count >= 3 {
                lastView = contentRowView3
            } else if count == 2 {
                lastView = contentRowView2
            }
        }

        separatorView.snp.remakeConstraints { make in
            make.leading.equalTo(container).offset(10)
            make.trailing.equalTo(container).offset(-10)
            make.top.equalTo(lastView.snp.bottom).offset(3)
            make.height.equalTo(1)
        }

        bottomTipsLabel.snp.remakeConstraints { make in
            make.leading.equalTo(contentRowView1)
            make.top.equalTo(separatorView.snp.bottom).offset(5)
            make.width.lessThanOrEqualTo(container)
            make.height.equalTo(bottomTipsLabel.font.lineHeight)
        }
    }

    override func fill(with data: TUIMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIMergeMessageCellData else { return }
        mergeData = data
        relayTitleLabel.text = data.title
        if let count = mergeData?.abstractSendDetailList.count {
            switch count {
            case 0:
                break
            case 1:
                contentRowView1.fill(with: data.abstractSendDetailList[0]["sender"], data.abstractSendDetailList[0]["detail"])
                contentRowView1.isHidden = false
                contentRowView2.isHidden = true
                contentRowView3.isHidden = true
            case 2:
                contentRowView1.fill(with: data.abstractSendDetailList[0]["sender"], data.abstractSendDetailList[0]["detail"])
                contentRowView2.fill(with: data.abstractSendDetailList[1]["sender"], data.abstractSendDetailList[1]["detail"])
                contentRowView1.isHidden = false
                contentRowView2.isHidden = false
                contentRowView3.isHidden = true
            default:
                contentRowView1.fill(with: data.abstractSendDetailList[0]["sender"], data.abstractSendDetailList[0]["detail"])
                contentRowView2.fill(with: data.abstractSendDetailList[1]["sender"], data.abstractSendDetailList[1]["detail"])
                contentRowView3.fill(with: data.abstractSendDetailList[2]["sender"], data.abstractSendDetailList[2]["detail"])
                contentRowView1.isHidden = false
                contentRowView2.isHidden = false
                contentRowView3.isHidden = false
            }
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    // MARK: - TUIMessageCellProtocol

    override class func getContentSize(_ data: TUIMessageCellData) -> CGSize {
        guard let mergeCellData = data as? TUIMergeMessageCellData else {
            assertionFailure("data must be kind of TUIMergeMessageCellData")
            return CGSize.zero
        }

        mergeCellData.abstractRow1Size = caculate(data: mergeCellData, index: 0)
        mergeCellData.abstractRow2Size = caculate(data: mergeCellData, index: 1)
        mergeCellData.abstractRow3Size = caculate(data: mergeCellData, index: 2)

        let mergeMessageCellWidthMax = TUISwift.tMergeMessageCell_Width_Max()

        let abstractAttributedString = mergeCellData.abstractAttributedString()
        let rect = abstractAttributedString.boundingRect(with: CGSize(width: mergeMessageCellWidthMax - 20, height: .infinity),
                                                         options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                         context: nil)
        let size = CGSize(width: ceil(rect.width), height: ceil(rect.height) - 10)
        mergeCellData.abstractSize = size
        var height = mergeCellData.abstractRow1Size.height + mergeCellData.abstractRow2Size.height + mergeCellData.abstractRow3Size.height
        let titleFont = UIFont.systemFont(ofSize: 16)
        height = (10 + titleFont.lineHeight + 3) + height + 1 + 5 + 20 + 5 + 3
        return CGSize(width: mergeMessageCellWidthMax, height: height + mergeCellData.msgStatusSize.height)
    }

    class func caculate(data: TUIMergeMessageCellData, index: Int) -> CGSize {
        let abstractSendDetailList: [Dictionary] = data.abstractSendDetailList
        guard abstractSendDetailList.count > index else {
            return CGSizeZero
        }

        guard let senderStr = data.abstractSendDetailList[index]["sender"] else {
            return .zero
        }

        let senderRect = senderStr.boundingRect(with: CGSize(width: 70, height: CGFloat.greatestFiniteMagnitude),
                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                context: nil)

        let abstr = NSMutableAttributedString(string: ":")
        if let detail = data.abstractSendDetailList[index]["detail"] as? NSMutableAttributedString {
            abstr.append(detail)
        }

        let mergeMessageCellWidthMax = TUISwift.tMergeMessageCell_Width_Max()
        let mergeMessageCellHeightMax = TUISwift.tMergeMessageCell_Height_Max()

        let senderWidth = senderRect.width
        let rect = abstr.boundingRect(with: CGSize(width: mergeMessageCellWidthMax - 20 - senderWidth, height: .infinity),
                                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                                      context: nil)

        let size = CGSize(width: mergeMessageCellWidthMax,
                          height: min(mergeMessageCellHeightMax / 3.0, ceil(rect.height)))

        return size
    }
}
