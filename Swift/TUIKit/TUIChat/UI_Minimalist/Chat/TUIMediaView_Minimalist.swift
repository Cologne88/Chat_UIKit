import ImSDK_Plus
import TIMCommon
import UIKit

class TUIMediaView_Minimalist: UIView {
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

        coverView = UIView(frame: bounds)
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
        menuCollectionView?.register(TUIImageCollectionCell_Minimalist.self, forCellWithReuseIdentifier: "TImageMessageCell")
        menuCollectionView?.register(TUIVideoCollectionCell_Minimalist.self, forCellWithReuseIdentifier: "TVideoMessageCell")
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

extension TUIMediaView_Minimalist: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, TUIMediaCollectionCellDelegate_Minimalist {
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider?.mediaCellData.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let data = dataProvider?.mediaCellData[indexPath.row] as? TUIMessageCellData,
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseId, for: indexPath) as? TUIMediaCollectionCell_Minimalist
        {
            cell.delegate = self
            cell.fill(with: data)
            return cell
        }
        return UICollectionViewCell()
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
        if let videoCell = cell as? TUIVideoCollectionCell_Minimalist {
            videoCell.stopVideoPlayAndSave()
        }
    }

    // MARK: - TUIMediaCollectionCellDelegate

    func onCloseMedia(cell: TUIMediaCollectionCell_Minimalist) {
        onClose?()
        removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: kDisableAllRotationOrientationNotification), object: nil)
    }
}
