// TUICallingHistoryViewController.swift

import UIKit
import TUICore

public class TUICallingHistoryViewController: UIViewController {
    var viewWillAppearClosure:(Bool)->Void?
    var callsVC:Observable<UIViewController?> = Observable(UIViewController())
    var isMimimalist: Bool = false
    private var settingCallsVc: UIViewController?

    public static func createCallingHistoryViewController(isMimimalist: Bool) -> TUICallingHistoryViewController? {
        var param: [String: Any] = [:]
        if isMimimalist {
            param["TUICore_TUICallingObjectFactory_RecordCallsVC_UIStyle"] = "TUICore_TUICallingObjectFactory_RecordCallsVC_UIStyle_Minimalist"
        } else {
            param["TUICore_TUICallingObjectFactory_RecordCallsVC_UIStyle"] = "TUICore_TUICallingObjectFactory_RecordCallsVC_UIStyle_Classic"
        }
        
        if let settingCallsVc = TUICore.createObject("TUICore_TUICallingObjectFactory", key: "TUICore_TUICallingObjectFactory_RecordCallsVC", param: param) as? UIViewController {
            return TUICallingHistoryViewController(callsVC: settingCallsVc, isMimimalist: isMimimalist)
        } else {
            return nil
        }
    }

    init(callsVC: UIViewController, isMimimalist: Bool) {
        self.settingCallsVc = callsVC
        self.isMimimalist = isMimimalist
        self.viewWillAppearClosure = {(Bool) in}
        
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
        viewWillAppearClosure(false)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewWillAppearClosure(true)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if let callsVC = settingCallsVc {
            self.callsVC.value = callsVC
            addChild(callsVC)
            view.addSubview(callsVC.view)
        }
    }
}
