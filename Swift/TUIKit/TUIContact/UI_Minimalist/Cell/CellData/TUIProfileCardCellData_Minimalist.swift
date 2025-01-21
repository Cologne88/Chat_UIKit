//  TUIProfileCardCellData_Minimalist.swift
//  TUIContact

import TIMCommon

class TUIProfileCardCellData_Minimalist: TUIProfileCardCellData {
    var showGroupType: Bool = false

    override init() {
        super.init()
        self.avatarImage = TUISwift.defaultAvatarImage()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(86)
    }
}
