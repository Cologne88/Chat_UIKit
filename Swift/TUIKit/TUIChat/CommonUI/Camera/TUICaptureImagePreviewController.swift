import UIKit
import TIMCommon

class TUICaptureImagePreviewController: UIViewController {
    private var image: UIImage
    private var imageView: UIImageView!
    private var commitButton: UIButton!
    private var cancelButton: UIButton!
    private var lastRect: CGRect = .zero

    var commitBlock: (() -> Void)?
    var cancelBlock: (() -> Void)?

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        self.view.addSubview(imageView)
        self.imageView = imageView
        print("\(image.imageOrientation.rawValue)--\(UIImage.Orientation.up.rawValue)")

        self.commitButton = UIButton(type: .custom)
        let commitImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camer_commit"))
        self.commitButton.setImage(commitImage, for: .normal)
        let commitBGImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camer_commitBg"))
        self.commitButton.setBackgroundImage(commitBGImage, for: .normal)
        self.commitButton.addTarget(self, action: #selector(commitButtonClick(_:)), for: .touchUpInside)
        self.view.addSubview(self.commitButton)

        self.cancelButton = UIButton(type: .custom)
        let cancelButtonBGImage = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath("camera_cancel"))
        self.cancelButton.setBackgroundImage(cancelButtonBGImage, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(cancelButtonClick(_:)), for: .touchUpInside)
        self.view.addSubview(self.cancelButton)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !lastRect.equalTo(self.view.bounds) {
            lastRect = self.view.bounds

            self.imageView.frame = self.view.bounds

            let commitButtonWidth: CGFloat = 80.0
            let buttonDistance = (self.view.bounds.width - 2 * commitButtonWidth) / 3.0
            let commitButtonY = self.view.bounds.height - commitButtonWidth - 50.0
            let commitButtonX = 2 * buttonDistance + commitButtonWidth
            self.commitButton.frame = CGRect(x: commitButtonX, y: commitButtonY, width: commitButtonWidth, height: commitButtonWidth)

            let cancelButtonX = commitButtonWidth
            self.cancelButton.frame = CGRect(x: cancelButtonX, y: commitButtonY, width: commitButtonWidth, height: commitButtonWidth)

            if TUISwift.isRTL() {
                self.commitButton.resetFrameToFitRTL()
                self.cancelButton.resetFrameToFitRTL()
            }
        }
    }

    @objc func commitButtonClick(_ btn: UIButton) {
        commitBlock?()
    }

    @objc func cancelButtonClick(_ btn: UIButton) {
        cancelBlock?()
    }
}
