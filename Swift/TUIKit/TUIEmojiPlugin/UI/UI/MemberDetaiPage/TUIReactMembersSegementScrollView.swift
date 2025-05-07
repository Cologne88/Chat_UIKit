//
//  TUIReactMembersSegementScrollView.swift
//  TUIChat
//
//  Created by wyl on 2022/10/31.
//  Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import UIKit

let SEGEMENT_BTN_WIDTH: CGFloat = TUISwift.kScale390(43)
let SEGEMENT_BTN_HEIGHT: CGFloat = TUISwift.kScale390(20)
let SEGEMENT_HEIGTHT: CGFloat = 22

class TUIReactMembersSegementItem: NSObject {
    var title: String = ""
    var facePath: String = ""
}

class TUIReactMembersSegementButtonView: UIView {
    lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var img: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    lazy var title: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: TUISwift.kScale390(12))
        label.tintColor = UIColor.tui_color(withHex: "#141516")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        addSubview(contentView)
        contentView.addSubview(img)
        contentView.addSubview(title)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.snp.remakeConstraints { make in
            make.leading.equalTo(img)
            make.center.equalTo(self)
            make.trailing.equalTo(title)
            make.height.equalTo(self)
        }
        
        img.snp.remakeConstraints { make in
            make.leading.equalTo(contentView).offset(TUISwift.kScale390(3))
            make.centerY.equalTo(self)
            make.width.height.equalTo(TUISwift.kScale390(12))
        }
        
        title.sizeToFit()
        title.snp.remakeConstraints { make in
            make.leading.equalTo(img.snp.trailing).offset(TUISwift.kScale390(5))
            make.centerY.equalTo(self)
            make.width.equalTo(title.frame.size.width)
            make.height.equalTo(title.font.lineHeight)
        }
    }
}

class TUIReactMembersSegementView: UIView, UIScrollViewDelegate {
    var nPageIndex: Int = 0
    var titleCount: Int = 0
    var currentBtn: TUIReactMembersSegementButtonView?
    var btnArray: [TUIReactMembersSegementButtonView] = []
    
    var block: ((Int) -> Void)?
    
    lazy var segementScrollView: UIScrollView = {
        let rect = self.bounds
        let scrollView = UIScrollView(frame: rect)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.isPagingEnabled = false
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        return scrollView
    }()
    
