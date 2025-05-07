//
//  TUIReactPopEmojiView.swift
//  TUIChat
//
//  Created by wyl on 2022/4/20.
//  Copyright © 2023 Tencent. All rights reserved.
//

import TIMCommon
import TUIChat
import UIKit

class TUIReactPopEmojiView: TUIFaceView {
    weak var delegateView: TUIChatPopMenu?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        guard groupIndexInSection.indices.contains(indexPath.section) else {
            return .zero
        }
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        let width = (frame.size.width - TChatEmojiView_Padding * 2 - TChatEmojiView_Margin * CGFloat(group.itemCountPerRow - 1)) / CGFloat(group.itemCountPerRow)
        let height = (collectionView.frame.size.height - TChatEmojiView_MarginTopBottom * CGFloat(group.rowCount - 1)) / CGFloat(group.rowCount)
        return CGSize(width: width, height: height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        defaultLayout()
        updateFrame()
        updateCorner()
    }
    
    func defaultLayout() {
        faceFlowLayout.scrollDirection = .horizontal
        faceFlowLayout.minimumLineSpacing = TChatEmojiView_Margin
        faceFlowLayout.minimumInteritemSpacing = TChatEmojiView_MarginTopBottom
        faceFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: TChatEmojiView_Padding, bottom: 0, right: TChatEmojiView_Padding)
        faceCollectionView.collectionViewLayout = faceFlowLayout
    }
    
    func updateFrame() {
        faceCollectionView.frame = CGRect(x: 0, y: TChatEmojiView_CollectionOffsetY, width: frame.size.width, height: TChatEmojiView_CollectionHeight)
        pageControl.frame = CGRect(x: 0, y: TChatEmojiView_CollectionOffsetY + faceCollectionView.frame.size.height, width: frame.size.width, height: TChatEmojiView_Page_Height)
    }
    
    func updateCorner() {
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        let boundsRect = CGRect(x: bounds.origin.x, y: bounds.origin.y - 1, width: bounds.size.width, height: bounds.size.height)
        let maskPath = UIBezierPath(roundedRect: boundsRect, byRoundingCorners: corner, cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
    
    override func setData(_ data: [TUIFaceGroup]) {
        super.setData(data)
    }
    
    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TFaceCell", for: indexPath) as? TUIFaceCell else {
            return UICollectionViewCell()
        }
        cell.face.contentMode = .scaleAspectFill
        
        guard groupIndexInSection.indices.contains(indexPath.section) else {
            return cell
        }
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        let itemCount = group.rowCount * group.itemCountPerRow
        
        if indexPath.row == itemCount - 1 && group.needBackDelete {
            let data = TUIFaceCellData()
            data.path = TUISwift.tuiChatFaceImagePath("del_normal")
            cell.setData(data)
            if let currentImage = cell.face.image {
                cell.face.image = currentImage.rtlImageFlippedForRightToLeftLayoutDirection()
            }
        } else {
            if let faces = group.faces, let indexNumber = itemIndexs[indexPath], indexNumber < faces.count {
                let data = faces[indexNumber]
                cell.setData(data)
            } else {
                cell.setData(TUIFaceCellData())
            }
        }
        cell.frame = CGRect(x: cell.frame.origin.x,
                            y: cell.frame.origin.y,
                            width: kTIMDefaultEmojiSize.width,
                            height: kTIMDefaultEmojiSize.height)
        cell.face.frame = CGRect(x: cell.face.frame.origin.x,
                                 y: cell.face.frame.origin.y,
                                 width: kTIMDefaultEmojiSize.width,
                                 height: kTIMDefaultEmojiSize.height)
        return cell
    }
    
    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard groupIndexInSection.indices.contains(indexPath.section) else {
            return
        }
        let groupIndex = groupIndexInSection[indexPath.section]
        let faces = faceGroups[groupIndex]
        let _ = faces.rowCount * faces.itemCountPerRow
        
        if let faces = faces.faces, let indexNumber = itemIndexs[indexPath], indexNumber < faces.count {
            let newIndexPath = IndexPath(row: indexNumber, section: groupIndex)
            faceView(self, didSelectItemAt: newIndexPath)
        }
    }
    
    func faceView(_ faceView: TUIFaceView, didSelectItemAt indexPath: IndexPath) {
        let group = faceView.faceGroups[indexPath.section]
        guard let face = group.faces?[indexPath.row] as? TUIFaceCellData else { return }
        if indexPath.section == 0 {
            updateRecentMenuQueue(face.name ?? "")
            updateReactClick(face.name ?? "")
            if let delegate = delegateView {
                delegate.hideWithAnimation()
            }
        }
    }
    
    func updateRecentMenuQueue(_ faceName: String) {
        if let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol {
            service.updateRecentMenuQueue(faceName)
        }
    }
    
    func updateReactClick(_ faceName: String) {
        if let targetCellData = delegateView?.targetCellData {
            targetCellData.updateReactClick(faceName)
        }
    }
}
