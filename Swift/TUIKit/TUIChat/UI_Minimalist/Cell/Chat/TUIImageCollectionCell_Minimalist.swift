import Photos
import TIMCommon
import TUICore
import UIKit

class TUIImageCollectionCell_Minimalist: TUIMediaCollectionCell_Minimalist {
    private var thumbImageObservation: NSKeyValueObservation?
    private var largeImageObservation: NSKeyValueObservation?
    private var originImageObservation: NSKeyValueObservation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageObservation?.invalidate()
        thumbImageObservation = nil
        largeImageObservation?.invalidate()
        largeImageObservation = nil
        originImageObservation?.invalidate()
        originImageObservation = nil
    }
    
    func setupViews() {
        imageView = UIImageView()
        imageView.layer.cornerRadius = 5.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        addSubview(imageView)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        downloadBtn = UIButton(type: .custom)
        downloadBtn.contentMode = .scaleToFill
        downloadBtn.setImage(TUISwift.tuiChatCommonBundleImage("download"), for: .normal)
        downloadBtn.addTarget(self, action: #selector(onDownloadBtnClick), for: .touchUpInside)
        addSubview(downloadBtn)
        
        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(onSelectMedia))
        addGestureRecognizer(tap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        downloadBtn.snp.makeConstraints { make in
            make.width.equalTo(31)
            make.height.equalTo(31)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-48)
        }
    }
    
    @objc func onDownloadBtnClick() {
        guard let image = imageView.image else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, _ in
            DispatchQueue.main.async {
                if success {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitPictureSavedSuccess"))
                } else {
                    TUITool.makeToast(TUISwift.timCommonLocalizableString("TUIKitPictureSavedFailed"))
                }
            }
        }
    }
    
    @objc func onSelectMedia() {
        delegate?.onCloseMedia?(cell: self)
    }
    
    override func fill(with data: TUIMessageCellData) {
        super.fill(with: data)
        guard let data = data as? TUIImageMessageCellData else { return }
        
        imageView.image = nil
        if originImageFirst(data) {
            return
        }
        
        if largeImageSecond(data) {
            return
        }
        
        if data.thumbImage == nil {
            data.downloadImage(type: .thumb)
        }
        if data.thumbImage != nil && data.largeImage == nil {
            data.downloadImage(type: .large)
        }
        
        thumbImageObservation = data.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.imageView.image = thumbImage
        }
        
        largeImageObservation = data.observe(\.largeImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let largeImage = change.newValue else { return }
            self.imageView.image = largeImage
        }
    }
    
    func largeImageSecond(_ data: TUIImageMessageCellData) -> Bool {
        var isExist = false
        _ = data.getImagePath(type: .large, isExist: &isExist)
        if isExist {
            data.decodeImage(type: .large)
            fillLargeImage(with: data)
        }
        return isExist
    }

    func originImageFirst(_ data: TUIImageMessageCellData) -> Bool {
        var isExist = false
        _ = data.getImagePath(type: .origin, isExist: &isExist)
        if isExist {
            data.decodeImage(type: .origin)
            fillOriginImage(with: data)
        }
        return isExist
    }
    
    func fillOriginImage(with data: TUIImageMessageCellData) {
        originImageObservation = data.observe(\.originImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let originImage = change.newValue else { return }
            self.imageView.image = originImage
        }
    }

    func fillLargeImage(with data: TUIImageMessageCellData) {
        largeImageObservation = data.observe(\.largeImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let largeImage = change.newValue else { return }
            self.imageView.image = largeImage
        }
    }

    func fillThumbImage(with data: TUIImageMessageCellData) {
        thumbImageObservation = data.observe(\.thumbImage, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let thumbImage = change.newValue else { return }
            self.imageView.image = thumbImage
        }
    }
}
