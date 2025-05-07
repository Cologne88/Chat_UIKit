import ImSDK_Plus
import TIMCommon
import UIKit

class TUIMediaView: UIView {
    var onClose: (() -> Void)?

    let ANIMATION_TIME = 0.2

    var dataProvider: TUIMessageMediaDataProvider?
    private var menuCollectionView: UICollectionView?
    private var saveBackgroundImage: UIImage?
    private var saveShadowImage: UIImage?
    private var imageView: UIImageView?
    private var thumbImage: UIImage?
    private var coverView: UIView?
    private var mediaView: UIView?
    private var thumbFrame: CGRect = .zero
    private var currentMessage: V2TIMMessage?
    private var mediaObservation: NSKeyValueObservation?
    private var currentVisibleIndexPath: IndexPath = .init(row: 0, section: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        mediaObservation = nil
    }

    func setThumb(_ thumb: UIImageView, frame: CGRect) {
        thumbImage = thumb.image
        thumbFrame = frame
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .clear

        coverView = UIView(frame: CGRectMake(0, 0, TUISwift.screen_Width() * 3, TUISwift.screen_Height() * 3))
        coverView?.backgroundColor = .black
        addSubview(coverView!)

        mediaView = UIView(frame: thumbFrame)
        mediaView?.backgroundColor = .clear
        addSubview(mediaView!)

        let menuFlowLayout = TUICollectionRTLFitFlowLayout()
        menuFlowLayout.scrollDirection = .horizontal
        menuFlowLayout.minimumLineSpacing = 0
        menuFlowLayout.minimumInteritemSpacing = 0
        menuFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        menuCollectionView = UICollectionView(frame: mediaView!.bounds, collectionViewLayout: menuFlowLayout)
        menuCollectionView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        menuCollectionView?.register(TUIImageCollectionCell.self, forCellWithReuseIdentifier: "TImageMessageCell")
        menuCollectionView?.register(TUIVideoCollectionCell.self, forCellWithReuseIdentifier: "TVideoMessageCell")
        menuCollectionView?.isPagingEnabled = true
        menuCollectionView?.delegate = self
        menuCollectionView?.dataSource = self
        menuCollectionView?.showsHorizontalScrollIndicator = false
        menuCollectionView?.showsVerticalScrollIndicator = false
        menuCollectionView?.alwaysBounceHorizontal = true
        menuCollectionView?.decelerationRate = .fast
        menuCollectionView?.backgroundColor = .clear
        menuCollectionView?.isHidden = true
        mediaView?.addSubview(menuCollectionView!)

        imageView = UIImageView(frame: mediaView!.bounds)
        imageView?.layer.cornerRadius = 5.0
        imageView?.layer.masksToBounds = true
        imageView?.contentMode = .scaleAspectFit
        imageView?.backgroundColor = .clear
        imageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView?.image = thumbImage
        mediaView?.addSubview(imageView!)

        UIView.animate(withDuration: ANIMATION_TIME) {
            self.mediaView?.frame = self.bounds
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ANIMATION_TIME) {
            self.imageView?.removeFromSuperview()
            self.menuCollectionView?.isHidden = false
        }

        NotificationCenter.default.post(name: NSNotification.Name(kEnableAllRotationOrientationNotification), object: nil)
        setupRotationNotifications()
    }

