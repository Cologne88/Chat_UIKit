import Foundation
import ImSDK_Plus
import TIMCommon
import TUICore

class TUIFoldConversationListBaseDataProvider: TUIConversationListBaseDataProvider {
    lazy var needRemoveConversationList: [String] = {
        var needRemoveConversationList = [String]()
        return needRemoveConversationList
    }()

    override init() {
        super.init()
    }

    override func loadNexPageConversations() {
        if isLastPage {
            return
        }
        let filter = V2TIMConversationListFilter()
        filter.type = .GROUP
        filter.markType = V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_FOLD.rawValue

        V2TIMManager.sharedInstance().getConversationListByFilter(filter: filter, nextSeq: pageIndex, count: pageSize) { [weak self] list, nextSeq, isFinished in
            guard let self = self, let list = list else { return }
            self.pageIndex = nextSeq
            self.isLastPage = isFinished
            self.preprocess(list)
        } fail: { [weak self] _, _ in
            guard let self = self else { return }
            self.isLastPage = true
        }
    }

    override func preprocess(_ v2Convs: [V2TIMConversation]) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.preprocess(v2Convs)
            }
            return
        }

        var conversationMap = [String: Int]()
        for item in conversationList {
            if let conversationID = item.conversationID {
                conversationMap[conversationID] = conversationList.firstIndex(of: item)
            }
        }

        var duplicateDataList = [TUIConversationCellData]()
        var addedDataList = [TUIConversationCellData]()
        var markHideDataList = [TUIConversationCellData]()
        var needHideByCancelMarkFoldDataList = [TUIConversationCellData]()

        for conv in v2Convs {
            if filteConversation(conv) {
                continue
            }

            if TUIConversationCellData.isMarkedByHideType(conv.markList) {
                markHideDataList.append(cellDataForConversation(conv))
                continue
            }

            let cellData = cellDataForConversation(conv)
            if TUIConversationCellData.isMarkedByFoldType(conv.markList) {
                if let _ = conversationMap[cellData.conversationID!] {
                    duplicateDataList.append(cellData)
                } else {
                    addedDataList.append(cellData)
                }
            } else {
                if let _ = conversationMap[cellData.conversationID!] {
                    needHideByCancelMarkFoldDataList.append(cellData)
                }
            }
        }

        if !duplicateDataList.isEmpty {
            sortDataList(&duplicateDataList)
            handleUpdateConversationList(duplicateDataList, positions: conversationMap)
        }

        if !addedDataList.isEmpty {
            sortDataList(&addedDataList)
            handleInsertConversationList(addedDataList)
        }

        if !markHideDataList.isEmpty {
            sortDataList(&markHideDataList)
            var pRemoveCellUIList = [TUIConversationCellData]()
            var pMarkHideDataMap = [String: TUIConversationCellData]()
            for item in markHideDataList {
                if let conversationID = item.conversationID {
                    pRemoveCellUIList.append(item)
                    pMarkHideDataMap[conversationID] = item
                }
            }
            for item in conversationList {
                if let _ = pMarkHideDataMap[item.conversationID!] {
                    pRemoveCellUIList.append(item)
                }
            }
            for item in pRemoveCellUIList {
                handleHideConversation(item)
            }
        }

        if !needHideByCancelMarkFoldDataList.isEmpty {
            sortDataList(&needHideByCancelMarkFoldDataList)
            var pRemoveCellUIList = [TUIConversationCellData]()
            var pMarkCancelFoldDataMap = [String: TUIConversationCellData]()
            for item in needHideByCancelMarkFoldDataList {
                if let conversationID = item.conversationID {
                    pRemoveCellUIList.append(item)
                    pMarkCancelFoldDataMap[conversationID] = item
                }
            }
            for item in conversationList {
                if let _ = pMarkCancelFoldDataMap[item.conversationID!] {
                    pRemoveCellUIList.append(item)
                }
            }
            for item in pRemoveCellUIList {
                handleHideConversation(item)
            }
        }
    }

    func handleRemoveConversation(_ conversation: TUIConversationCellData) {
        guard let index = conversationList.firstIndex(of: conversation) else { return }

        conversationList.remove(at: index)
        delegate?.deleteConversation(at: [IndexPath(row: index, section: 0)])

        let deleteAction: () -> Void = {
            V2TIMManager.sharedInstance().deleteConversation(conversation: conversation.conversationID, succ: { [weak self] in
                guard let self = self else { return }
                self.updateMarkUnreadCount()
            }, fail: nil)
        }

        V2TIMManager.sharedInstance().markConversation(conversationIDList: [conversation.conversationID], markType: NSNumber(value: V2TIMConversationMarkType.CONVERSATION_MARK_TYPE_FOLD.rawValue), enableMark: false, succ: { _ in
            deleteAction()
        }, fail: { _, _ in
            deleteAction()
        })

        self.needRemoveConversationList.append(conversation.conversationID!)
    }
}
