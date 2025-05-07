import UIKit

public class TUISecondConfirmBtnInfo: NSObject {
    public var title: String = ""
    public var click: (() -> Void)?
    
    public override init() {
        super.init()
    }

    public init(tile: String, click: (() -> Void)? = nil) {
        self.title = tile
        self.click = click
    }
}

public class TUISecondConfirm {
    private static var secondWindow: UIWindow?
    private static var cancelBtnInfo: TUISecondConfirmBtnInfo?
    private static var confirmBtnInfo: TUISecondConfirmBtnInfo?

    public static func show(title: String, cancelBtnInfo: TUISecondConfirmBtnInfo, confirmBtnInfo: TUISecondConfirmBtnInfo) {
        self.cancelBtnInfo = cancelBtnInfo
        self.confirmBtnInfo = confirmBtnInfo

        secondWindow = UIWindow(frame: UIScreen.main.bounds)
        secondWindow?.windowLevel = UIWindow.Level.alert - 1
        secondWindow?.backgroundColor = UIColor.clear
        secondWindow?.isHidden = false

        if #available(iOS 13.0, *) {
            for windowScene in UIApplication.shared.connectedScenes {
                if let windowScene = windowScene as? UIWindowScene, windowScene.activationState == .foregroundActive {
                    secondWindow?.windowScene = windowScene
                    break
                }
            }
        }

        let backgroundView = UIView(frame: secondWindow!.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        secondWindow?.addSubview(backgroundView)

        let confirmView = UIView()
        confirmView.backgroundColor = UIColor(named: "second_confirm_bg_color") ?? UIColor.white
        confirmView.layer.cornerRadius = 13
        confirmView.layer.masksToBounds = true
        secondWindow?.addSubview(confirmView)
        confirmView.frame = CGRect(x: 32, y: (secondWindow!.frame.height - 183) / 2, width: secondWindow!.frame.width - 64, height: 183)

        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: confirmView.frame.width, height: 123))
        titleLabel.text = title
        titleLabel.textColor = UIColor(named: "second_confirm_title_color") ?? UIColor.black
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        confirmView.addSubview(titleLabel)

        let line1 = UIView(frame: CGRect(x: 0, y: titleLabel.frame.maxY, width: titleLabel.frame.width, height: 0.5))
        line1.backgroundColor = UIColor(named: "second_confirm_line_color") ?? UIColor.lightGray
        confirmView.addSubview(line1)

        let cancelBtn = UIButton(type: .custom)
        cancelBtn.frame = CGRect(x: 0, y: line1.frame.maxY, width: line1.frame.width / 2, height: confirmView.frame.height - line1.frame.maxY)
        cancelBtn.setTitle(cancelBtnInfo.title, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelBtn.setTitleColor(UIColor(named: "second_confirm_cancel_btn_title_color") ?? UIColor.black, for: .normal)
        cancelBtn.addTarget(self, action: #selector(onCancelBtnClick), for: .touchUpInside)
        confirmView.addSubview(cancelBtn)

        let line2 = UIView(frame: CGRect(x: cancelBtn.frame.maxX, y: cancelBtn.frame.minY, width: 0.5, height: cancelBtn.frame.height))
        line2.backgroundColor = UIColor(named: "second_confirm_line_color") ?? UIColor.lightGray
        confirmView.addSubview(line2)

        let confirmBtn = UIButton(type: .custom)
        confirmBtn.frame = CGRect(x: line2.frame.maxX, y: cancelBtn.frame.minY, width: cancelBtn.frame.width, height: cancelBtn.frame.height)
        confirmBtn.setTitle(confirmBtnInfo.title, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        confirmBtn.setTitleColor(UIColor(named: "second_confirm_confirm_btn_title_color") ?? UIColor.red, for: .normal)
        confirmBtn.addTarget(self, action: #selector(onConfirmBtnClick), for: .touchUpInside)
        confirmView.addSubview(confirmBtn)
    }

    @objc private static func onCancelBtnClick() {
        cancelBtnInfo?.click?()
        dismiss()
    }

    @objc private static func onConfirmBtnClick() {
        confirmBtnInfo?.click?()
        dismiss()
    }

    private static func dismiss() {
        secondWindow = nil
        cancelBtnInfo = nil
        confirmBtnInfo = nil
    }
}
