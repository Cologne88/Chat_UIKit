//
//  TUIIMIntroductionViewController.m
//  TUIKitDemo
//
//  Created by lynxzhang on 2022/2/9.
//  Copyright © 2022 Tencent. All rights reserved.
//


import UIKit
import TUICore
import TIMCommon

class TUIIMIntroductionViewController: UIViewController {

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = UIColor.white

        let imLogo = UIImageView(frame: CGRect(x: TUISwift.kScale390(34), y: 56, width: 62, height: 31))
        imLogo.image = TUISwift.tuiDemoDynamicImage("", defaultImage:UIImage(named: TUISwift.tuiDemoImagePath("im_logo")))
        view.addSubview(imLogo)

        let imLabel = UILabel(frame: CGRect(x: imLogo.frame.origin.x, y: imLogo.frame.maxY + 10, width: 100, height: 36))
        imLabel.text = TUISwift.timCommonLocalizableString("TIMAppTencentCloudIM")
        imLabel.font = UIFont.systemFont(ofSize: 24)
        imLabel.textColor = UIColor.black
        view.addSubview(imLabel)

        let introductionLabel = UILabel(frame: CGRect(x: TUISwift.kScale390(31), y: imLabel.frame.maxY + 32, width: view.frame.width - imLabel.frame.origin.x * 2, height: 144))
        introductionLabel.text = TUISwift.timCommonLocalizableString("TIMAppWelcomeToChatDetails")
        introductionLabel.numberOfLines = 0
        introductionLabel.font = UIFont.systemFont(ofSize: 16)
        introductionLabel.textColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        view.addSubview(introductionLabel)

        let startX = TUISwift.kScale390(30)
        let startY = introductionLabel.frame.maxY + 30
        let widthSpace = TUISwift.kScale390(10)
        let heightSpace: CGFloat = 10
        let viewWidth = (TUISwift.screen_Width() - startX * 2 - widthSpace) / 2
        let viewHeight: CGFloat = 82

        for i in 0..<4 {
            let introductionView = UIView(frame: CGRect(x: startX + (viewWidth + widthSpace) * CGFloat(i % 2), y: startY + (viewHeight + heightSpace) * CGFloat(i / 2), width: viewWidth, height: viewHeight))
            let label = UILabel(frame: CGRect(x: TUISwift.kScale390(20), y: 14, width: introductionView.frame.width - TUISwift.kScale390(20) * 2, height: 35))
            label.textColor = UIColor(red: 0/255, green: 110/255, blue: 255/255, alpha: 1)
            label.font = UIFont.systemFont(ofSize: 24)

            let subLabel = UILabel(frame: CGRect(x: label.frame.origin.x, y: label.frame.maxY + 3, width: label.frame.width, height: 24))
            subLabel.textColor = UIColor.black
            subLabel.font = UIFont.systemFont(ofSize: 8)
            subLabel.numberOfLines = 0

            switch i {
            case 0:
                label.text = TUISwift.timCommonLocalizableString("TIMApp1Minute")
                subLabel.text = TUISwift.timCommonLocalizableString("TIMAppRunDemo")
            case 1:
                label.text = TUISwift.timCommonLocalizableString("TIMApp10000+")
                subLabel.text = TUISwift.timCommonLocalizableString("TIMAppCustomers")
            case 2:
                label.text = "99.99%"
                subLabel.text = TUISwift.timCommonLocalizableString("TIMAppMessagingSuccess")
            case 3:
                label.text = TUISwift.timCommonLocalizableString("TIMApp1Billion+")
                subLabel.text = TUISwift.timCommonLocalizableString("TIMAppActiveUsers")
            default:
                break
            }

            introductionView.addSubview(label)
            introductionView.addSubview(subLabel)
            view.addSubview(introductionView)
        }

        let understoodBtn = UIButton(type: .custom)
        understoodBtn.backgroundColor = UIColor(red: 16/255, green: 78/255, blue: 245/255, alpha: 1)
        let btnWidth: CGFloat = 202
        let btnHeight: CGFloat = 42
        understoodBtn.frame = CGRect(x: (view.frame.width - btnWidth) / 2, y: view.frame.height - btnHeight - TUISwift.bottom_SafeHeight() - 100, width: btnWidth, height: btnHeight)
        understoodBtn.setTitle(TUISwift.timCommonLocalizableString("TIMAppOK"), for: .normal)
        understoodBtn.setTitleColor(UIColor.white, for: .normal)
        understoodBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        understoodBtn.layer.cornerRadius = btnHeight / 2
        understoodBtn.layer.masksToBounds = true
        understoodBtn.addTarget(self, action: #selector(understood), for: .touchUpInside)
        view.addSubview(understoodBtn)
    }

    @objc private func understood() {
        dismiss(animated: true, completion: nil)
    }
}
