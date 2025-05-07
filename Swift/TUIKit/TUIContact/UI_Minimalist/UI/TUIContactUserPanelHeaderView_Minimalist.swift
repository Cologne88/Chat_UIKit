//  TUIContactUserPanelHeaderView_Minimalist.swift
//  TUIContact

import TIMCommon
import UIKit

class TUIContactPanelCell_Minimalist: UICollectionViewCell {
    private let imageView = UIImageView(frame: .zero)
    private let nameLabel = UILabel(frame: .zero)
    private let imageIcon = UIImageView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleToFill
        addSubview(imageView)

        imageIcon.image = UIImage.safeImage(TUISwift.tuiContactImagePath_Minimalist("contact_info_del_icon"))
        addSubview(imageIcon)

        nameLabel.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        addSubview(nameLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.masksToBounds = true

        nameLabel.sizeToFit()

        imageView.frame = CGRect(x: (bounds.size.width - TUISwift.kScale390(40)) * 0.5, y: 0, width: TUISwift.kScale390(40), height: TUISwift.kScale390(40))
        if TUIConfig.default().avatarType == .TAvatarTypeRounded {
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = imageView.frame.size.height / 2
        } else if TUIConfig.default().avatarType == .TAvatarTypeRadiusCorner {
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = TUIConfig.default().avatarCornerRadius
        }
        imageIcon.frame = CGRect(x: imageView.frame.origin.x + imageView.frame.size.width - TUISwift.kScale390(12), y: imageView.frame.origin.y, width: TUISwift.kScale390(12), height: TUISwift.kScale390(12))

        nameLabel.frame = CGRect(x: 0, y: imageView.frame.size.height + TUISwift.kScale390(2), width: nameLabel.frame.size.width, height: TUISwift.kScale390(17))
        nameLabel.center.x = imageView.center.x
        nameLabel.textAlignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
    }

    func fillWithData(_ model: TUICommonContactSelectCellData) {
        imageView.sd_setImage(with: model.avatarUrl, placeholderImage: UIImage.safeImage(TUISwift.timCommonImagePath("default_c2c_head")), options: .highPriority)
        nameLabel.text = model.title
    }
}

class TUIContactUserPanelHeaderView_Minimalist: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var clickCallback: (() -> Void)?
    var selectedUsers = [TUICommonContactSelectCellData]()
    var topStartPosition: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        var topPadding: CGFloat = 44.0
        if #available(iOS 11.0, *) {
            if let window = TUITool.applicationKeywindow() {
                topPadding = window.safeAreaInsets.top
            }
        }
        topPadding = max(26, topPadding)
        topStartPosition = 0
        selectedUsers = []
        userPanel.isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        userPanel.frame = bounds
    }

    lazy var userPanel: UICollectionView = {
        let layout = TUICollectionRTLFitFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TUIContactPanelCell_Minimalist.self, forCellWithReuseIdentifier: "TUIContactPanelCell_Minimalist")
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = true
        }
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentMode = .scaleAspectFit
        collectionView.isScrollEnabled = true
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        return collectionView
    }()

    // MARK: UICollectionViewDelegate

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedUsers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = "TUIContactPanelCell_Minimalist"
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TUIContactPanelCell_Minimalist else {
            return UICollectionViewCell()
        }
        if indexPath.row < selectedUsers.count {
            cell.fillWithData(selectedUsers[indexPath.row])
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let model = selectedUsers[indexPath.row]
        let size = model.title.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: TUISwift.kScale390(12))], context: nil).size
        return CGSize(width: max(TUISwift.kScale390(60), size.width), height: TUISwift.kScale390(60))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: TUISwift.kScale390(16), bottom: 0, right: TUISwift.kScale390(16))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if indexPath.row < selectedUsers.count {
            let model = selectedUsers[indexPath.row]
            model.isSelected.toggle()
            selectedUsers.remove(at: indexPath.row)
            clickCallback?()
        }
    }
}
