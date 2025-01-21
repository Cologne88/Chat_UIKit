import TIMCommon
import TUICore
import UIKit

class TUIVideoReplyQuoteView: TUIImageReplyQuoteView {
    var playView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        playView = UIImageView()
        playView.image = TUISwift.tuiChatCommonBundleImage("play_normal")
        playView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        addSubview(playView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    override func updateConstraints() {
        super.updateConstraints()

        guard let myData = data as? TUIVideoReplyQuoteViewData else { return }

        imageView.snp.remakeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            if CGSizeEqualToSize(CGSize.zero, myData.imageSize) {
                make.size.equalTo(CGSize(width: 60, height: 60))
            } else {
                make.size.equalTo(myData.imageSize)
            }
        }

        playView.snp.remakeConstraints { make in
            make.size.equalTo(CGSize(width: 30, height: 30))
            make.center.equalTo(imageView)
        }
    }

    override func fill(with data: TUIReplyQuoteViewData) {
        super.fill(with: data)
    }
}
