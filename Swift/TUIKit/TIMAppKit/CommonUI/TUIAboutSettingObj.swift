// TUIAboutSettingObj.swift
// TUIKitDemo
//
// Created by wyl on 2022/2/9.
// Copyright © 2022 Tencent. All rights reserved.

import Foundation

class TUIAboutSettingObj {
    let title: String?
    let subtitle: String?
    let cellClass: AnyClass
    let cellHeight: Int

    init(title: String? = nil, subtitle: String? = nil, cellClass: AnyClass = NSObject.self) {
        self.title = title
        self.subtitle = subtitle
        self.cellClass = cellClass
        self.cellHeight = 52
    }
}
