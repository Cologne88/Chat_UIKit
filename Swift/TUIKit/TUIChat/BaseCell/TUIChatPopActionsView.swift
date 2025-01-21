import UIKit

class TUIChatPopActionsView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorner()
    }

    private func updateCorner() {
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        let containerBounds = self.bounds
        let bounds = CGRect(x: containerBounds.origin.x, y: containerBounds.origin.y - 1, width: containerBounds.size.width, height: containerBounds.size.height)
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
}
