//  TUIContactActionCellData_Minimalist.swift
//  TUIContact

import TIMCommon

class TUIContactActionCellData_Minimalist: TUICommonCellData {
    
    var title: String?
    var icon: UIImage?
    @objc dynamic var readNum: Int = 0
    var needBottomLine: Bool = true
    
    override init() {
        super.init()
        self.needBottomLine = true
    }
}
