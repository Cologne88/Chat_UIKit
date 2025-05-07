import TIMCommon
import UIKit

@objc public protocol TUIFaceVerticalViewDelegate: NSObjectProtocol {
    @objc optional func faceVerticalView(_ faceView: TUIFaceVerticalView, scrollToFaceGroupIndex index: Int)
    @objc optional func faceVerticalView(_ faceView: TUIFaceVerticalView, didSelectItemAtIndexPath indexPath: IndexPath)
    @objc optional func faceVerticalViewDidBackDelete(_ faceView: TUIFaceVerticalView)
    @objc optional func faceVerticalViewClickSendMessageBtn()
}

open class TUIFaceVerticalView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate {
    public var lineView: UIView!
    public var faceCollectionView: UICollectionView!
    public var faceFlowLayout: UICollectionViewFlowLayout!
    public var faceGroups: [TUIFaceGroup] = []
    public var sectionIndexInGroup: [Int] = []
    public var groupIndexInSection: [Int] = []
    public var itemIndexs: [IndexPath: Int] = [:]
    public var floatCtrlView: UIView!
    public weak var delegate: TUIFaceVerticalViewDelegate?

    private var sendButton: UIButton!
    private var deleteButton: UIButton!
    private var hasPreViewShow = false
    private var sectionCount = 0
    private var curGroupIndex = 0

