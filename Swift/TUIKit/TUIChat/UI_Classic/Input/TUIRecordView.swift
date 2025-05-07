import TIMCommon
import TUICore
import UIKit

class TUIRecordView: UIView {
    var recordImage: UIImageView!
    var title: UILabel!
    var background: UIView!
    var timeLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        defaultLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor.clear
        
        background = UIView()
        background.backgroundColor = TUISwift.rgba(0, g: 0, b: 0, a: 0.6)
        background.layer.cornerRadius = 5
        background.layer.masksToBounds = true
        addSubview(background)
        
        recordImage = UIImageView()
        recordImage.image = UIImage.safeImage(TUISwift.tuiChatImagePath("record_1"))
        recordImage.alpha = 0.8
        recordImage.contentMode = .center
        background.addSubview(recordImage)
        
        title = UILabel()
        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.white
        title.textAlignment = .center
        title.layer.cornerRadius = 5
        title.layer.masksToBounds = true
        background.addSubview(title)
        
        timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor.white
        timeLabel.textAlignment = .center
        timeLabel.layer.cornerRadius = 5
        timeLabel.text = String(format: "%.0f\"", min(60, TUIChatConfig.shared.maxAudioRecordDuration))
        background.addSubview(timeLabel)
    }
    
    private func defaultLayout() {
        var backSize = CGSize(width: 150, height: 150)
        title.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordSlideToCancel")
        let titleSize = title.sizeThatFits(CGSize(width: TUISwift.screen_Width(), height: TUISwift.screen_Height()))
        
        let recordMargin = 8.0
        if titleSize.width > backSize.width {
            backSize.width = titleSize.width + 2 * recordMargin
        }
        
        let imageHeight = backSize.height - titleSize.height - 2 * recordMargin
        
        timeLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.background).offset(10)
            make.width.equalTo(100)
            make.height.equalTo(10)
            make.centerX.equalTo(self.background)
        }

        recordImage.snp.remakeConstraints { make in
            make.top.equalTo(self.timeLabel.snp.bottom).offset(-13)
            make.centerX.equalTo(self.background)
            make.width.equalTo(backSize.width)
            make.height.equalTo(imageHeight)
        }

        title.snp.remakeConstraints { make in
            make.centerX.equalTo(self.background)
            make.top.equalTo(self.recordImage.snp.bottom)
            make.width.equalTo(backSize.width)
            make.height.equalTo(15)
        }

        background.snp.remakeConstraints { make in
            make.top.equalTo(self.timeLabel.snp.top).offset(-3)
            make.bottom.equalTo(self.title.snp.bottom).offset(3)
            make.center.equalTo(self)
            make.width.equalTo(backSize.width)
        }
    }
    
    func setStatus(_ status: RecordStatus) {
        switch status {
        case .recording:
            title.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordSlideToCancel")
            title.backgroundColor = UIColor.clear
        case .cancel:
            title.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordReleaseToCancel")
            title.backgroundColor = UIColor.clear
        case .tooShort:
            title.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordTimeshort")
            title.backgroundColor = UIColor.clear
        case .tooLong:
            title.text = TUISwift.timCommonLocalizableString("TUIKitInputRecordTimeLong")
            title.backgroundColor = UIColor.clear
        }
    }
    
    func setPower(_ power: Int) {
        let imageName = getRecordImage(power)
        recordImage.image = UIImage.safeImage(TUISwift.tuiChatImagePath(imageName))
    }
    
    private func getRecordImage(_ power: Int) -> String {
        let adjustedPower = power + 60
        var index = 0
        if adjustedPower < 25 {
            index = 1
        } else {
            index = Int(ceil(Double(adjustedPower - 25) / 5.0)) + 1
        }
        index = min(index, 8)
        return "record_\(index)"
    }
}
