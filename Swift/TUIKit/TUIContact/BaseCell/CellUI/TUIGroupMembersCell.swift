import TIMCommon
import TUICore
import UIKit

protocol TUIGroupMembersCellDelegate: AnyObject {
    func groupMembersCell(_ cell: TUIGroupMembersCell, didSelectItemAtIndex index: Int)
}

class TUIGroupMembersCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var memberCollectionView: UICollectionView!
    var memberFlowLayout: UICollectionViewFlowLayout!
    weak var delegate: TUIGroupMembersCellDelegate?
    var data: TUIGroupMembersCellData? {
        didSet {
            updateLayout()
            memberCollectionView.reloadData()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        memberFlowLayout = UICollectionViewFlowLayout()
        
        let cellSize = TUIGroupMemberCell.getSize()
        memberFlowLayout.itemSize = cellSize
        memberFlowLayout.minimumInteritemSpacing = (TUISwift.screen_Width() - cellSize.width * CGFloat(TGroupMembersCell_Column_Count) - 2 * 20) / CGFloat(TGroupMembersCell_Column_Count - 1)
        memberFlowLayout.minimumLineSpacing = CGFloat(TGroupMembersCell_Margin)
        memberFlowLayout.sectionInset = UIEdgeInsets(top: CGFloat(TGroupMembersCell_Margin), left: 20, bottom: CGFloat(TGroupMembersCell_Margin), right: 20)
        
        memberCollectionView = UICollectionView(frame: .zero, collectionViewLayout: memberFlowLayout)
        memberCollectionView.register(TUIGroupMemberCell.self, forCellWithReuseIdentifier: TGroupMemberCell_ReuseId)
        memberCollectionView.collectionViewLayout = memberFlowLayout
        memberCollectionView.delegate = self
        memberCollectionView.dataSource = self
        memberCollectionView.showsHorizontalScrollIndicator = false
        memberCollectionView.showsVerticalScrollIndicator = false
        memberCollectionView.backgroundColor = backgroundColor
        contentView.addSubview(memberCollectionView)
        separatorInset = UIEdgeInsets(top: 0, left: CGFloat(TGroupMembersCell_Margin), bottom: 0, right: 0)
        selectionStyle = .none
    }
    
    private func updateLayout() {
        guard let data = data else { return }
        let height = TUIGroupMembersCell.getHeight(data)
        memberCollectionView.frame = CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: height)
    }
    
    static func getHeight(_ data: TUIGroupMembersCellData) -> CGFloat {
        guard data.members.count > 0 else { return 0 }
        var row = Int(ceil(Double(data.members.count) / Double(TGroupMembersCell_Column_Count)))
        if row > TGroupMembersCell_Row_Count {
            row = Int(TGroupMembersCell_Row_Count)
        }
        let margin = (row + 1) * Int(TGroupMembersCell_Margin)
        let height = Double(row) * Double(TUIGroupMemberCell.getSize().height) + Double(margin)
        return CGFloat(height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.members.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TGroupMemberCell_ReuseId, for: indexPath) as! TUIGroupMemberCell
        if let data = data?.members[indexPath.item] as? TUIGroupMemberCellData {
            cell.data = data
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate {
            delegate.groupMembersCell(self, didSelectItemAtIndex: indexPath.section * Int(TGroupMembersCell_Column_Count) + indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return TUIGroupMemberCell.getSize()
    }
}
