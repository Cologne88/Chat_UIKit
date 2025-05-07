import TIMCommon
import UIKit

@objc protocol TUIFaceViewDelegate: AnyObject {
    @objc optional func faceView(_ faceView: TUIFaceView, scrollToFaceGroupIndex index: Int)
    @objc optional func faceView(_ faceView: TUIFaceView, didSelectItemAtIndexPath indexPath: IndexPath)
    @objc optional func faceViewDidBackDelete(_ faceView: TUIFaceView)
}

open class TUIFaceView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var lineView: UIView!
    public var faceCollectionView: UICollectionView!
    public var faceFlowLayout: UICollectionViewFlowLayout!
    public var pageControl: UIPageControl!
    public var faceGroups: [TUIFaceGroup] = []
    private var sectionIndexInGroup: [Int] = []
    private var pageCountInGroup: [Int] = []
    public var groupIndexInSection: [Int] = []
    public var itemIndexs: [IndexPath: Int] = [:]
    weak var delegate: TUIFaceViewDelegate?

    private var sectionCount = 0
    private var curGroupIndex = 0

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")

        faceFlowLayout = TUICollectionRTLFitFlowLayout()
        faceFlowLayout.scrollDirection = .horizontal
        faceFlowLayout.minimumLineSpacing = CGFloat(TFaceView_Margin)
        faceFlowLayout.minimumInteritemSpacing = CGFloat(TFaceView_Margin)
        faceFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: CGFloat(TFaceView_Page_Padding), bottom: 0, right: CGFloat(TFaceView_Page_Padding))

        faceCollectionView = UICollectionView(frame: .zero, collectionViewLayout: faceFlowLayout)
        faceCollectionView.register(TUIFaceCell.self, forCellWithReuseIdentifier: "TFaceCell")
        faceCollectionView.isPagingEnabled = true
        faceCollectionView.delegate = self
        faceCollectionView.dataSource = self
        faceCollectionView.showsHorizontalScrollIndicator = false
        faceCollectionView.showsVerticalScrollIndicator = false
        faceCollectionView.backgroundColor = backgroundColor
        faceCollectionView.alwaysBounceHorizontal = true
        addSubview(faceCollectionView)

        lineView = UIView()
        lineView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        addSubview(lineView)

        pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = TUISwift.tuiChatDynamicColor("chat_face_page_control_current_color", defaultColor: "#7D7D7D")
        pageControl.pageIndicatorTintColor = TUISwift.tuiChatDynamicColor("chat_face_page_control_color", defaultColor: "#DEDEDE")
        pageControl.isUserInteractionEnabled = false
        addSubview(pageControl)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        defaultLayout()
    }

    private func defaultLayout() {
        lineView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: TUISwift.tLine_Height())
        pageControl.frame = CGRect(x: 0, y: frame.size.height - CGFloat(TFaceView_Page_Height), width: frame.size.width, height: CGFloat(TFaceView_Page_Height))
        let y = lineView.frame.origin.y + lineView.frame.size.height + CGFloat(TFaceView_Margin)
        let height = frame.size.height - pageControl.frame.size.height - lineView.frame.size.height - 2 * CGFloat(TFaceView_Margin)
        faceCollectionView.frame = CGRect(x: 0, y: y, width: frame.size.width, height: height)
    }

    open func setData(_ data: [TUIFaceGroup]) {
        faceGroups = data
        defaultLayout()

        sectionIndexInGroup = []
        groupIndexInSection = []
        itemIndexs = [:]
        pageCountInGroup = []

        var sectionIndex = 0
        for (groupIndex, group) in faceGroups.enumerated() {
            sectionIndexInGroup.append(sectionIndex)
            let itemCount = group.rowCount * group.itemCountPerRow
            if let count = group.faces?.count {
                sectionCount = Int(ceil(Double(count) / Double(itemCount - (group.needBackDelete ? 1 : 0))))
                pageCountInGroup.append(sectionCount)
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
            let itemCount = face.rowCount * face.itemCountPerRow - (face.needBackDelete ? 1 : 0)
            let groupSection = curSection - groupSectionIndex
            for itemIndex in 0..<itemCount {
                let row = itemIndex % face.rowCount
                let column = itemIndex / face.rowCount
                let count = groupSection * itemCount
                let reIndex = face.itemCountPerRow * row + column + count
                itemIndexs[IndexPath(row: Int(itemIndex), section: curSection)] = Int(reIndex)
            }
        }

        curGroupIndex = 0
        if !pageCountInGroup.isEmpty {
            pageControl.numberOfPages = pageCountInGroup[0]
        }
        faceCollectionView.reloadData()
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let groupIndex = groupIndexInSection[section]
        let group = faceGroups[groupIndex]
        return Int(group.rowCount * group.itemCountPerRow)
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TFaceCell", for: indexPath) as? TUIFaceCell {
            let groupIndex = groupIndexInSection[indexPath.section]
            let group = faceGroups[groupIndex]
            let itemCount = group.rowCount * group.itemCountPerRow
            if indexPath.row == itemCount - 1 && group.needBackDelete {
                let data = TUIFaceCellData()
                data.path = TUISwift.tuiChatFaceImagePath("del_normal")
                cell.setData(data)
                cell.face.image = cell.face.image?.rtlImageFlippedForRightToLeftLayoutDirection()
            } else {
                if let index = itemIndexs[indexPath], index < (group.faces?.count ?? 0) {
                    if let data = group.faces?[index] as? TUIFaceCellData {
                        cell.setData(data)
                    }
                } else {
                    cell.setData(TUIFaceCellData())
                }
            }
            return cell
        }
        return UICollectionViewCell()
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let groupIndex = groupIndexInSection[indexPath.section]
        let faces = faceGroups[groupIndex]
        let itemCount = faces.rowCount * faces.itemCountPerRow
        if indexPath.row == itemCount - 1 && faces.needBackDelete {
            delegate?.faceViewDidBackDelete?(self)
        } else {
            if let index = itemIndexs[indexPath], index < (faces.faces?.count ?? 0) {
                delegate?.faceView?(self, didSelectItemAtIndexPath: IndexPath(row: index, section: groupIndex))
            }
        }
    }

    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        let padding = CGFloat(TFaceView_Page_Padding) * 2
        let margin = CGFloat(TFaceView_Margin) * CGFloat(group.itemCountPerRow - 1)
        let width = (frame.size.width - padding - margin) / CGFloat(group.itemCountPerRow)
        let height = (collectionView.frame.size.height - CGFloat(TFaceView_Margin) * CGFloat(group.rowCount - 1)) / CGFloat(group.rowCount)
        return CGSize(width: width, height: height)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let curSection = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        if curSection >= groupIndexInSection.count {
            return
        }
        let groupIndex = groupIndexInSection[curSection]
        let startSection = sectionIndexInGroup[groupIndex]
        let pageCount = pageCountInGroup[groupIndex]
        if curGroupIndex != groupIndex {
            curGroupIndex = groupIndex
            pageControl.numberOfPages = pageCount
            delegate?.faceView?(self, scrollToFaceGroupIndex: curGroupIndex)
        }
        pageControl.currentPage = curSection - startSection
    }

    func scrollToFaceGroupIndex(_ index: Int) {
        if index >= sectionIndexInGroup.count {
            return
        }
        let start = sectionIndexInGroup[index]
        let count = pageCountInGroup[index]
        let curSection = Int(ceil(faceCollectionView.contentOffset.x / faceCollectionView.frame.size.width))
        if curSection > start && curSection < start + count {
            return
        }
        let rect = CGRect(x: CGFloat(start) * faceCollectionView.frame.size.width, y: 0, width: faceCollectionView.frame.size.width, height: faceCollectionView.frame.size.height)
        faceCollectionView.scrollRectToVisible(rect, animated: false)
        scrollViewDidScroll(faceCollectionView)
    }
}
