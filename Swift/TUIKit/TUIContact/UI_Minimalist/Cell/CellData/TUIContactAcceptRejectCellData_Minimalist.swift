//  TUIContactAcceptRejectCellData_Minimalist.swift
//  TUIContact

import TIMCommon

class TUIContactAcceptRejectCellData_Minimalist: TUICommonCellData {
    var agreeClickCallback: (() -> Void)?
    var rejectClickCallback: (() -> Void)?
    var isAccepted: Bool = false
    var isRejected: Bool = false

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(42)
    }
}
