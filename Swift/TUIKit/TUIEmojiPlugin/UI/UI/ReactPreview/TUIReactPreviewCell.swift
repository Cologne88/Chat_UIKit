//
//  TUIReactPreviewCell.swift
//  TUIChat
//
//  Created by wyl on 2022/5/26.
//  Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import UIKit

let margin: CGFloat = 8
let rightMargin: CGFloat = 8
let maxItemWidth: CGFloat = 107
let MaxTagSize: CGFloat = UIScreen.main.bounds.width * 0.25 * 3 - 20

class TUIReactPreviewCell: UIView, TUIAttributedLabelDelegate {
    var model: TUIReactModel? {
        didSet {
            guard let model = model else { return }
            self.backgroundColor = model.defaultColor
            
            self.subviews.forEach { $0.removeFromSuperview() }
            
            let text = model.descriptionFollowUserStr()
        
            var allWidth: CGFloat = 0
            
            let emojiBtn = UIButton()
            emojiBtn.addTarget(self, action: #selector(self.emojiBtnClick), for: .touchUpInside)
            self.addSubview(emojiBtn)
            let image = TUIImageCache.sharedInstance().getFaceFromCache(model.emojiPath)
            emojiBtn.setImage(image, for: .normal)
            emojiBtn.frame = CGRect(x: margin, y: 4, width: 18, height: 18)
            allWidth += emojiBtn.frame.size.width
            
            let line = UIView(frame: CGRect(x: emojiBtn.frame.origin.x + emojiBtn.frame.size.width + 4,
                                            y: (30 - 14) * 0.5,
                                            width: 1,
                                            height: 14))
            line.backgroundColor = UIColor(red: 68/255.0, green: 68/255.0, blue: 68/255.0, alpha: 0.2)
            self.addSubview(line)
            allWidth += line.frame.size.width
            
            let label = TUIAttributedLabel(frame: CGRect(x: line.frame.origin.x + 4,
                                                         y: 8,
                                                         width: self.frame.size.width,
                                                         height: 30))
            label.isUserInteractionEnabled = true
            self.addSubview(label)
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.onSelectUser))
            label.addGestureRecognizer(tap)

            let contentString = text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 11
            paragraphStyle.lineBreakMode = .byTruncatingTail

            let mutableAttributedString = NSMutableAttributedString(string: contentString)
            let range = NSRange(location: 0, length: contentString.utf16.count)
            mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            mutableAttributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 11), range: range)
            mutableAttributedString.addAttribute(.strokeWidth, value: 0, range: range)
            label.attributedText = mutableAttributedString

            label.linkAttributes = [
                NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): model.textColor as Any,
                NSAttributedString.Key(rawValue: kCTUnderlineStyleAttributeName as String): NSNumber(value: false)
            ]
            if let clickURL = URL(string: "click") {
                label.addLink(to: clickURL, withRange: range)
            }
            label.sizeToFit()
            label.textColor = model.textColor

            var fitWidth = label.frame.size.width
            let limitWidth = MaxTagSize - allWidth - 12 - 12 - 100
            if fitWidth > limitWidth {
                fitWidth = limitWidth
            }
            label.frame = CGRect(x: label.frame.origin.x, y: label.frame.origin.y, width: fitWidth, height: label.frame.size.height)
            label.preferredMaxLayoutWidth = 10
            label.font = UIFont.systemFont(ofSize: 11)
            label.numberOfLines = 1
            label.delegate = self

            allWidth += label.frame.size.width
            allWidth += margin
            allWidth += rightMargin
            allWidth += 8
            self.ItemWidth = allWidth
        }
    }
    
    var ItemWidth: CGFloat = 0
    var emojiClickCallback: ((TUIReactModel?) -> Void)?
    var userClickCallback: ((TUIReactModel?) -> Void)?
    
    private var tagBtn: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.prepareUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.prepareUI()
    }
    
    func prepareUI() {
        self.layer.cornerRadius = 12.0
        self.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.subviews.forEach { $0.resetFrameToFitRTL() }
    }
    
    @objc func emojiBtnClick() {
        if let callback = emojiClickCallback, let model = model {
            callback(model)
        }
    }
    
    @objc func onSelectUser() {
        if let callback = userClickCallback, let model = model {
            callback(model)
        }
    }
}
