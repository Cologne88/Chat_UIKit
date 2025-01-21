import TIMCommon
import TUICore

class TUIGroupProfileCardCellData_Minimalist: TUIProfileCardCellData {
    weak var delegate: TUIGroupInfoDataProviderDelegate?

    override init() {
        super.init()
    }

    override func height(ofWidth width: CGFloat) -> CGFloat {
        return TUISwift.kScale390(329)
    }
}
