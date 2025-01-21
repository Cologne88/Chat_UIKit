//  TUIMemberInfoCellData_Minimalist.swift
//  TUIContact

import Foundation
import UIKit

class TUIMemberInfoCellData_Minimalist: NSObject {
    var identifier: String?
    var avatar: UIImage?
    var avatarUrl: String?
    var name: String?
    var style: TUIMemberInfoCellStyle?
    
    override init() {
        super.init()
    }
    
    init(identifier: String, avatar: UIImage? = nil, avatarUrl: String? = nil, name: String? = nil, style: TUIMemberInfoCellStyle) {
        self.identifier = identifier
        self.avatar = avatar
        self.avatarUrl = avatarUrl
        self.name = name
        self.style = style
    }
}
