import ImSDK_Plus
import TIMCommon
import UIKit

class TUIReplyPreviewBar: UIView {
    var onClose: TUIInputPreviewBarCallback?

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 143 / 255.0, green: 150 / 255.0, blue: 160 / 255.0, alpha: 1 / 1.0)
        return titleLabel
    }()

    lazy var closeButton: UIButton = {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(TUISwift.tuiChatCommonBundleImage("icon_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(self.onClose(_:)), for: .touchUpInside)
        closeButton.sizeToFit()
        return closeButton
    }()

    let timElemTypeFile = 6
    var previewData: TUIReplyPreviewData? {
        didSet {
            guard let previewData = previewData else { return }

            let abstract = TUIReplyPreviewData.displayAbstract(type: previewData.type, abstract: previewData.msgAbstract ?? "", withFileName: true, isRisk: false)
            self.titleLabel.text = "\(previewData.sender ?? ""): \(abstract)".getLocalizableStringWithFaceContent()
            self.titleLabel.lineBreakMode = (previewData.type == .ELEM_TYPE_FILE) ? .byTruncatingMiddle : .byTruncatingTail
        }
    }

    var previewReferenceData: TUIReferencePreviewData? {
        didSet {
            guard let previewReferenceData = previewReferenceData else { return }

            let abstract = TUIReferencePreviewData.displayAbstract(type: previewReferenceData.type, abstract: previewReferenceData.msgAbstract ?? "", withFileName: true, isRisk: false)
            self.titleLabel.text = "\(previewReferenceData.sender ?? ""): \(abstract)".getLocalizableStringWithFaceContent()
            self.titleLabel.lineBreakMode = (previewReferenceData.type == .ELEM_TYPE_FILE) ? .byTruncatingMiddle : .byTruncatingTail
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")
        addSubview(self.titleLabel)
        addSubview(self.closeButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.closeButton.mm_width(16).mm_height(16)
        self.closeButton.mm_centerY = self.mm_centerY
        self.closeButton.mm_right(16.0)

        self.titleLabel.mm_x = 16.0
        self.titleLabel.mm_y = 10
        self.titleLabel.mm_w = self.closeButton.mm_x - 10 - 16
        self.titleLabel.mm_h = self.mm_h - 20
    }

    @objc private func onClose(_ closeButton: UIButton) {
        self.onClose?()
    }
}

class TUIReferencePreviewBar: TUIReplyPreviewBar {
    override func layoutSubviews() {
        super.layoutSubviews()

        closeButton.mm_right(16.0)
        closeButton.frame = CGRectMake(closeButton.frame.origin.x, (frame.size.height - 16) * 0.5, 16, 16)

        titleLabel.mm_x = 16.0
        titleLabel.mm_y = 10
        titleLabel.mm_w = closeButton.mm_x - 10 - 16
        titleLabel.mm_h = mm_h - 20
    }
}
