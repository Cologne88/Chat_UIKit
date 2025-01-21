//  TUIContactEmptyView_Minimalist.swift
//  TUIContact

import UIKit
import TIMCommon

class TUIContactEmptyView_Minimalist: UIView {
    var midImage: UIImageView?
    var tipsLabel: UILabel?

    init(image: UIImage?, text: String?) {
        super.init(frame: .zero)
        self.tipsLabel = UILabel()
        self.tipsLabel?.text = text
        self.tipsLabel?.textColor = UIColor.tui_color(withHex: "#999999")
        self.tipsLabel?.font = UIFont.systemFont(ofSize: 14.0)
        self.tipsLabel?.textAlignment = .center

        if let img = image {
            self.midImage = UIImageView(image: img)
        }

        if let tipsLabel = self.tipsLabel {
            self.addSubview(tipsLabel)
        }
        if let midImage = self.midImage {
            self.addSubview(midImage)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let midImage = self.midImage {
            midImage.frame = CGRect(x: (self.bounds.size.width - TUISwift.kScale390(105)) * 0.5, y: 0, width: TUISwift.kScale390(105), height: TUISwift.kScale390(105))
        }
        self.tipsLabel?.sizeToFit()
        if let tipsLabel = self.tipsLabel, let midImage = self.midImage {
            tipsLabel.frame = CGRect(x: (self.bounds.size.width - tipsLabel.frame.size.width) * 0.5,
                                     y: midImage.frame.origin.y + midImage.frame.size.height + TUISwift.kScale390(10),
                                     width: tipsLabel.frame.size.width,
                                     height: tipsLabel.frame.size.height)
        }
    }
}
