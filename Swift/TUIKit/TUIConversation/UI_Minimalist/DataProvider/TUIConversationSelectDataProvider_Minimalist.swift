import Foundation

class TUIConversationSelectDataProvider_Minimalist: TUIConversationSelectBaseDataProvider {
    
    override func getConversationCellClass() -> AnyClass {
        return TUIConversationCellData_Minimalist.self
    }
}
