import TIMCommon
import TUICore
import UIKit

class TUIVoiceReplyQuoteView_Minimalist: TUITextReplyQuoteView_Minimalist {
    var iconView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView = UIImageView()
        iconView.image = TUISwift.tuiChatCommonBundleImage("message_voice_receiver_normal")
        addSubview(iconView)

        textLabel.numberOfLines = 1
        textLabel.font = UIFont.systemFont(ofSize: 10.0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)
        guard let myData = data as? TUIVoiceReplyQuoteViewData else {
            return
        }
        iconView.image = myData.icon
        textLabel.numberOfLines = 1
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()
        iconView.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(15)
            make.height.equalTo(15)
        }

        textLabel.sizeToFit()
        textLabel.snp.remakeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(3)
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).offset(-3)
            make.height.equalTo(textLabel.font.lineHeight)
        }
    }
}