    lazy var selectedLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.tui_color(withHex: "#F9F9F9").withAlphaComponent(0.54)
        return view
    }()
    
    init(frame: CGRect, SegementItems items: [TUIReactMembersSegementItem], block clickedBlock: @escaping (Int) -> Void) {
        super.init(frame: frame)
        addSubview(segementScrollView)
        block = clickedBlock
        nPageIndex = 1
        titleCount = items.count
        let padding = TUISwift.kScale390(8)
        var preBtn: TUIReactMembersSegementButtonView? = nil
        
        for i in 0..<titleCount {
            var btn: TUIReactMembersSegementButtonView
            if preBtn == nil {
                btn = TUIReactMembersSegementButtonView(frame: CGRect(x: 0, y: (self.frame.height - SEGEMENT_BTN_HEIGHT) * 0.5, width: SEGEMENT_BTN_WIDTH, height: SEGEMENT_BTN_HEIGHT))
                currentBtn = btn
            } else {
                let xPosition = preBtn!.frame.origin.x + preBtn!.frame.size.width + padding
                btn = TUIReactMembersSegementButtonView(frame: CGRect(x: xPosition, y: (self.frame.height - SEGEMENT_BTN_HEIGHT) * 0.5, width: SEGEMENT_BTN_WIDTH, height: SEGEMENT_BTN_HEIGHT))
            }
            preBtn = btn
            btn.title.text = items[i].title
            btn.img.image = TUIImageCache.sharedInstance().getFaceFromCache(items[i].facePath)
            btn.tag = i + 1
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(btnClick(_:)))
            btn.addGestureRecognizer(tapGesture)
            segementScrollView.addSubview(btn)
            btnArray.append(btn)
        }
        
        if let currentBtn = currentBtn {
            selectedLine.frame = CGRect(x: currentBtn.frame.origin.x, y: (self.frame.height - SEGEMENT_BTN_HEIGHT) * 0.5, width: max(currentBtn.frame.size.width, SEGEMENT_BTN_WIDTH), height: SEGEMENT_BTN_HEIGHT)
        }
        selectedLine.layer.cornerRadius = TUISwift.kScale390(10)
        
        segementScrollView.addSubview(selectedLine)
        segementScrollView.contentSize = CGSize(width: CGFloat(titleCount) * SEGEMENT_BTN_WIDTH + (padding * CGFloat(titleCount) - 1), height: 0)
        
        if TUISwift.isRTL() {
            segementScrollView.transform = CGAffineTransform(rotationAngle: .pi)
            for subview in segementScrollView.subviews {
                subview.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setPageIndex(_ nIndex: Int) {
        if nIndex != nPageIndex {
            nPageIndex = nIndex
            refreshSegement()
        }
    }
    
    func refreshSegement() {
        for btn in btnArray {
            if btn.tag == nPageIndex {
                currentBtn = btn
            }
        }
        
        if let currentBtn = currentBtn {
            if currentBtn.frame.origin.x + SEGEMENT_BTN_WIDTH > frame.width + segementScrollView.contentOffset.x {
                let offset = CGPoint(x: segementScrollView.contentOffset.x + SEGEMENT_BTN_WIDTH, y: 0)
                segementScrollView.setContentOffset(offset, animated: true)
            } else if currentBtn.frame.origin.x < segementScrollView.contentOffset.x {
                let offset = CGPoint(x: currentBtn.frame.origin.x, y: 0)
                segementScrollView.setContentOffset(offset, animated: true)
            }
            
            UIView.animate(withDuration: 0.2, animations: {
                self.selectedLine.frame = CGRect(x: currentBtn.frame.origin.x, y: (self.frame.height - SEGEMENT_BTN_HEIGHT) * 0.5, width: currentBtn.frame.size.width, height: SEGEMENT_BTN_HEIGHT)
                self.selectedLine.layer.cornerRadius = TUISwift.kScale390(10)
            }, completion: { _ in
                // to do
            })
        }
    }
    
    @objc func btnClick(_ recognizer: UITapGestureRecognizer) {
        if let btn = recognizer.view as? TUIReactMembersSegementButtonView {
            currentBtn = btn
            if nPageIndex != btn.tag {
                showHapticFeedback()
                nPageIndex = btn.tag
                refreshSegement()
                block?(nPageIndex)
            }
        }
    }
    
    func showHapticFeedback() {
        if #available(iOS 10.0, *) {
            DispatchQueue.main.async {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

class TUIReactMembersSegementScrollView: UIView, UIScrollViewDelegate {
    private let items: [TUIReactMembersSegementItem]
    private let viewArray: [UIViewController]
    
    lazy var mySegementView: TUIReactMembersSegementView = {
        let frame = CGRect(x: TUISwift.kScale390(27), y: 0, width: UIScreen.main.bounds.width - TUISwift.kScale390(54), height: SEGEMENT_HEIGTHT)
        let segementView = TUIReactMembersSegementView(frame: frame, SegementItems: self.items) { [weak self] index in
            guard let strongSelf = self else { return }
            strongSelf.pageScrollView.setContentOffset(CGPoint(x: CGFloat(index - 1) * UIScreen.main.bounds.width, y: 0), animated: true)
        }
        return segementView
    }()
    
    lazy var pageScrollView: UIScrollView = {
        let yOrigin = self.mySegementView.frame.size.height
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: yOrigin, width: UIScreen.main.bounds.width, height: self.bounds.height - yOrigin))
        scrollView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    init(frame: CGRect, SegementItems items: [TUIReactMembersSegementItem], viewArray: [UIViewController]) {
        self.items = items
        self.viewArray = viewArray
        super.init(frame: frame)
        addSubview(mySegementView)
        addSubview(pageScrollView)
        
        for i in 0..<viewArray.count {
            let viewController = viewArray[i]
            viewController.view.frame = CGRect(x: CGFloat(i) * UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: pageScrollView.frame.size.height)
            pageScrollView.addSubview(viewController.view)
        }
        pageScrollView.contentSize = CGSize(width: CGFloat(viewArray.count) * UIScreen.main.bounds.width, height: pageScrollView.frame.size.height)
        
        if TUISwift.isRTL() {
            pageScrollView.transform = CGAffineTransform(rotationAngle: .pi)
            for subview in pageScrollView.subviews {
                subview.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateContainerView() {
        let yOrigin = mySegementView.frame.size.height
        pageScrollView.frame = CGRect(x: 0, y: yOrigin, width: UIScreen.main.bounds.width, height: bounds.height - yOrigin)
        
        for i in 0..<viewArray.count {
            let viewController = viewArray[i]
            viewController.view.frame = CGRect(x: CGFloat(i) * UIScreen.main.bounds.width, y: 0, width: UIScreen.main.bounds.width, height: pageScrollView.frame.size.height)
        }
        
        pageScrollView.contentSize = CGSize(width: CGFloat(viewArray.count) * UIScreen.main.bounds.width, height: pageScrollView.frame.size.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == pageScrollView {
            let p = Int(pageScrollView.contentOffset.x / UIScreen.main.bounds.width)
            mySegementView.setPageIndex(p + 1)
        }
    }
}