    func setupRotationNotifications() {
        if #available(iOS 16.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDeviceOrientationChange(_:)),
                name: NSNotification.Name("TUIMessageMediaViewDeviceOrientationChangeNotification"),
                object: nil
            )
        } else {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onDeviceOrientationChange(_:)),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        }
    }

    @objc func onDeviceOrientationChange(_ notification: Notification) {
        UIView.performWithoutAnimation {
            applyRotationFrame()
        }
    }

    func applyRotationFrame() {
        frame = CGRect(x: 0, y: 0, width: TUISwift.screen_Width(), height: TUISwift.screen_Height())
        coverView?.frame = CGRect(x: 0, y: 0, width: TUISwift.screen_Width() * 3, height: TUISwift.screen_Height() * 3)
        mediaView?.frame = frame
        mediaView?.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        menuCollectionView?.frame = mediaView?.frame ?? CGRect.zero
        menuCollectionView?.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        menuCollectionView?.setNeedsLayout()
        imageView?.frame = mediaView?.frame ?? CGRect.zero
        imageView?.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)

        menuCollectionView?.performBatchUpdates({
            // Perform any updates if needed
        }, completion: { [weak self] finished in
            guard let self else { return }
            if finished {
                self.menuCollectionView?.scrollToItem(at: self.currentVisibleIndexPath, at: .left, animated: false)
            }
        })
    }

    func setCurMessage(_ curMessage: V2TIMMessage) {
        currentMessage = curMessage
        let model = TUIChatConversationModel()
        model.userID = curMessage.userID
        model.groupID = curMessage.groupID
        dataProvider = TUIMessageMediaDataProvider(conversationModel: model)
        dataProvider?.loadMediaWithMessage(currentMessage!)

        guard let dataProvider = dataProvider else { return }
        mediaObservation = self.dataProvider?.observe(\.mediaCellData, options: [.new, .initial]) { [weak self] _, _ in
            guard let self = self, dataProvider.mediaCellData.count > 0 else { return }
            self.menuCollectionView?.reloadData()
            for i in 0 ..< dataProvider.mediaCellData.count {
                let data = dataProvider.mediaCellData[i]
                if data.innerMessage?.msgID == self.currentMessage?.msgID {
                    self.currentVisibleIndexPath = IndexPath(row: i, section: 0)
                    self.menuCollectionView?.scrollToItem(at: IndexPath(row: i, section: 0), at: .left, animated: false)
                    return
                }
            }
        }
    }

    func setCurMessage(_ curMessage: V2TIMMessage, allMessages: [V2TIMMessage]) {
        currentMessage = curMessage

        var media = [TUIMessageCellData]()
        for message in allMessages {
            if let data = TUIMessageMediaDataProvider.getMediaCellData(message) {
                media.append(data)
            }
        }

        dataProvider = TUIMessageMediaDataProvider(conversationModel: nil)
        dataProvider?.mediaCellData = media

        menuCollectionView?.reloadData()
        if let dataProvider = dataProvider {
            for i in 0 ..< dataProvider.mediaCellData.count {
                let data = dataProvider.mediaCellData[i]
                if data.innerMessage?.msgID == currentMessage?.msgID {
                    menuCollectionView?.scrollToItem(at: IndexPath(row: i, section: 0), at: .left, animated: false)
                    return
                }
            }
        }
    }
}

extension TUIMediaView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, TUIMediaCollectionCellDelegate {
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider?.mediaCellData.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let data = dataProvider?.mediaCellData[indexPath.row] as? TUIMessageCellData else {
            return UICollectionViewCell()
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseId, for: indexPath) as! TUIMediaCollectionCell
        cell.delegate = self
        cell.fill(with: data)

        if let videoCell = cell as? TUIVideoCollectionCell {
            videoCell.reloadAllView()
        } else if let imageCell = cell as? TUIImageCollectionCell {
            imageCell.reloadAllView()
        }

        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        menuCollectionView?.collectionViewLayout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let attrs = collectionView.layoutAttributesForItem(at: currentVisibleIndexPath) else {
            return proposedContentOffset
        }
        let newOriginForOldIndex = attrs.frame.origin
        return newOriginForOldIndex.x == 0 ? proposedContentOffset : newOriginForOldIndex
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.size.width / 2), y: scrollView.frame.size.height / 2)
        if let indexPath = menuCollectionView?.indexPathForItem(at: center) {
            currentVisibleIndexPath = indexPath
        }

        let indexPaths = menuCollectionView?.indexPathsForVisibleItems
        guard let indexPath = indexPaths?.first else { return }

        if let data = dataProvider?.mediaCellData[indexPath.row] {
            currentMessage = data.innerMessage
        }

        guard let dataProvider = dataProvider else { return }
        if indexPath.row <= dataProvider.pageCount / 2 {
            dataProvider.loadOlderMedia()
        }

        if indexPath.row >= dataProvider.mediaCellData.count - dataProvider.pageCount / 2 {
            dataProvider.loadNewerMedia()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let indexPaths = menuCollectionView?.indexPathsForVisibleItems
        guard let indexPath = indexPaths?.first else { return }
        let cell = menuCollectionView?.cellForItem(at: indexPath)
        if let videoCell = cell as? TUIVideoCollectionCell {
            videoCell.stopVideoPlayAndSave()
        }
    }

    // MARK: - TUIMediaCollectionCellDelegate

    func onCloseMedia(cell: TUIMediaCollectionCell) {
        onClose?()
        removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kDisableAllRotationOrientationNotification), object: nil)
    }
}
