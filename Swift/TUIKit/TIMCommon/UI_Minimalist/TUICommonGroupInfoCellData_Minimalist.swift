import Foundation
import UIKit

open class TUIGroupButtonCellData_Minimalist: TUICommonCellData {
    public var title: String?
    public var cbuttonSelector: Selector?
    public var style: TUIButtonStyle = .green
    public var textColor: UIColor?
    public var hideSeparatorLine: Bool = false
    public var isInfoPageLeftButton: Bool = false

    override open func height(ofWidth width: CGFloat) -> CGFloat {
        return 56
    }
}

open class TUIGroupMemberCellData_Minimalist: TUICommonCellData {
    public var identifier: String?
    public var name: String?
    public var avatarImage: UIImage?
    public var avatarUrl: String?
    public var showAccessory: Bool = false
    public var detailName: String?
    public var tag: Int = 0

    override open func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(48)
    }
}

open class TUICommonGroupInfoCellData_Minimalist: NSObject {}
