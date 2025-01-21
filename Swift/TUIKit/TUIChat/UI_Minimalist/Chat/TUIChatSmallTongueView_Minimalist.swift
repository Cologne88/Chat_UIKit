import TIMCommon
import TUICore
import UIKit

@objc class TUIChatSmallTongue_Minimalist: NSObject {
    var type: TUIChatSmallTongueType = .none
    var parentView: UIView?
    var unreadMsgCount: Int = 0
    var atMsgSeqs: [Int] = []
}

@objc protocol TUIChatSmallTongueViewDelegate_Minimalist: NSObjectProtocol {
    @objc optional func onChatSmallTongueClick(_ tongue: TUIChatSmallTongue_Minimalist)
}

class TUIChatSmallTongueView_Minimalist: UIView {
    weak var delegate: TUIChatSmallTongueViewDelegate_Minimalist?
    private var tongue: TUIChatSmallTongue_Minimalist?
    private var imageView: UIImageView?
    private var label: UILabel?
    let kTongueFontSize: CGFloat = 14

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // shadow
        layer.shadowColor = TUISwift.rgb(0, green: 0, blue: 0, alpha: 0.15).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 2
        clipsToBounds = false

        // backgroundView
        let backgroudView = UIImageView(frame: bounds)
        addSubview(backgroudView)
        backgroudView.mm_fill()
        backgroudView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        var bkImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("small_tongue_bk"))
        bkImage = bkImage.rtl_imageFlippedForRightToLeftLayoutDirection()
        var ei = NSCoder.uiEdgeInsets(for: "{5,12,5,5}")
        ei = rtlEdgeInsetsWithInsets(ei)
        backgroudView.image = bkImage.resizableImage(withCapInsets: ei, resizingMode: .stretch)

        // tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)
    }

    @objc private func onTap() {
        guard let tongue = tongue else { return }
        delegate?.onChatSmallTongueClick?(tongue)
    }

    func setTongue(_ tongue: TUIChatSmallTongue_Minimalist?) {
        self.tongue = tongue
        if imageView == nil {
            imageView = UIImageView()
            addSubview(imageView!)
        }

        imageView!.image = TUIChatSmallTongueView_Minimalist.getTongueImage(tongue)
        imageView!.mm_width()(TUISwift.kScale390(18))?.mm_height()(TUISwift.kScale390(18))?.mm_left()(TUISwift.kScale390(18))?.mm_top()(TUISwift.kScale390(5))

        if label == nil {
            label = UILabel()
            label?.font = UIFont.systemFont(ofSize: kTongueFontSize)
            addSubview(label!)
        }

        if let text = TUIChatSmallTongueView_Minimalist.getTongueText(tongue), let label = label {
            label.isHidden = false
            label.text = text
            label.textAlignment = .center
            label.textColor = TUISwift.tuiChatDynamicColor("chat_drop_down_color", defaultColor: "#147AFF")
            label.mm_width()(TUISwift.kScale390(16))?.mm_height()(TUISwift.kScale390(20))?.mm_top()(imageView!.mm_b + TUISwift.kScale390(2))?.mm__centerX()(imageView!.mm_centerX)
        } else {
            label?.isHidden = true
        }
    }

    static func getTongueWidth(_ tongue: TUIChatSmallTongue_Minimalist?) -> CGFloat {
        return TUISwift.kScale390(54)
    }

    static func getTongueHeight(_ tongue: TUIChatSmallTongue_Minimalist?) -> CGFloat {
        guard let tongue = tongue else { return 0 }
        switch tongue.type {
        case .scrollToBoom:
            return TUISwift.kScale390(29)
        case .receiveNewMsg, .someoneAt:
            return TUISwift.kScale390(47)
        default:
            return 0
        }
    }

    static func getTongueText(_ tongue: TUIChatSmallTongue_Minimalist?) -> String? {
        guard let tongue = tongue else { return nil }
        switch tongue.type {
        case .scrollToBoom:
            return nil
        case .receiveNewMsg:
            return "\(tongue.unreadMsgCount > 99 ? 99 : tongue.unreadMsgCount)"
        case .someoneAt:
            return "\(tongue.atMsgSeqs.count > 99 ? 99 : tongue.atMsgSeqs.count)"
        default:
            return nil
        }
    }

    static func getTongueImage(_ tongue: TUIChatSmallTongue_Minimalist?) -> UIImage? {
        guard let tongue = tongue else { return nil }
        switch tongue.type {
        case .scrollToBoom, .receiveNewMsg:
            return TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("small_tongue_scroll_to_boom"))
        case .someoneAt:
            return TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("small_tongue_someone_at_me"))
        default:
            return nil
        }
    }
}

class TUIChatSmallTongueManager_Minimalist {
    private static var gTongueView: TUIChatSmallTongueView_Minimalist?
    private static var gTongue: TUIChatSmallTongue_Minimalist?

    static func showTongue(_ tongue: TUIChatSmallTongue_Minimalist, delegate:
        TUIChatSmallTongueViewDelegate_Minimalist?)
    {
        if let gTongue = gTongue,
           tongue.type == gTongue.type,
           tongue.parentView == gTongue.parentView,
           tongue.unreadMsgCount == gTongue.unreadMsgCount,
           tongue.atMsgSeqs == gTongue.atMsgSeqs,
           !(TUIChatSmallTongueManager_Minimalist.gTongueView?.isHidden ?? false)
        {
            return
        }
        gTongue = tongue

        if let gTongueView = gTongueView {
            gTongueView.removeFromSuperview()
        } else {
            gTongueView = TUIChatSmallTongueView_Minimalist()
        }

        let tongueWidth = TUIChatSmallTongueView_Minimalist.getTongueWidth(gTongue)
        let tongueHeight = TUIChatSmallTongueView_Minimalist.getTongueHeight(gTongue)

        if TUISwift.isRTL() {
            let frame = CGRect(x: TUISwift.kScale390(16),
                               y: tongue.parentView!.mm_h - TUISwift.bottom_SafeHeight() - TUISwift.tTextView_Height() - 20 - tongueHeight,
                               width: tongueWidth,
                               height: tongueHeight)
            gTongueView!.frame = frame
        } else {
            let frame = CGRect(x: tongue.parentView!.mm_w - TUISwift.kScale390(54),
                               y: tongue.parentView!.mm_h - TUISwift.bottom_SafeHeight() - TUISwift.tTextView_Height() - 20 - tongueHeight,
                               width: tongueWidth,
                               height: tongueHeight)
            gTongueView!.frame = frame
        }

        gTongueView!.delegate = delegate
        gTongueView!.setTongue(gTongue)
        tongue.parentView?.addSubview(gTongueView!)
    }

    static func removeTongue(type: TUIChatSmallTongueType) {
        if type != gTongue?.type {
            return
        }
        removeTongue()
    }

    static func removeTongue() {
        gTongue = nil
        gTongueView?.removeFromSuperview()
        gTongueView = nil
    }

    static func hideTongue(_ isHidden: Bool) {
        gTongueView?.isHidden = isHidden
    }
}
