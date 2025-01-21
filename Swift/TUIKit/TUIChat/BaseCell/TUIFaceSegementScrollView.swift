import TIMCommon
import UIKit

class TUIFaceSegementScrollView: UIView, UIScrollViewDelegate {
    var onScrollCallback: ((Int) -> Void)?
//    var pageScrollView: UIScrollView
    private var items: [TUIFaceGroup] = []
    private var viewArray: [TUIFaceVerticalView] = []

    lazy var pageScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        addSubview(scrollView)
        return scrollView
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == pageScrollView {
            let p = Int(pageScrollView.contentOffset.x / frame.size.width)
            onScrollCallback?(p)
        }
    }

    // MARK: - Func

    func setItems(_ items: [TUIFaceGroup], delegate: TUIFaceVerticalViewDelegate) {
        self.items = items
        pageScrollView.subviews.forEach { $0.removeFromSuperview() }
        viewArray.removeAll()

        for (i, indexGroup) in items.enumerated() {
            let faceView = TUIFaceVerticalView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: pageScrollView.frame.size.height))
            let recentGroup: TUIFaceGroup? = indexGroup.recent
            if let recent = recentGroup {
                faceView.setData([recent, indexGroup])
            } else {
                faceView.setData([indexGroup])
            }

            faceView.frame = CGRect(x: CGFloat(i) * frame.size.width, y: 0, width: frame.size.width, height: pageScrollView.frame.size.height)
            faceView.delegate = delegate
            pageScrollView.addSubview(faceView)
            viewArray.append(faceView)
        }
        pageScrollView.contentSize = CGSize(width: CGFloat(viewArray.count) * frame.size.width, height: pageScrollView.frame.size.height)
        if TUISwift.isRTL() {
            pageScrollView.transform = CGAffineTransform(rotationAngle: .pi)
            pageScrollView.subviews.forEach { $0.transform = CGAffineTransform(rotationAngle: .pi) }
        }
    }

    func updateContainerView() {
        pageScrollView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)

        for (i, view) in viewArray.enumerated() {
            view.frame = CGRect(x: CGFloat(i) * pageScrollView.frame.size.width, y: 0, width: pageScrollView.frame.size.width, height: pageScrollView.frame.size.height)
        }

        pageScrollView.contentSize = CGSize(width: CGFloat(viewArray.count) * frame.size.width, height: pageScrollView.frame.size.height)
    }

    func setPageIndex(_ index: Int) {
        let p = CGPoint(x: pageScrollView.frame.size.width * CGFloat(index), y: 0)
        pageScrollView.setContentOffset(p, animated: false)
    }

    func setAllFloatCtrlViewAllowSendSwitch(_ isAllow: Bool) {
        viewArray.forEach { $0.setFloatCtrlViewAllowSendSwitch(isAllow) }
    }

    func updateRecentView() {
        guard let service = TIMCommonMediator.share().getObject(TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol else { return }
        guard let faceView = viewArray.first else { return }
        guard let indexGroup = items.first else { return }
        if let recent = service.getChatPopMenuRecentQueue() as? TUIFaceGroup {
            indexGroup.recent = recent
        }
        indexGroup.recent.rowCount = 1
        indexGroup.recent.itemCountPerRow = 8
        indexGroup.recent.groupName = TUISwift.timCommonLocalizableString("TUIChatFaceGroupRecentEmojiName")
        let recentGroup: TUIFaceGroup? = indexGroup.recent
        if indexGroup.isNeedAddInInputBar, let recent = recentGroup {
            faceView.setData([recent, indexGroup])
        } else {
            faceView.setData([indexGroup])
        }
    }
}
