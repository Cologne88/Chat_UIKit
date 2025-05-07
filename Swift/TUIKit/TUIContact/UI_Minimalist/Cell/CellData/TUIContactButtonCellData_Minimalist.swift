//  TUIContactButtonCellData_Minimalist.swift
//  TUIContact

import Foundation
import TIMCommon

class TUIContactButtonCellData_Minimalist: TUICommonCellData {
    var title: String
    var cbuttonSelector: Selector?
    var style: TUIButtonStyle
    var textColor: UIColor?
    var hideSeparatorLine: Bool
    
    override init() {
        self.title = ""
        self.style = .green
        self.hideSeparatorLine = false
        super.init()
    }

    init(title: String, cbuttonSelector: Selector? = nil, style: TUIButtonStyle, textColor: UIColor? = nil, hideSeparatorLine: Bool = false) {
        self.title = title
        self.cbuttonSelector = cbuttonSelector
        self.style = style
        self.textColor = textColor
        self.hideSeparatorLine = hideSeparatorLine
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(42)
    }
}
