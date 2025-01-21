import TIMCommon
import UIKit

class TTextField: UITextField {
    var margin: Int = 0

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let margin = CGFloat(self.margin)
        let inset = CGRect(x: bounds.origin.x + margin, y: bounds.origin.y, width: bounds.size.width - margin, height: bounds.size.height)
        return inset
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let margin = CGFloat(self.margin)
        let inset = CGRect(x: bounds.origin.x + margin, y: bounds.origin.y, width: bounds.size.width - margin, height: bounds.size.height)
        return inset
    }
}

class TUITextEditController: UIViewController {
    var inputTextField: UITextField?
    @objc dynamic var textValue: String?

    init(text: String?) {
        self.textValue = text
        super.init(nibName: nil, bundle: nil)
        self.edgesForExtendedLayout = []
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: TUISwift.timCommonLocalizableString("Save"),
                                                                 style: .plain,
                                                                 target: self,
                                                                 action: #selector(self.onSave))
        self.view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")

        let inputTextField = TTextField(frame: .zero)
        inputTextField.text = self.textValue?.trimmingCharacters(in: .illegalCharacters)
        inputTextField.margin = 10
        inputTextField.backgroundColor = TUISwift.timCommonDynamicColor("search_textfield_bg_color", defaultColor: "#FEFEFE")
        inputTextField.frame = CGRect(x: 0, y: 10, width: self.view.frame.size.width, height: 40)
        inputTextField.clearButtonMode = .whileEditing
        self.view.addSubview(inputTextField)
        self.inputTextField = inputTextField
    }

    @objc func onSave() {
        self.textValue = self.inputTextField?.text?.trimmingCharacters(in: .illegalCharacters)
        self.navigationController?.popViewController(animated: true)
    }
}
