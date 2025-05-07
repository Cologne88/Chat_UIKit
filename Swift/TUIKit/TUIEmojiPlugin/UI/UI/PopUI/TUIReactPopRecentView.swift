//
//  TUIReactPopRecentView.swift
//  TUIChat
//
//  Created by wyl on 2022/5/25.
//  Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import TUIChat
import UIKit

let kTIMRecentDefaultEmojiSize: CGSize = .init(width: 30, height: 30)

class TUIReactPopRecentView: UIView {
    private(set) var faceGroups: [TUIFaceGroup] = []
    var needShowbottomLine: Bool = false
    var arrowButton: UIButton?
    weak var delegateView: TUIChatPopMenu?
    
    private var sectionIndexInGroup: [Int] = []
    private var groupIndexInSection: [Int] = []
    private var itemIndexs: [IndexPath: Int] = [:]
    private var sectionCount: Int = 0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        defaultLayout()
        
        if TUISwift.isRTL() {
            for subview in subviews {
                if subview.responds(to: #selector(UIView.resetFrameToFitRTL)) {
                    subview.resetFrameToFitRTL()
                }
            }
        }
    }
    
    func defaultLayout() {
        setupCorner()
        setupDefaultArray()
    }
    
    func setupCorner() {
        let corners: UIRectCorner = [.topRight, .topLeft]
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    func setupDefaultArray() {
        var faceArray: [TUIFaceGroup] = []
        if let defaultFaceGroup = findFaceGroupAboutType() {
            faceArray.append(defaultFaceGroup)
        }
        setData(faceArray)
    }
    
    func setData(_ data: [TUIFaceGroup]) {
        faceGroups = data
        sectionIndexInGroup.removeAll()
        groupIndexInSection.removeAll()
        itemIndexs.removeAll()
        
        var sectionIndex = 0
        for groupIndex in 0..<faceGroups.count {
            let group = faceGroups[groupIndex]
            sectionIndexInGroup.append(sectionIndex)
            let itemCount = group.rowCount * group.itemCountPerRow
            let sectionCountForGroup = Int(ceil(Double(group.faces?.count ?? 0) * 1.0 / Double(itemCount)))
            for _ in 0..<sectionCountForGroup {
                groupIndexInSection.append(groupIndex)
            }
            sectionIndex += sectionCountForGroup
        }
        sectionCount = sectionIndex
        
        for curSection in 0..<sectionCount {
            let grpIndex = groupIndexInSection[curSection]
            let groupSectionIndex = sectionIndexInGroup[grpIndex]
            let faceGroup = faceGroups[grpIndex]
            let itemCount = faceGroup.rowCount * faceGroup.itemCountPerRow
            let groupSection = curSection - groupSectionIndex
            for itemIndex in 0..<itemCount {
                // transpose line/row
                let row = itemIndex % faceGroup.rowCount
                let column = itemIndex / faceGroup.rowCount
                let section = groupSection * itemCount
                let reIndex = faceGroup.itemCountPerRow * row + column + section
                let indexPath = IndexPath(row: Int(itemIndex), section: curSection)
                itemIndexs[indexPath] = Int(reIndex)
            }
        }
        
        createBtns()
        
        if needShowbottomLine {
            let margin: CGFloat = 20
            let lineFrame = CGRect(x: margin, y: frame.size.height - 1, width: frame.size.width - 2 * margin, height: 0.5)
            let line = UIView(frame: lineFrame)
            addSubview(line)
            line.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        }
    }

    func findFaceGroupAboutType() -> TUIFaceGroup? {
        guard let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self) else {
            return nil
        }
        
        guard let group = service.getChatPopMenuRecentQueue() else {
            return nil
        }
        
        if let faces = group.faces {
            group.faces = Array(faces.prefix(min(6, faces.count)))
        }
        
        return group
    }
    
    func createBtns() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
        
        guard let firstGroupIndex = groupIndexInSection.first, firstGroupIndex < faceGroups.count else {
            return
        }
        let group = faceGroups[firstGroupIndex]
        var tag = 0
        let margin: CGFloat = 20
        let padding: CGFloat = 10
        
        var preBtn: UIButton? = nil
        guard let faces = group.faces else { return }
        for cellData in faces {
            let image = TUIImageCache.sharedInstance().getFaceFromCache(cellData.path ?? "")
            let button = buttonWithCellImage(image, tag: tag)
            addSubview(button)
            if tag == 0 {
                button.mm_width(kTIMRecentDefaultEmojiSize.width)
                    .mm_height(kTIMRecentDefaultEmojiSize.height)
                    .mm_left(margin)
                    .mm__centerY(mm_centerY)
            } else if let preButton = preBtn {
                button.mm_width(kTIMRecentDefaultEmojiSize.width)
                    .mm_height(kTIMRecentDefaultEmojiSize.height)
                    .mm_left(preButton.mm_x + preButton.mm_w + padding)
                    .mm__centerY(mm_centerY)
            }
            tag += 1
            preBtn = button
        }
        
        arrowButton = buttonWithCellImage(TUISwift.tuiChatBundleThemeImage("chat_icon_emojiArrowDown_img", defaultImage: "emojiArrowDown"), tag: 999)
        if let arrowButton = arrowButton {
            addSubview(arrowButton)
            arrowButton.setImage(TUISwift.tuiChatBundleThemeImage("chat_icon_emojiArrowUp_img", defaultImage: "emojiArrowUp"), for: .selected)
            arrowButton.mm_width(25)
                .mm_height(25)
                .mm_right(margin)
                .mm__centerY(mm_centerY)
        }
    }
    
    func buttonWithCellImage(_ img: UIImage?, tag: Int) -> UIButton {
        let actionButton = TUIFitButton(type: .custom)
        actionButton.imageSize = kTIMRecentDefaultEmojiSize
        actionButton.setImage(img, for: .normal)
        actionButton.contentMode = .scaleAspectFit
        actionButton.addTarget(self, action: #selector(onClick(_:)), for: .touchUpInside)
        actionButton.tag = tag
        return actionButton
    }
    
    @objc func onClick(_ btn: UIButton) {
        if btn.tag == 999 {
            btn.isSelected.toggle()
            if btn.isSelected {
                showDetailPage()
            } else {
                hideDetailPage()
            }
        } else {
            if faceGroups.isEmpty { return }
            let group = faceGroups[0]
            guard let faces = group.faces else { return }
            if btn.tag < faces.count {
                let face = faces[btn.tag]
                let faceName = face.name ?? ""
                updateReactClick(faceName)
            }
            delegateView?.hideWithAnimation()
        }
    }
    
    func showDetailPage() {
        delegateView?.containerView?.alpha = 0
        if let emojiSubviews = delegateView?.emojiContainerView?.subviews {
            for subview in emojiSubviews {
                subview.alpha = 1
            }
        }
    }
    
    func hideDetailPage() {
        delegateView?.containerView?.alpha = 1
        if let emojiSubviews = delegateView?.emojiContainerView?.subviews {
            for subview in emojiSubviews {
                if subview != self {
                    subview.alpha = 0
                }
            }
        }
    }
    
    func updateReactClick(_ faceName: String) {
        if let targetCellData = delegateView?.targetCellData {
            targetCellData.updateReactClick(faceName)
        }
    }
}
