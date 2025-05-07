import UIKit

open class TUIGroupMemberCellData: NSObject {
    public var identifier: String = ""
    public var name: String = ""
    public var avatarImage: UIImage?
    public var avatarUrl: String?
    public var tag: Int = 0

    override public init() {
        super.init()
    }

    public init(identifier: String, name: String, avatarImage: UIImage? = nil, avatarUrl: String, tag: Int) {
        self.identifier = identifier
        self.name = name
        self.avatarImage = avatarImage
        self.avatarUrl = avatarUrl
        self.tag = tag
    }
}

open class TUIGroupMembersCellData: NSObject {
    public var members: [TUIGroupMemberCellData]?

    override public init() {
        super.init()
    }

    public init(members: [TUIGroupMemberCellData]) {
        self.members = members
    }

    public static func getSize() -> CGSize {
        var headSize = TUISwift.tGroupMemberCell_Head_Size()
        let width = headSize.width * CGFloat(TGroupMembersCell_Column_Count)
        let margin = CGFloat(TGroupMembersCell_Margin) * CGFloat(TGroupMembersCell_Column_Count + 1)
        if width + margin > UIScreen.main.bounds.width {
            let margin = (CGFloat(TGroupMembersCell_Margin) * CGFloat(TGroupMembersCell_Column_Count + 1))
            let wd = (UIScreen.main.bounds.width - margin) / CGFloat(TGroupMembersCell_Column_Count)
            headSize = CGSize(width: wd, height: wd)
        }
        return CGSize(width: headSize.width, height: headSize.height + CGFloat(TGroupMemberCell_Name_Height) + CGFloat(TGroupMemberCell_Margin))
    }

    public static func getHeight(data: TUIGroupMembersCellData) -> CGFloat {
        var row = ceil(Double(data.members?.count ?? 0) / Double(TGroupMembersCell_Column_Count))
        if row > Double(TGroupMembersCell_Row_Count) {
            row = Double(TGroupMembersCell_Row_Count)
        }
        let height = CGFloat(row) * getSize().height + (CGFloat(row) + 1) * CGFloat(TGroupMembersCell_Margin)
        return height
    }

    public func height(ofWidth width: CGFloat) -> CGFloat {
        return TUIGroupMembersCellData.getHeight(data: self)
    }
}

public class TUICommonGroupInfoCellData {
    // Add properties and methods as needed
}
