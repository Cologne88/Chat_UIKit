import SnapKit
import TIMCommon
import UIKit

@objc protocol TUIMenuViewDelegate_Minimalist: NSObjectProtocol {
    @objc optional func menuViewDidSelectItemsAtIndex(_ menuView: TUIMenuView_Minimalist, _ index: Int)
    @objc optional func menuViewDidSendMessage(_ menuView: TUIMenuView_Minimalist)
}

class TUIMenuView_Minimalist: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var menuCollectionView: UICollectionView!
    var menuFlowLayout: UICollectionViewFlowLayout!
    weak var delegate: TUIMenuViewDelegate_Minimalist?

    private var _data: [TUIMenuCellData] = []
    var data: [TUIMenuCellData] {
        get {
            return _data
        }
        set {
            _data = newValue
            menuCollectionView.reloadData()
            defaultLayout()
            menuCollectionView.layoutIfNeeded()
            let indexPath = IndexPath(item: 0, section: 0)
            menuCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = .clear
        menuFlowLayout = TUICollectionRTLFitFlowLayout()
        menuFlowLayout.scrollDirection = .horizontal
        menuFlowLayout.minimumLineSpacing = 0
        menuFlowLayout.minimumInteritemSpacing = 0

        menuCollectionView = UICollectionView(frame: .zero, collectionViewLayout: menuFlowLayout)
        menuCollectionView.register(TUIMenuCell_Minimalist.self, forCellWithReuseIdentifier: "TMenuCell")
        menuCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TMenuLineCell")
        menuCollectionView.delegate = self
        menuCollectionView.dataSource = self
        menuCollectionView.showsHorizontalScrollIndicator = false
        menuCollectionView.showsVerticalScrollIndicator = false
        menuCollectionView.backgroundColor = backgroundColor
        menuCollectionView.alwaysBounceHorizontal = true
        addSubview(menuCollectionView)
    }

    func defaultLayout() {
        menuCollectionView.snp.remakeConstraints { make in
            make.leading.equalTo(0)
            make.trailing.equalTo(self)
            make.height.equalTo(40)
            make.centerY.equalTo(self)
        }
    }

    func sendUpInside(_ sender: UIButton) {
        delegate?.menuViewDidSendMessage?(self)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count * 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row % 2 == 0 {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TMenuCell", for: indexPath) as? TUIMenuCell_Minimalist {
                cell.setData(data[indexPath.row / 2])
                return cell
            }
            return UICollectionViewCell()
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TMenuLineCell", for: indexPath)
            cell.backgroundColor = .clear
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row % 2 != 0 {
            return
        }
        for i in 0..<data.count {
            let data = data[i]
            data.isSelected = (i == indexPath.row / 2)
        }
        collectionView.reloadData()
        delegate?.menuViewDidSelectItemsAtIndex?(self, indexPath.row / 2)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row % 2 == 0 {
            let wh = collectionView.frame.size.height
            return CGSize(width: wh, height: wh)
        } else {
            return CGSize(width: TUISwift.tLine_Height(), height: collectionView.frame.size.height)
        }
    }

    func scrollTo(_ index: Int) {
        for i in 0..<data.count {
            let data = data[i]
            data.isSelected = (i == index)
        }
        menuCollectionView.reloadData()
    }
}
