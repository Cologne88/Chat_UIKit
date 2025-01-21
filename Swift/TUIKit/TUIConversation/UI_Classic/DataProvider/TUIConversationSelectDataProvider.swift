import Foundation

class TUIConversationSelectDataProvider: TUIConversationSelectBaseDataProvider {
    
    override func getConversationCellClass() -> AnyClass {
        return TUIConversationCellData.self
    }
}
