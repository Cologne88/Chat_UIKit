import TIMCommon
import TUICore
import UIKit

class TUIGroupNoticeController: UIViewController {
    var groupID: String?
    var onNoticeChanged: (() -> Void)?

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.textAlignment = TUISwift.isRTL() ? .right : .left
        textView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        textView.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        textView.font = UIFont.systemFont(ofSize: 17)
        return textView
    }()

    private weak var rightButton: UIButton?
    private lazy var dataProvider: TUIGroupNoticeDataProvider = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        view.addSubview(textView)

        let rightBtn = UIButton(type: .custom)
        rightBtn.setTitleColor(TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000"), for: .normal)
        rightBtn.setTitleColor(TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000"), for: .selected)
        rightBtn.setTitle(TUISwift.timCommonLocalizableString("Edit"), for: .normal)
        rightBtn.setTitle(TUISwift.timCommonLocalizableString("Done"), for: .selected)
        rightBtn.sizeToFit()
        rightBtn.addTarget(self, action: #selector(onClickRight(_:)), for: .touchUpInside)
        rightButton = rightBtn
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBtn)
        rightButton?.isHidden = true

        let titleLabel = UILabel()
        titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitGroupNotice")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        titleLabel.textColor = TUISwift.timCommonDynamicColor("nav_title_text_color", defaultColor: "#000000")
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        dataProvider.groupID = groupID
        dataProvider.getGroupInfo { [weak self] in
            guard let self = self else { return }
            self.textView.text = self.dataProvider.groupInfo?.notification
            self.textView.isEditable = false
            self.rightButton?.isHidden = !self.dataProvider.canEditNotice()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textView.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dataProvider.canEditNotice() == true && textView.text.isEmpty {
            onClickRight(rightButton)
        }
    }

    @objc private func onClickRight(_ button: UIButton?) {
        guard let button = button else { return }
        if button.isSelected {
            textView.isEditable = false
            textView.resignFirstResponder()
            updateNotice()
        } else {
            textView.isEditable = true
            textView.becomeFirstResponder()
        }
        button.isSelected.toggle()
    }

    private func updateNotice() {
        dataProvider.updateNotice(textView.text) { [weak self] code, desc in
            guard let self = self else { return }
            if code != 0 {
                TUITool.makeToastError(code, msg: desc)
                return
            }
            self.onNoticeChanged?()
        }
    }
}
