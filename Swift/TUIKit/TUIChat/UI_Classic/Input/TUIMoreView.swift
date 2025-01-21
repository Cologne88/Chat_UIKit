import TIMCommon
import TUICore
import UIKit

protocol TUIMoreViewDelegate: AnyObject {
    func moreView(_ moreView: TUIMoreView, didSelectMoreCell cell: TUIInputMoreCell)
}

class TUIMoreView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var lineView: UIView!
    var moreCollectionView: UICollectionView!
    var moreFlowLayout: UICollectionViewFlowLayout!
    var pageControl: UIPageControl!
    weak var delegate: TUIMoreViewDelegate?
    
    private var data: [TUIInputMoreCellData] = []
    private var itemIndexs: [IndexPath: Int] = [:]
    private var sectionCount: Int = 0
    private var itemsInSection: Int = 0
    private var rowCount: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = TUISwift.tuiChatDynamicColor("chat_input_controller_bg_color", defaultColor: "#EBF0F6")
        
        moreFlowLayout = UICollectionViewFlowLayout()
        moreFlowLayout.scrollDirection = .horizontal
        moreFlowLayout.minimumLineSpacing = 0
        moreFlowLayout.minimumInteritemSpacing = 0.0
        moreFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: CGFloat(TMoreView_Section_Padding), bottom: 0, right: CGFloat(TMoreView_Section_Padding))
        
        moreCollectionView = UICollectionView(frame: .zero, collectionViewLayout: moreFlowLayout)
        moreCollectionView.register(TUIInputMoreCell.self, forCellWithReuseIdentifier: TMoreCell_ReuseId)
        moreCollectionView.isPagingEnabled = true
        moreCollectionView.delegate = self
        moreCollectionView.dataSource = self
        moreCollectionView.showsHorizontalScrollIndicator = false
        moreCollectionView.showsVerticalScrollIndicator = false
        moreCollectionView.backgroundColor = backgroundColor
        moreCollectionView.alwaysBounceHorizontal = true
        addSubview(moreCollectionView)
        
        lineView = UIView()
        lineView.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        addSubview(lineView)
        
        pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = TUISwift.tuiChatDynamicColor("chat_face_page_control_current_color", defaultColor: "#7D7D7D")
        pageControl.pageIndicatorTintColor = TUISwift.tuiChatDynamicColor("chat_face_page_control_color", defaultColor: "#DEDEDE")
        addSubview(pageControl)
    }
    
    private func defaultLayout() {
        let cellSize = TUIInputMoreCell.getSize()
        let cellHeight = cellSize.height * CGFloat(rowCount)
        let cellMargin = CGFloat(TMoreView_Margin * Int32(rowCount - 1))
        let collectionHeight = cellHeight + cellMargin
        
        lineView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: TLine_Heigh)
        moreCollectionView.frame = CGRect(x: 0, y: lineView.frame.origin.y + lineView.frame.size.height + CGFloat(TMoreView_Margin), width: self.frame.size.width, height: collectionHeight)
        
        if sectionCount > 1 {
            pageControl.frame = CGRect(x: 0, y: moreCollectionView.frame.origin.y + moreCollectionView.frame.size.height, width: self.frame.size.width, height: CGFloat(TMoreView_Page_Height))
            pageControl.isHidden = false
        } else {
            pageControl.isHidden = true
        }
        
        if rowCount > 1 {
            moreFlowLayout.minimumInteritemSpacing = (moreCollectionView.frame.size.height - cellSize.height * CGFloat(rowCount)) / CGFloat(rowCount - 1)
        }
        
        let margin = TMoreView_Section_Padding
        let moreViewWidth = cellSize.width * CGFloat(TMoreView_Column_Count) + 2 * CGFloat(margin)
        let margins = moreCollectionView.frame.size.width - moreViewWidth
        let column = CGFloat(TMoreView_Column_Count - 1)
        let spacing = CGFloat(margins) / column
        moreFlowLayout.minimumLineSpacing = spacing
        moreFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: CGFloat(margin), bottom: 0, right: CGFloat(margin))
        
        var height = moreCollectionView.frame.origin.y + moreCollectionView.frame.size.height + CGFloat(TMoreView_Margin)
        if sectionCount > 1 {
            height = pageControl.frame.origin.y + pageControl.frame.size.height
        }
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func setData(_ data: [TUIInputMoreCellData]) {
        self.data = data
        
        if data.count > TMoreView_Column_Count {
            rowCount = 2
        } else {
            rowCount = 1
        }
        itemsInSection = Int(TMoreView_Column_Count) * rowCount
        sectionCount = Int(ceil(Double(data.count) / Double(itemsInSection)))
        pageControl.numberOfPages = sectionCount
        
        itemIndexs = [:]
        for curSection in 0..<sectionCount {
            for itemIndex in 0..<itemsInSection {
                let row = itemIndex % rowCount
                let column = itemIndex / rowCount
                let reIndex = Int(TMoreView_Column_Count) * row + column + curSection * itemsInSection
                itemIndexs[IndexPath(row: itemIndex, section: curSection)] = reIndex
            }
        }
        
        moreCollectionView.reloadData()
        defaultLayout()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsInSection
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TMoreCell_ReuseId, for: indexPath) as! TUIInputMoreCell
        let index = itemIndexs[indexPath] ?? 0
        let data = index >= self.data.count ? nil : self.data[index]
        cell.fill(with: data)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
        if let delegate = delegate, let cell = cell as? TUIInputMoreCell {
            delegate.moreView(self, didSelectMoreCell: cell)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TUIInputMoreCell.getSize()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.x
        let page = contentOffset / scrollView.frame.size.width
        if Int(page * 10) % 10 == 0 {
            pageControl.currentPage = Int(page)
        }
    }
}
