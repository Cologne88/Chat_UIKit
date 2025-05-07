//
//  TUIReactMemberCellData.swift
//  TUITagDemo
//
//  Created by wyl on 2022/5/12.
//  Copyright © 2022 TUI. All rights reserved.
//

import Foundation
import UIKit
import TIMCommon

public class TUIReactMemberCellData: NSObject {
    public var emojiName: String?
    public var emojiPath: String?
    public var friendRemark: String?
    public var nickName: String?
    public var faceURL: String?
    public var userID: String = ""
    
    public var isCurrentUser: Bool = false
    
    public var tagModel: TUIReactModel?
    
    public func displayName() -> String {
        if let friendRemark = friendRemark, !friendRemark.isEmpty {
            return friendRemark
        } else if let nickName = nickName, !nickName.isEmpty {
            return nickName
        } else {
            return userID
        }
    }
    
    public var cellHeight: CGFloat {
        return TUISwift.kScale390(72)
    }
} 
