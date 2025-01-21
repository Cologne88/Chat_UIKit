import Foundation
import UIKit
import ImSDK_Plus
import TUICore
import TIMCommon
import TIMAppKit
import TUIContact
import TUIChat


class LoginController: UIViewController {
    @IBOutlet weak var user: UITextField!
    @IBOutlet weak var logView: UIImageView!
    @IBOutlet weak var loginButton: UIButton!

    private var changeStyleView: UIView?
    private var changeSkinView: UIView?
    private var changeLanguageView: UIView?

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F3F4F5")
        logView.image = TUISwift.tuiDemoDynamicImage("public_login_logo_img", defaultImage: UIImage(named: "public_login_logo"))
        loginButton.backgroundColor = TUISwift.timCommonDynamicColor("primary_theme_color", defaultColor: "#147AFF")
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.setTitle(NSLocalizedString("login", comment: ""), for: .normal)
        
        changeStyleView = createOptionalView(title: NSLocalizedString("ChangeStyle", comment: ""),
                                             leftIcon: TUISwift.tuiDemoDynamicImage("", defaultImage: UIImage(named: "icon_style")),
                                             rightIcon: TUISwift.tuiDemoDynamicImage("login_drop_img", defaultImage: UIImage(named: "icon_drop_arraw")))
        changeStyleView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onChangeStyle)))
        
        changeSkinView = createOptionalView(title: NSLocalizedString("ChangeSkin", comment: ""),
                                            leftIcon: UIImage(named: "icon_skin"),
                                            rightIcon: UIImage(named: "icon_drop_arraw"))
        changeSkinView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onChangeSkin)))
        
        changeLanguageView = createOptionalView(title: NSLocalizedString("CurrentLanguage", comment: ""),
                                                leftIcon: UIImage(named: "icon_language"),
                                                rightIcon: UIImage(named: "icon_drop_arraw"))
        changeLanguageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onChangeLanguage)))
        
        if let changeStyleView = changeStyleView, let changeSkinView = changeSkinView, let changeLanguageView = changeLanguageView {
            view.addSubview(changeStyleView)
            view.addSubview(changeSkinView)
            view.addSubview(changeLanguageView)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            
            self.changeLanguageView?.mm_right()(20)
            if #available(iOS 11.0, *) {
                self.changeLanguageView?.mm_y = 10 + self.view.mm_safeAreaTopGap
            } else {
                self.changeLanguageView?.mm_y = 10
            }
            
            if TUIStyleSelectViewController.isClassicEntrance() {
                self.changeSkinView?.isHidden = false
                self.changeSkinView?.mm_right()(20 + (self.changeLanguageView?.mm_w ?? 0) + 20)
                self.changeSkinView?.mm_y = self.changeLanguageView?.mm_y ?? 0
                
                self.changeStyleView?.mm_right()(40 + (self.changeSkinView?.mm_w ?? 0) + (self.changeLanguageView?.mm_w ?? 0) + 20)
                self.changeStyleView?.mm_y = self.changeLanguageView?.mm_y ?? 0
            } else {
                self.changeSkinView?.isHidden = true
                self.changeStyleView?.mm_right()(20 + (self.changeLanguageView?.mm_w ?? 0) + 20)
                self.changeStyleView?.mm_y = self.changeLanguageView?.mm_y ?? 0
            }
        }
    }

    @objc func onTap() {
        view.endEditing(true)
    }

    @objc func onChangeLanguage() {
        let vc = TUILanguageSelectController()
        vc.delegate = AppDelegate.sharedInstance
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onChangeStyle() {
        let vc = TUIStyleSelectViewController()
        vc.delegate = AppDelegate.sharedInstance as? TUIStyleSelectControllerDelegate
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func onChangeSkin() {
        let vc = TUIThemeSelectController()
        vc.delegate = AppDelegate.sharedInstance
        navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func login(_ sender: Any) {
        view.endEditing(true)
        
        TCLoginModel.sharedInstance.isDirectlyLoginSDK = true
        guard let userid = user.text else { return }
        let userSig = GenerateTestUserSig.genTestUserSig(identifier: userid)
        loginIM(userId: userid, userSig: userSig)
    }

    func loginIM(userId: String, userSig: String) {
        if userId.isEmpty || userSig.isEmpty {
            TUITool.hideToastActivity()
            alertText(NSLocalizedString("TipsLoginErrorWithUserIdfailed", comment: ""))
            return
        }
        TCLoginModel.sharedInstance.saveLoginedInfo(userID: userId, userSig: userSig)
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.loginSDK(userId, userSig: userSig, succ: { [weak self] in
            guard let self = self else { return }
            TUITool.hideToastActivity()
        }, fail: { [weak self] code, msg in
            TUITool.hideToastActivity()
            self?.alertText(String(format: NSLocalizedString("TipsLoginErrorFormat", comment: ""), code, "Please check whether the SDKAPPID and SECRETKEY are correctly configured (GenerateTestUserSig.h)"))
        })
    }

    func alertText(_ str: String) {
        let alert = UIAlertController(title: str, message: nil, preferredStyle: .alert)
        alert.tuitheme_addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: ""), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func createOptionalView(title: String, leftIcon: UIImage?, rightIcon: UIImage?) -> UIView {
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = .gray
        label.isUserInteractionEnabled = true
        contentView.addSubview(label)
        
        let leftIconView = UIImageView()
        leftIconView.image = leftIcon
        leftIconView.isUserInteractionEnabled = true
        contentView.addSubview(leftIconView)
        
        let rightIconView = UIImageView()
        rightIconView.image = rightIcon
        rightIconView.isUserInteractionEnabled = true
        contentView.addSubview(rightIconView)

        leftIconView.mm_width()(18.0)?.mm_height()(18.0)
        leftIconView.mm_x = 0
        leftIconView.mm_centerY = 0.5 * (contentView.mm_h - leftIconView.mm_h)
        
        label.sizeToFit()
        label.mm_x = leftIconView.frame.maxX + 5.0
        label.mm_centerY = leftIconView.mm_centerY
        
        rightIconView.mm_width()(10.0)?.mm_height()(7.0)
        rightIconView.mm_x = label.frame.maxX + 5.0
        rightIconView.mm_centerY = leftIconView.mm_centerY
        
        contentView.mm_w = rightIconView.frame.maxX
        
        return contentView
    }
} 
