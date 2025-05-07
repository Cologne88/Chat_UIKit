import TIMCommon
import UIKit

class TUIReactPreview: UIView {
    /// datasource
    var listArrM: [TUIReactModel] = []
    
    /// Select the model for the TAB
    var emojiClickCallback: ((TUIReactModel) -> Void)?
    var userClickCallback: ((TUIReactModel) -> Void)?
    
    weak var delegateCell: TUIMessageCell?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateView() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
        if listArrM.isEmpty {
            return
        }
        
        /**
         * Margin, including top、bottom、left and right
         */
        let margin: CGFloat = 12
        let rightMargin: CGFloat = 12
        let topMargin: CGFloat = 3
        let bottomMargin: CGFloat = 3
        
        /**
         * Padding in the horizontal direction
         */
        let padding: CGFloat = 6
        
        /**
         * Padding in the vertical direction
         */
        let verticalPadding: CGFloat = 8
        
        /**
         * Size of tagview
         */
        var tagViewWidth: CGFloat = 0
        var tagViewHeight: CGFloat = 0
        
        var index = 0
        var preCell: TUIReactPreviewCell?
        
        for model in listArrM {
            let cell = TUIReactPreviewCell(frame: .zero)
            cell.tag = index
            cell.model = model
            addSubview(cell)
            
            if index == 0 {
                cell.frame = CGRect(x: margin, y: topMargin, width: cell.ItemWidth, height: 24)
                tagViewWidth = cell.ItemWidth
                tagViewHeight = 24
                if listArrM.count == 1 {
                    /**
                     * If  there is only one tag
                     */
                    tagViewWidth = margin + cell.frame.size.width + rightMargin
                    tagViewHeight = cell.frame.origin.y + cell.frame.size.height + bottomMargin
                }
            } else {
                // preCell must have value
                guard let previousCell = preCell else { continue }
                let previousFrameRightPoint = previousCell.frame.origin.x + previousCell.frame.size.width
                
                /**
                 * Placed in the current line, the width required after layout
                 */
                let needWidth = padding + cell.ItemWidth
                let residueWidth = MaxTagSize - previousFrameRightPoint - rightMargin
                if needWidth < residueWidth {
                    /**
                     * Placed it in the same line if has enough space
                     */
                    cell.frame = CGRect(x: previousFrameRightPoint + padding,
                                        y: previousCell.frame.origin.y,
                                        width: cell.ItemWidth,
                                        height: 24)
                } else {
                    /**
                     * Placed it in the another line if not enough space
                     */
                    cell.frame = CGRect(x: margin,
                                        y: previousCell.frame.origin.y + previousCell.frame.size.height + verticalPadding,
                                        width: cell.ItemWidth,
                                        height: 24)
                }
                
                let currentLineMaxWidth = max(previousFrameRightPoint + rightMargin,
                                              cell.frame.origin.x + cell.frame.size.width + rightMargin)
                tagViewWidth = max(currentLineMaxWidth, tagViewWidth)
                tagViewHeight = cell.frame.origin.y + cell.frame.size.height + bottomMargin
            }
            
            cell.emojiClickCallback = { [weak self] model in
                guard let model = model else { return }
                print("model.emojiKey click : \(model.emojiKey)")
                if let strongSelf = self {
                    strongSelf.emojiClickCallback?(model)
                }
            }
            
            cell.userClickCallback = { [weak self] model in
                guard let model = model else { return }
                if let strongSelf = self {
                    strongSelf.userClickCallback?(model)
                }
            }
            
            preCell = cell
            index += 1
        }
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: tagViewWidth, height: tagViewHeight)
    }
    
    func updateRTLView() {
        for subview in subviews {
            subview.resetFrameToFitRTL()
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
            guard let self = self else { return }
            self.setNeedsUpdateConstraints()
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    func refreshByArray(_ tagsArray: [TUIReactModel]?) {
        if let models = tagsArray, models.count > 0 {
            listArrM = models
            UIView.animate(withDuration: 1, animations: { [weak self] in
                self?.updateView()
            }, completion: { _ in
                // Completion block
            })
            delegateCell?.messageData?.messageContainerAppendSize = frame.size
            notifyReactionChanged()
        } else {
            listArrM = []
            UIView.animate(withDuration: 1, animations: { [weak self] in
                self?.updateView()
            }, completion: { _ in
                // Completion block
            })
            if let messageData = delegateCell?.messageData,
               messageData.messageContainerAppendSize != CGSize.zero
            {
                messageData.messageContainerAppendSize = CGSize.zero
                notifyReactionChanged()
            }
        }
    }
}
