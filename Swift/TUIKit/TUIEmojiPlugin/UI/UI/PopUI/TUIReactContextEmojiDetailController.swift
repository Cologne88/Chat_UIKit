//
//  TUIReactContextEmojiDetailController.swift
//  TUIChat
//
//  Created by wyl on 2022/10/27.
//  Copyright © 2023 Tencent. All rights reserved.
//

import UIKit
import TUIChat
import TIMCommon

class TUIReactContextPopEmojiFaceView: TUIFaceVerticalView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func setData(_ data: [TUIFaceGroup]) {
        super.setData(data)
        floatCtrlView?.isHidden = true
        backgroundColor = UIColor.clear
        faceCollectionView?.backgroundColor = backgroundColor
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.frame.size.width, height: 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard groupIndexInSection.indices.contains(indexPath.section) else {
            return .zero
        }
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        let itemsPerRow = group.itemCountPerRow
        let viewWidth: CGFloat = self.frame.size.width
        let totalPadding: CGFloat = CGFloat(TFaceView_Page_Padding * 2)
        let totalMargin: CGFloat = CGFloat(TFaceView_Margin) * CGFloat(itemsPerRow - 1)
        let availableWidth: CGFloat = viewWidth - totalPadding - totalMargin
        let width: CGFloat = availableWidth / CGFloat(itemsPerRow)
        let height = width
        return CGSize(width: width, height: height)
    }
    
    // MARK: - UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TFaceCell", for: indexPath) as? TUIFaceCell else {
            return UICollectionViewCell()
        }
        
        guard groupIndexInSection.indices.contains(indexPath.section) else {
            return cell
        }
        let groupIndex = groupIndexInSection[indexPath.section]
        let group = faceGroups[groupIndex]
        
        if let faces = group.faces, let indexNumber = itemIndexs[indexPath] as? NSNumber, indexNumber.intValue < faces.count {
            let data = faces[indexNumber.intValue]
            cell.setData(data )
        } else {
            cell.setData(TUIFaceCellData())
        }
        
        cell.face.contentMode = .scaleAspectFill
        return cell
    }
}

// MARK: - TUIReactContextEmojiDetailController
class TUIReactContextEmojiDetailController: TUIChatFlexViewController, TUIFaceVerticalViewDelegate {
    
    var reactClickCallback: ((String) -> Void)?
    
    lazy var faceView: TUIReactContextPopEmojiFaceView = {
        let view = TUIReactContextPopEmojiFaceView(frame: CGRectZero)
        view.delegate = self
        if let emojiDetailGroups = TUIChatConfig.shared.chatContextEmojiDetailGroups() {
            view.setData(emojiDetailGroups)
        }
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    override init() {
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNormalBottom()
        
        containerView.backgroundColor = UIColor.white
        containerView.addSubview(faceView)
        setFaceViewFrame()
    }
    
    override func updateSubContainerView() {
        super.updateSubContainerView()
        setFaceViewFrame()
    }
    
    func setFaceViewFrame() {
        let topHeight = topGestureView.frame.size.height
        let containerWidth = containerView.frame.size.width
        let containerHeight = containerView.frame.size.height
        faceView.frame = CGRect(x: 0, y: topHeight, width: containerWidth, height: containerHeight - topHeight)
    }
    
    func updateRecentMenuQueue(_ faceName: String?) {
        guard let service = TIMCommonMediator.shared.getObject(for: TUIEmojiMeditorProtocol.self) as? TUIEmojiMeditorProtocol else {
            return
        }
        service.updateRecentMenuQueue(faceName ?? "")
    }
    
    // MARK: - TUIFaceVerticalViewDelegate
    func faceVerticalView(_ faceView: TUIFaceVerticalView, scrollToFaceGroupIndex index: Int){
        // to do
    }
    
    func faceVerticalView(_ faceView: TUIFaceVerticalView, didSelectItemAtIndexPath indexPath: IndexPath) {
        guard indexPath.section < faceView.faceGroups.count else { return }
        let group = faceView.faceGroups[indexPath.section]
        guard let faces = group.faces else { return }
        if indexPath.row < faces.count {
            let face = faces[indexPath.row]
            if indexPath.section == 0 {
                updateRecentMenuQueue(face.name)
                dismiss(animated: false, completion: nil)
                if let callback = reactClickCallback {
                    callback(face.name ?? "")
                }
            }
        }
    }
    
    func faceViewDidBackDelete(_ faceView: TUIFaceView) {
        // to do
    }
} 
