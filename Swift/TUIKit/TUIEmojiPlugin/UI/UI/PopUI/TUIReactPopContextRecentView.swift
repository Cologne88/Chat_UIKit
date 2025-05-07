//
//  TUIReactPopContextRecentView.swift
//  TUIChat
//
//  Created by wyl on 2022/10/24.
//  Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import TUIChat
import UIKit

class TUIReactPopContextRecentView: UIView {
    let kTIMRecentDefaultEmojiSize: CGSize = .init(width: 25, height: 25)
    
    private(set) var faceGroups: [TUIFaceGroup] = []
    var needShowbottomLine: Bool = false
    var arrowButton: UIButton?
    weak var delegateVC: TUIChatPopContextController?
    
    private var sectionIndexInGroup: [Int] = []
    private var groupIndexInSection: [Int] = []
    private var itemIndexs: [IndexPath: Int] = [:]
    private var sectionCount: Int = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        defaultLayout()
    }
    
    func defaultLayout() {
        setupCorner()
        setupDefaultArray()
    }
    
    func setupCorner() {
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: TUISwift.kScale390(22), height: TUISwift.kScale390(22)))
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
            let groupSectionCount = Int(ceil(Double(group.faces?.count ?? 0) / Double(itemCount)))
            for _ in 0..<groupSectionCount {
                groupIndexInSection.append(groupIndex)
            }
            sectionIndex += groupSectionCount
        }
        sectionCount = sectionIndex
        
        for curSection in 0..<sectionCount {
            guard curSection < groupIndexInSection.count else { continue }
            let groupIndex = groupIndexInSection[curSection]
            guard groupIndex < sectionIndexInGroup.count else { continue }
            let groupStartIndex = sectionIndexInGroup[groupIndex]
            let faceGroup = faceGroups[groupIndex]
            let itemCount = faceGroup.rowCount * faceGroup.itemCountPerRow
            let groupSection = curSection - groupStartIndex
            for itemIndex in 0..<itemCount {
                let row = itemIndex % faceGroup.rowCount
                let column = itemIndex / faceGroup.rowCount
                let section = groupSection * itemCount
                let reIndex = faceGroup.itemCountPerRow * row + column + section
                let indexKey = IndexPath(row: Int(itemIndex), section: curSection)
                itemIndexs[indexKey] = Int(reIndex)
            }
        }
        
        createBtns()
        
        if needShowbottomLine {
            let margin: CGFloat = 20
            let line = UIView(frame: CGRect(x: margin, y: frame.height - 1, width: frame.width - 2 * margin, height: 0.5))
            addSubview(line)
            line.backgroundColor = TUISwift.timCommonDynamicColor("separator_color", defaultColor: "#DBDBDB")
        }
    }
    
    func findFaceGroupAboutType() -> TUIFaceGroup? {
        guard let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self) else {
            return nil
        }
        
        guard var group = service.getChatPopMenuRecentQueue() else {
            return nil
        }
        
        if let faces = group.faces {
            group.faces = Array(faces.prefix(min(6, faces.count)))
        }
        
        return group
    }
    
    func createBtns() {
        subviews.forEach { $0.removeFromSuperview() }
        
        guard let firstGroupIndex = groupIndexInSection.first, firstGroupIndex < faceGroups.count else { return }
        let group = faceGroups[firstGroupIndex]
        var tag = 0
        let margin = TUISwift.kScale390(8)
        let padding = TUISwift.kScale390(2)
        
        var preBtn: UIButton? = nil
        guard let faces = group.faces else { return }
        for cellData in faces {
            let image = TUIImageCache.sharedInstance().getFaceFromCache(cellData.path ?? "")
            let button = buttonWithCellImage(img: image, Tag: tag)
            addSubview(button)
            if tag == 0 {
                button.frame = CGRect(x: margin, y: TUISwift.kScale390(8), width: kTIMRecentDefaultEmojiSize.width, height: kTIMRecentDefaultEmojiSize.height)
            } else if let pre = preBtn {
                button.frame = CGRect(x: pre.frame.origin.x + pre.frame.width + padding, y: TUISwift.kScale390(8), width: kTIMRecentDefaultEmojiSize.width, height: kTIMRecentDefaultEmojiSize.height)
            }
            tag += 1
            preBtn = button
        }
        
        arrowButton = buttonWithCellImage(img: UIImage.safeImage(TUISwift.tuiChatImagePath_Minimalist("icon_emoji_more")), Tag: 999)
        if let arrowButton = arrowButton {
            addSubview(arrowButton)
            arrowButton.frame = CGRect(x: frame.width - margin - TUISwift.kScale390(24),
                                       y: TUISwift.kScale390(8),
                                       width: TUISwift.kScale390(24),
                                       height: TUISwift.kScale390(24))
        }
        
        if TUISwift.isRTL() {
            for subview in subviews {
                subview.resetFrameToFitRTL()
            }
        }
    }
    
    func buttonWithCellImage(img: UIImage?, Tag tag: Int) -> UIButton {
        let actionButton = TUIFitButton(type: .custom)
        actionButton.imageSize = kTIMRecentDefaultEmojiSize
        actionButton.setImage(img, for: .normal)
        actionButton.contentMode = .scaleAspectFit
        actionButton.addTarget(self, action: #selector(onClick(sender:)), for: .touchUpInside)
        actionButton.tag = tag
        return actionButton
    }
    
    @objc func onClick(sender btn: UIButton) {
        if btn.tag == 999 {
            btn.isSelected.toggle()
            showDetailPage()
        } else {
            guard faceGroups.count > 0 else { return }
            let group = faceGroups[0]
            guard btn.tag < (group.faces?.count ?? 0) else { return }
            guard let face = group.faces?[btn.tag] else { return }
            let faceName = face.name ?? ""
            updateReactClick(faceName: faceName)
            delegateVC?.blurDismissViewController(animated: true, completion: nil)
        }
    }
    
    func showDetailPage() {
        let detailController = TUIReactContextEmojiDetailController()
        detailController.modalPresentationStyle = .custom
        detailController.reactClickCallback = { [weak self] faceName in
            guard let self = self else { return }
            self.updateReactClick(faceName: faceName)
            self.delegateVC?.blurDismissViewController(animated: true, completion: nil)
        }
        if let vc = mm_viewController {
            vc.present(detailController, animated: true, completion: nil)
        }
    }
    
    func hideDetailPage() {
        delegateVC?.blurDismissViewController(animated: true, completion: nil)
    }
    
    func updateReactClick(faceName: String) {
        if let alertViewCellData = delegateVC?.alertViewCellData {
            alertViewCellData.updateReactClick(faceName)
        }
    }
}
