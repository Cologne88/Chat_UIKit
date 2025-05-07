//
//  TUIReactPreview_Minimalist.swift
//  TUIEmojiPlugin
//
//  Created by cologne on 2023/11/29.
//

import TIMCommon
import UIKit

class TUIReactPreview_Minimalist: UIView {
    var reactlistArr: [TUIReactModel] = []
    weak var delegateCell: TUIMessageCell?
    var emojiClickCallback: ((TUIReactModel?) -> Void)?
    
    private var replyEmojiView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = TUISwift.rgba(221, g: 221, b: 221, a: 1).cgColor
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = UIColor.white
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private var replyEmojiCount: UILabel = {
        let label = UILabel()
        label.textColor = TUISwift.rgba(153, g: 153, b: 153, a: 1)
        label.rtlAlignment = .leading
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private var replyEmojiImageViews: [UIImageView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    private func setupViews() {
        addSubview(replyEmojiView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onJumpToReactEmojiPage))
        addGestureRecognizer(tap)
        
        replyEmojiView.addSubview(replyEmojiCount)
        replyEmojiImageViews = []
    }
    
    func updateView() {
        // emoji
        if replyEmojiImageViews.count > 0 {
            for emojiView in replyEmojiImageViews {
                emojiView.removeFromSuperview()
            }
            replyEmojiImageViews.removeAll()
        }
        replyEmojiView.isHidden = true
        replyEmojiCount.isHidden = true
        
        if reactlistArr.count > 0 {
            replyEmojiView.isHidden = false
            replyEmojiCount.isHidden = false
            
            var emojiCount = 0
            let emojiMaxCount = 6
            var replyEmojiTotalCount = 0
            var existEmojiMap: [String: TUIReactModel] = [:]
            for model in reactlistArr {
                let emojiKey = model.emojiKey
                replyEmojiTotalCount += model.followIDs.count
                
                if emojiCount >= emojiMaxCount || existEmojiMap[emojiKey] != nil {
                    continue
                }
                let emojiView = UIImageView()
                if emojiCount < emojiMaxCount - 1 {
                    existEmojiMap[emojiKey] = model
                    let image = emojiKey.getEmojiImage()
                    emojiView.image = image
                } else {
                    let image = TUIImageCache.sharedInstance().getResourceFromCache(TUISwift.tuiChatImagePath_Minimalist("msg_reply_more_icon"))
                    emojiView.image = image
                }
                replyEmojiView.addSubview(emojiView)
                replyEmojiImageViews.append(emojiView)
                emojiCount += 1
            }
            
            replyEmojiCount.text = "\(replyEmojiTotalCount)"
        }
        
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        if replyEmojiImageViews.count > 0 {
            let emojiSize: CGFloat = 12
            let emojiSpace = TUISwift.kScale390(4)
            var preEmojiView: UIImageView? = nil
            for (i, emojiView) in replyEmojiImageViews.enumerated() {
                emojiView.snp.remakeConstraints { make in
                    if i == 0 {
                        make.leading.equalTo(replyEmojiView.snp.leading).offset(TUISwift.kScale390(8))
                    } else if let pre = preEmojiView {
                        make.leading.equalTo(pre.snp.trailing).offset(emojiSpace)
                    }
                    make.width.height.equalTo(emojiSize)
                    make.centerY.equalTo(replyEmojiView.snp.centerY)
                }
                emojiView.layer.masksToBounds = true
                emojiView.layer.cornerRadius = emojiSize / 2.0
                preEmojiView = emojiView
            }
            
            if let lastEmojiView = replyEmojiImageViews.last {
                replyEmojiCount.snp.remakeConstraints { make in
                    make.leading.equalTo(lastEmojiView.snp.trailing).offset(TUISwift.kScale390(8))
                    make.trailing.equalTo(replyEmojiView.snp.trailing)
                    make.width.equalTo(emojiSize + 10)
                    make.height.equalTo(emojiSize)
                    make.centerY.equalTo(replyEmojiView.snp.centerY)
                }
            }
            
            replyEmojiView.snp.remakeConstraints { make in
                if let direction = delegateCell?.messageData?.direction, direction == .incoming {
                    make.leading.greaterThanOrEqualTo(self)
                } else {
                    make.trailing.lessThanOrEqualTo(self)
                }
                make.top.equalTo(self)
                make.height.equalTo(self)
            }
        } else {
            replyEmojiCount.frame = .zero
            replyEmojiView.frame = .zero
        }
    }
    
    func refreshByArray(_ tagsArray: [TUIReactModel]?) {
        if let models = tagsArray, models.count > 0 {
            reactlistArr = models
            UIView.animate(withDuration: 1, animations: { [weak self] in
                self?.updateView()
            }, completion: { _ in
                // Completion block intentionally left blank
            })
            delegateCell?.messageData?.messageContainerAppendSize = CGSize(width: 0, height: TUISwift.kScale375(16))
            notifyReactionChanged()
        } else {
            reactlistArr = []
            UIView.animate(withDuration: 1, animations: { [weak self] in
                self?.updateView()
            }, completion: { _ in
                // Completion block intentionally left blank
            })
            if let messageData = delegateCell?.messageData, messageData.messageContainerAppendSize != .zero {
                messageData.messageContainerAppendSize = .zero
                notifyReactionChanged()
            }
        }
    }
    
    func notifyReactionChanged() {
        let param: [AnyHashable: Any] = [
            "TUICore_TUIPluginNotify_DidChangePluginViewSubKey_Data": delegateCell?.messageData as Any,
            "TUICore_TUIPluginNotify_DidChangePluginViewSubKey_VC": self,
            "TUICore_TUIPluginNotify_DidChangePluginViewSubKey_isAllowScroll2Bottom": "0"
        ]
        TUICore.notifyEvent("TUICore_TUIPluginNotify",
                            subKey: "TUICore_TUIPluginNotify_DidChangePluginViewSubKey",
                            object: nil,
                            param: param)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.setNeedsUpdateConstraints()
            self?.updateConstraintsIfNeeded()
            self?.layoutIfNeeded()
        }
    }
    
    @objc func onJumpToReactEmojiPage() {
        if let callback = emojiClickCallback {
            callback(nil)
        }
    }
}
