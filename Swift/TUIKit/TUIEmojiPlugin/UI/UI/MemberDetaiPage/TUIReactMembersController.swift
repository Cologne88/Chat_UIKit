//
//  TUIReactMembersController.swift
//  TUIChat
//
//  Created by wyl on 2022/10/31.
//  Copyright © 2023 Tencent. All rights reserved.
//

import UIKit
import TUIChat
import TIMCommon

class TUIChatMembersReactSubController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableView: UITableView = UITableView()
    var data: [TUIReactMemberCellData] = []
    var originData: TUIMessageCellData?
    var emojiClickCallback: ((TUIReactModel) -> Void)?
    
    var tableViewObservation: NSKeyValueObservation?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configTableView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configTableView()
    }
    
    func configTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        tableView.register(TUIReactMemberCell.self, forCellReuseIdentifier: "TUIReactMemberCell")
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        
        tableViewObservation = view.observe(\.frame, options: [.new]) { [weak self] (view, change) in
            guard let self = self else { return }
            self.tableView.frame = self.view.bounds
        }
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if data.count > indexPath.section {
            let cellData = data[indexPath.section]
            return cellData.cellHeight
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (tableView.dequeueReusableCell(withIdentifier: "TUIReactMemberCell") as? TUIReactMemberCell) ?? TUIReactMemberCell(style: .subtitle, reuseIdentifier: "TUIReactMemberCell")
        cell.selectionStyle = .none
        cell.fill(with: data[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellData = data[indexPath.row]
        if cellData.isCurrentUser {
            if let callback = emojiClickCallback {
                callback(cellData.tagModel ?? TUIReactModel())
            }
        }
    }
}

class TUIReactMembersController: TUIChatFlexViewController, V2TIMAdvancedMsgListener {
    var originData: TUIMessageCellData?
    var tagsArray: [TUIReactModel] = []
    
    var scrollview: TUIReactMembersSegementScrollView?
    var provider: TUIEmojiReactDataProvider?
    var tabItems: [TUIReactMembersSegementItem] = []
    var tabPageVCArray: [TUIChatMembersReactSubController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNormalBottom()
        provider = TUIEmojiReactDataProvider()
        loadList()
        registerTUIKitNotification()
        containerView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
        
        dealData()
        reloadData()
    }
    
    override func updateSubContainerView() {
        super.updateSubContainerView()
        scrollview?.frame = CGRect(x: 0,
                                   y: self.topGestureView.frame.size.height,
                                   width: self.containerView.frame.size.width,
                                   height: self.containerView.frame.size.height - self.topGestureView.frame.size.height)
        scrollview?.updateContainerView()
    }
    
    func loadList() {
        guard let origin = originData, let innerMsg = origin.innerMessage else { return }
        if provider == nil {
            provider = TUIEmojiReactDataProvider()
        }
        provider!.msgId = innerMsg.msgID
        
        provider!.getMessageReactions(messageList: [innerMsg], maxUserCountPerReaction: 5, succ: { [weak self] (_tagsArray: [TUIReactModel], _ tagsMap: [String: TUIReactModel]) in
            guard let self = self else { return }
            self.tagsArray = tagsArray
            self.dealData()
            self.reloadData()
        }, fail: nil)
        
        provider!.changed = { [weak self] (tagsArray: [TUIReactModel], tagsMap: [AnyHashable: Any]) in
            guard let self = self else { return }
            self.tagsArray = tagsArray
            self.dealData()
            self.reloadData()
            if tagsArray.count <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    func dealData() {
        tabItems = []
        var summaryCount = 0
        
        for tagsModel in tagsArray {
            let item = TUIReactMembersSegementItem()
            item.title = "\(tagsModel.followUserModels.count)"
            item.facePath = tagsModel.emojiPath
            tabItems.append(item)
            summaryCount += tagsModel.followUserModels.count
        }
        
        var pageTabCellDatasArray: [[TUIReactMemberCellData]] = []
        for tagsModel in tagsArray {
            var emojiCellDatas: [TUIReactMemberCellData] = []
            let followUserModels = tagsModel.followUserModels
            for userModel in followUserModels {
                let cellData = TUIReactMemberCellData()
                cellData.tagModel = tagsModel
                cellData.emojiName = tagsModel.emojiKey
                cellData.emojiPath = tagsModel.emojiPath
                cellData.faceURL = userModel.faceURL
                cellData.friendRemark = userModel.friendRemark
                cellData.nickName = userModel.nickName
                cellData.userID = userModel.userID
                if userModel.userID == TUILogin.getUserID() {
                    cellData.isCurrentUser = true
                }
                emojiCellDatas.append(cellData)
            }
            pageTabCellDatasArray.append(emojiCellDatas)
        }
        
        tabPageVCArray = []
        for i in 0..<tabItems.count {
            let subController = TUIChatMembersReactSubController()
            if i < pageTabCellDatasArray.count {
                subController.data = pageTabCellDatasArray[i]
            }
            subController.originData = originData
            subController.emojiClickCallback = { [weak self] (model: TUIReactModel) in
                guard let self = self, let innerMsg = self.originData?.innerMessage else { return }
                self.provider?.removeMessageReaction(v2Message: innerMsg, reactionID: model.emojiKey, succ: nil, fail: nil)
            }
            tabPageVCArray.append(subController)
        }
    }
    
    func reloadData() {
        scrollview?.removeFromSuperview()
        let frame =  CGRect(x: 0, y: self.topGestureView.frame.size.height,
                            width: self.containerView.frame.size.width,
                            height: self.containerView.frame.size.height - self.topGestureView.frame.size.height);
        let newScrollView = TUIReactMembersSegementScrollView(frame: frame, SegementItems: tabItems, viewArray: tabPageVCArray)
        scrollview = newScrollView
        containerView.addSubview(newScrollView)
    }
    
    func registerTUIKitNotification() {
        V2TIMManager.sharedInstance().addAdvancedMsgListener(listener: self)
    }
} 
