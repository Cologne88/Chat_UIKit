import TIMCommon

public let SHEET_COMMON = 1
public let SHEET_AGREE = 2
public let SHEET_SEX = 3
public let SHEET_V2API = 4

struct TUISelectMemberOptionalStyle: OptionSet {
    let rawValue: Int

    static let none = TUISelectMemberOptionalStyle([])
    static let atAll = TUISelectMemberOptionalStyle(rawValue: 1 << 0)
    static let transferOwner = TUISelectMemberOptionalStyle(rawValue: 1 << 1)
    static let publicMan = TUISelectMemberOptionalStyle(rawValue: 1 << 2)
}

typealias SelectedFinished = (_ modelList: [TUIUserModel]) -> Void
