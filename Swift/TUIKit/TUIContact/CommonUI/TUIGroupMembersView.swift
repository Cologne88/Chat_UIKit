import TIMCommon
import UIKit

// MARK: - TUIGroupMembersViewDelegate

@objc protocol TUIGroupMembersViewDelegate: NSObjectProtocol {
    @objc func groupMembersView(_ groupMembersView: TUIGroupMembersView, didSelectGroupMember groupMember: TUIGroupMemberCellData)
    @objc func groupMembersView(_ groupMembersView: TUIGroupMembersView, didLoadMoreData completion: @escaping ([TUIGroupMemberCellData]) -> Void)
}

// MARK: - TUIGroupMembersView

class TUIGroupMembersView: UIView, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var searchBar: UISearchBar?
    var collectionView: UICollectionView?
    var flowLayout: UICollectionViewFlowLayout?
    weak var delegate: TUIGroupMembersViewDelegate?
    var indicatorView: UIActivityIndicatorView?
    private var data: [TUIGroupMemberCellData] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .white
        flowLayout = UICollectionViewFlowLayout()
        flowLayout?.headerReferenceSize = CGSize(width: frame.size.width, height: CGFloat(TGroupMembersController_Margin))
        let cellSize = TUIGroupMemberCell.getSize()
        
        let y = searchBar?.frame.origin.y ?? 0 + (searchBar?.frame.size.height ?? 0)
        collectionView = UICollectionView(frame: CGRect(x: CGFloat(TGroupMembersController_Margin), y: y, width: frame.size.width - CGFloat(2 * TGroupMembersController_Margin), height: frame.size.height - y), collectionViewLayout: flowLayout!)
        collectionView?.register(TUIGroupMemberCell.self, forCellWithReuseIdentifier: TGroupMemberCell_ReuseId)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.backgroundColor = .clear
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(TMessageController_Header_Height), right: 0)
        if let collectionView = collectionView {
            addSubview(collectionView)
        }
        
        indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView?.hidesWhenStopped = true
        collectionView?.addSubview(indicatorView!)
        
        let viewWidth = collectionView?.frame.size.width ?? 0
        let cellWidth = cellSize.width * CGFloat(TGroupMembersController_Row_Count)
        flowLayout?.minimumLineSpacing = (viewWidth - cellWidth) / (CGFloat(TGroupMembersController_Row_Count) - 1)
        flowLayout?.minimumInteritemSpacing = flowLayout?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TGroupMemberCell_ReuseId, for: indexPath) as? TUIGroupMemberCell else {
            return UICollectionViewCell()
        }
        let data = data[indexPath.row]
        cell.data = data
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Implement selection logic if needed
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TUIGroupMemberCell.getSize()
    }
    
    // MARK: - Load

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && (scrollView.contentOffset.y >= scrollView.bounds.origin.y) {
            loadMoreData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton {
            cancelButton.setTitle(TUISwift.timCommonLocalizableString("Cancel"), for: .normal)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        reloadData()
    }
    
    func setData(_ data: [TUIGroupMemberCellData]) {
        self.data = data
        reloadData()
    }
    
    private func reloadData() {
        collectionView?.reloadData()
        collectionView?.layoutIfNeeded()
        indicatorView?.frame = CGRect(x: 0, y: collectionView?.contentSize.height ?? 0, width: collectionView?.bounds.size.width ?? 0, height: CGFloat(TMessageController_Header_Height))
        if (collectionView?.contentSize.height ?? 0) > (collectionView?.frame.size.height ?? 0) {
            indicatorView?.startAnimating()
        } else {
            indicatorView?.stopAnimating()
        }
    }
    
    private func loadMoreData() {
        guard let delegate = delegate, delegate.responds(to: #selector(TUIGroupMembersViewDelegate.groupMembersView(_:didLoadMoreData:))) else {
            var point = collectionView?.contentOffset ?? CGPoint.zero
            point.y -= CGFloat(TMessageController_Header_Height)
            collectionView?.setContentOffset(point, animated: true)
            return
        }
        
        var isLoading = false
        if isLoading {
            return
        }
        isLoading = true
        delegate.groupMembersView(self) { [weak self] moreData in
            isLoading = false
            self?.data.append(contentsOf: moreData)
            var point = self?.collectionView?.contentOffset ?? CGPoint.zero
            point.y -= CGFloat(TMessageController_Header_Height)
            self?.collectionView?.setContentOffset(point, animated: true)
            self?.reloadData()
        }
    }
}