    private lazy var dispalyView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        imageView.contentMode = .scaleToFill
        imageView.backgroundColor = .white
        imageView.addSubview(dispalyImage)
        return imageView
    }()

    private lazy var dispalyImage: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        defaultLayout()
    }

    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")

        faceFlowLayout = TUICollectionRTLFitFlowLayout()
        faceFlowLayout.scrollDirection = .vertical
        faceFlowLayout.minimumLineSpacing = CGFloat(TFaceView_Margin)
        faceFlowLayout.minimumInteritemSpacing = CGFloat(TFaceView_Margin)
        faceFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: CGFloat(TFaceView_Page_Padding), bottom: 0, right: CGFloat(TFaceView_Page_Padding))

        faceCollectionView = UICollectionView(frame: .zero, collectionViewLayout: faceFlowLayout)
        faceCollectionView.register(TUIFaceCell.self, forCellWithReuseIdentifier: "TFaceCell")
        faceCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView")
        faceCollectionView.isPagingEnabled = false
        faceCollectionView.delegate = self
        faceCollectionView.dataSource = self
        faceCollectionView.showsHorizontalScrollIndicator = false
        faceCollectionView.showsVerticalScrollIndicator = false
        faceCollectionView.backgroundColor = backgroundColor
        faceCollectionView.alwaysBounceVertical = true
        addSubview(faceCollectionView)

        lineView = UIView()
        lineView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        addSubview(lineView)

        setupFloatCtrlView()
    }

    private func setupFloatCtrlView() {
        floatCtrlView = UIView()
        addSubview(floatCtrlView)

        sendButton = UIButton(type: .custom)
        sendButton.setTitle(TUISwift.timCommonLocalizableString("Send"), for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        sendButton.addTarget(self, action: #selector(didSelectSendButton(_:)), for: .touchUpInside)
        sendButton.backgroundColor = TUISwift.timCommonDynamicColor("", defaultColor: "#0069F6")
        sendButton.layer.cornerRadius = 2
        floatCtrlView.addSubview(sendButton)

        deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(contentsOfFile: TUISwift.tuiChatFaceImagePath("del_normal")), for: .normal)
        deleteButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        deleteButton.imageView?.contentMode = .scaleAspectFit
        deleteButton.layer.cornerRadius = 2
        deleteButton.addTarget(self, action: #selector(didSelectDeleteButton(_:)), for: .touchUpInside)
        deleteButton.backgroundColor = .white
        floatCtrlView.addSubview(deleteButton)
    }

    private func defaultLayout() {
        lineView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: TUISwift.tLine_Height())
        faceCollectionView.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }

        floatCtrlView.snp.remakeConstraints { make in
            make.trailing.equalTo(self.snp.trailing).offset(-16)
            make.bottom.equalTo(self.snp.bottom).offset(20)
            make.height.equalTo(88)
            make.leading.equalTo(deleteButton.snp.leading)
        }

        sendButton.snp.remakeConstraints { make in
            make.trailing.equalTo(floatCtrlView.snp.trailing)
            make.top.equalTo(floatCtrlView)
            make.height.equalTo(30)
            make.width.equalTo(50)
        }
        deleteButton.snp.remakeConstraints { make in
            make.trailing.equalTo(sendButton.snp.leading).offset(-10)
            make.top.equalTo(floatCtrlView)
            make.height.equalTo(30)
            make.width.equalTo(50)
        }
    }

    open func setData(_ data: [TUIFaceGroup]) {
        faceGroups = data
        defaultLayout()

        sectionIndexInGroup = []
        groupIndexInSection = []
        itemIndexs = [:]

        var sectionIndex = 0
        for (groupIndex, group) in faceGroups.enumerated() {
            sectionIndexInGroup.append(sectionIndex)
            if let itemCount = group.faces?.count {
                let sectionCount = Int(ceil(Double(itemCount) / Double(itemCount)))
                for _ in 0..<sectionCount {
                    groupIndexInSection.append(groupIndex)
                }
                sectionIndex += sectionCount
            }
        }
        sectionCount = sectionIndex

        for curSection in 0..<sectionCount {
            let groupIndex = groupIndexInSection[curSection]
            let groupSectionIndex = sectionIndexInGroup[groupIndex]
            let face = faceGroups[groupIndex]
            if let itemCount = face.faces?.count {
                for itemIndex in 0..<itemCount {
                    let reIndex = itemIndex
                    itemIndexs[IndexPath(row: itemIndex, section: curSection)] = reIndex
                }
            }
        }

        curGroupIndex = 0

        faceCollectionView.reloadData()

        let group = faceGroups[0]
        if !group.isNeedAddInInputBar {
            floatCtrlView.isHidden = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.adjustEmotionsAlpha()
        }
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let groupIndex = groupIndexInSection[section]
        let group = faceGroups[groupIndex]
        return group.faces?.count ?? 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TFaceCell", for: indexPath) as? TUIFaceCell else {
            assertionFailure("Unable to dequeue TUIFaceCell")
            return UICollectionViewCell()
        }

        cell.longPressCallback = { [weak self, weak cell] _ in
            guard let self, let cell else { return }
            if self.hasPreViewShow {
                return
            }
            if let view = TUITool.applicationKeywindow()?.rootViewController?.view {
                self.showDisplayView(displayX: 0, displayY: 0, targetView: view, faceCell: cell)
            }
        }

        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]

        if let count = group.faces?.count, let index = itemIndexs[indexPath], index < count {
            if let data = group.faces?[index] as? TUIFaceCellData {
                cell.setData(data)
            }
        } else {
            cell.setData(TUIFaceCellData())
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let groupIndex = groupIndexInSection[indexPath.section]
        let faces = faceGroups[groupIndex]
        if let count = faces.faces?.count, let index = itemIndexs[indexPath], index < count {
            delegate?.faceVerticalView?(self, didSelectItemAtIndexPath: IndexPath(row: index, section: groupIndex))
        }
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        let padding = CGFloat(TFaceView_Page_Padding) * 2
        let margin = CGFloat(TFaceView_Margin) * CGFloat(group.itemCountPerRow - 1)
        let width = (frame.size.width - padding - margin) / CGFloat(group.itemCountPerRow)
        let height = width + CGFloat(TFaceView_Margin)
        return CGSize(width: width, height: height)
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let group = faceGroups[section]
        if (group.groupName?.count ?? 0) > 0 {
            return CGSize(width: frame.size.width, height: 20)
        } else {
            return CGSize(width: frame.size.width, height: 0)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath)
        headerView.subviews.forEach { $0.removeFromSuperview() }
        let label = UILabel(frame: CGRect(x: CGFloat(TFaceView_Page_Padding), y: 0, width: frame.size.width, height: 17))
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = TUISwift.timCommonDynamicColor("", defaultColor: "#444444")
        headerView.addSubview(label)
        let group = faceGroups[indexPath.section]
        if (group.groupName?.count ?? 0) > 0 {
            label.text = group.groupName
        }
        return headerView
    }

    // MARK: - UIScrollViewDelegate

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let curSection = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        if curSection >= groupIndexInSection.count {
            return
        }
        let groupIndex = groupIndexInSection[curSection]
        let startSection = sectionIndexInGroup[groupIndex]
        if curGroupIndex != groupIndex {
            curGroupIndex = groupIndex
            delegate?.faceVerticalView?(self, scrollToFaceGroupIndex: curGroupIndex)
        }

        if scrollView == faceCollectionView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.adjustEmotionsAlpha()
            }
        }
    }

    func scrollToFaceGroupIndex(_ index: Int) {
        if index >= sectionIndexInGroup.count {
            return
        }
        let start = sectionIndexInGroup[index]
        let curSection = Int(ceil(faceCollectionView.contentOffset.x / faceCollectionView.frame.size.width))
        if curSection > start && curSection < start {
            return
        }
        let rect = CGRect(x: CGFloat(start) * faceCollectionView.frame.size.width, y: 0, width: faceCollectionView.frame.size.width, height: faceCollectionView.frame.size.height)
        faceCollectionView.scrollRectToVisible(rect, animated: false)
        scrollViewDidScroll(faceCollectionView)
    }

    // MARK: - floatCtrlView

    private func adjustEmotionsAlpha() {
        if floatCtrlView.isHidden {
            return
        }
        let buttonGroupRect = floatCtrlView.frame
        let floatingRect = faceCollectionView.convert(buttonGroupRect, from: self)
        for visibleCell in faceCollectionView.visibleCells {
            let cellInCollection = faceCollectionView.convert(visibleCell.frame, to: faceCollectionView)
            let isOverlapping = floatingRect.intersects(cellInCollection)
            if isOverlapping {
                let emojiCenterPoint = CGPoint(x: cellInCollection.midX, y: cellInCollection.midY)
                let containsHalf = floatingRect.contains(emojiCenterPoint)
                visibleCell.alpha = containsHalf ? 0 : 0.5
            } else {
                visibleCell.alpha = 1
            }
        }
    }

    func setFloatCtrlViewAllowSendSwitch(_ isAllow: Bool) {
        deleteButton.isEnabled = isAllow
        sendButton.isEnabled = isAllow
        deleteButton.alpha = isAllow ? 1 : 0.5
        sendButton.alpha = isAllow ? 1 : 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.adjustEmotionsAlpha()
        }
    }

    @objc private func didSelectSendButton(_ btn: UIButton) {
        delegate?.faceVerticalViewClickSendMessageBtn?()
    }

    @objc private func didSelectDeleteButton(_ btn: UIButton) {
        delegate?.faceVerticalViewDidBackDelete?(self)
    }

    private func showDisplayView(displayX: CGFloat, displayY: CGFloat, targetView: UIView, faceCell: TUIFaceCell) {
        hasPreViewShow = true

        let contentViewController = UIViewController()
        contentViewController.view.addSubview(dispalyView)
        dispalyImage.image = faceCell.gifImage
        let dispalyImageX: CGFloat = 5
        let dispalyImageY: CGFloat = 5
        let dispalyImageW = min(faceCell.face.image?.size.width ?? 0, 150)
        let dispalyImageH = min(faceCell.face.image?.size.height ?? 0, 150)

        dispalyView.frame = CGRect(x: displayX, y: displayY, width: dispalyImageW + 10, height: dispalyImageH + 10)
        dispalyImage.frame = CGRect(x: dispalyImageX, y: dispalyImageY, width: dispalyImageH, height: dispalyImageH)

        contentViewController.view.backgroundColor = .clear
        contentViewController.preferredContentSize = CGSize(width: dispalyView.frame.size.width, height: dispalyView.frame.size.height)
        contentViewController.modalPresentationStyle = .popover

        let popoverController = contentViewController.popoverPresentationController
        popoverController?.sourceView = self
        popoverController?.sourceRect = CGRect(x: 0, y: -10, width: frame.size.width, height: 0)
        popoverController?.permittedArrowDirections = .down
        popoverController?.delegate = self
        popoverController?.canOverlapSourceViewRect = false
        mm_viewController?.present(contentViewController, animated: true, completion: nil)
        popoverController?.backgroundColor = .white
    }

    // MARK: - UIPopoverPresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        hasPreViewShow = false
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
