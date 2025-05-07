import TIMCommon
import TUICore
import UIKit

class TUIFileViewController: UIViewController, UIDocumentInteractionControllerDelegate {
    var data: TUIFileMessageCellData?
    var dismissClickCallback: (() -> Void)?

    private var image: UIImageView?
    private var name: UILabel?
    private var progress: UILabel?
    private var button: UIButton?
    private var document: UIDocumentInteractionController?
    private var downladProgressObservation: NSKeyValueObservation?

    deinit {
        downladProgressObservation = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("File")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.textAlignment = TUISwift.isRTL() ? .right : .left
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        // left
        let defaultImage = UIImage.safeImage(TUISwift.tuiChatImagePath("back"))
        let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let formatImage = TUISwift.timCommonDynamicImage("nav_back_img", defaultImage: defaultImage).rtlImageFlippedForRightToLeftLayoutDirection()
        leftButton.addTarget(self, action: #selector(onBack(_:)), for: .touchUpInside)
        leftButton.setImage(formatImage, for: .normal)
        let leftItem = UIBarButtonItem(customView: leftButton)
        navigationItem.leftBarButtonItem = leftItem

        let frame = CGRect(x: (view.frame.size.width - 80) * 0.5,
                           y: CGFloat(TUISwift.navBar_Height() + CGFloat(TUISwift.statusBar_Height()) + 50),
                           width: 80, height: 80)
        image = UIImageView(frame: frame)
        image!.contentMode = .scaleAspectFit
        image!.image = UIImage.safeImage(TUISwift.tuiChatImagePath("msg_file"))
        view.addSubview(image!)

        name = UILabel(frame: CGRect(x: 0, y: image!.frame.origin.y + image!.frame.size.height + 20, width: view.frame.size.width, height: 40))
        name?.textColor = .black
        name?.font = UIFont.systemFont(ofSize: 15)
        name?.textAlignment = .center
        name?.text = data?.fileName
        view.addSubview(name!)

        button = UIButton(frame: CGRect(x: 100, y: name!.frame.origin.y + name!.frame.size.height + 20, width: view.frame.size.width - 200, height: 40))
        button?.setTitleColor(.white, for: .normal)
        button?.backgroundColor = UIColor(red: 44 / 255.0, green: 145 / 255.0, blue: 247 / 255.0, alpha: 1.0)
        button?.layer.cornerRadius = 5
        button?.layer.masksToBounds = true
        button?.addTarget(self, action: #selector(onOpen(_:)), for: .touchUpInside)

        view.addSubview(button!)

        guard let data = data else { return }
        downladProgressObservation = data.observe(\.downladProgress, options: [.new, .initial]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            if progress < 100 && progress > 0 {
                self.button?.setTitle(TUISwift.timCommonLocalizableString("TUIKitDownloadProgressFormat").replacingOccurrences(of: "%ld", with: "\(progress)"), for: .normal)
            } else {
                self.button?.setTitle(TUISwift.timCommonLocalizableString("TUIKitOpenWithOtherApp"), for: .normal)
            }
        }

        if data.isLocalExist() {
            button?.setTitle(TUISwift.timCommonLocalizableString("TUIKitOpenWithOtherApp"), for: .normal)
        } else {
            button?.setTitle(TUISwift.timCommonLocalizableString("Download"), for: .normal)
        }
    }

    @objc func onOpen(_ sender: Any) {
        guard let data = data else { return }
        var isExist = false
        let path = data.getFilePath(&isExist)
        if let path = path, isExist {
            let url = URL(fileURLWithPath: path)
            document = UIDocumentInteractionController(url: url)
            document?.delegate = self
            document?.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        } else {
            data.downloadFile()
        }
    }

    @objc func onBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }

    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.frame
    }

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
