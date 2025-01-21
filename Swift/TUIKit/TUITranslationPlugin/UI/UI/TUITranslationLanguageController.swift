// TUITranslationLanguageController.swift
// TUITranslation
//
// Created by xia on 2023/4/7.
// Copyright © 2023 Tencent. All rights reserved.

import TIMCommon
import UIKit

class TUITranslationLanguageController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var onSelectedLanguage: ((String) -> Void)?
    
    private let languageCodeList: [String] = [
        "zh", "zh-TW", "en", "ja", "ko", "fr", "es", "it", "de", "tr", "ru", "pt", "vi", "id", "th", "ms", "hi"
    ]
    
    private let languageNameList: [String] = [
        "简体中文", "繁體中文", "English", "日本語", "한국어", "Français", "Español", "Italiano", "Deutsch", "Türkçe", "Русский", "Português",
        "Tiếng Việt", "Bahasa Indonesia", "ภาษาไทย", "Bahasa Melayu", "हिन्दी"
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds)
        tableView.delaysContentTouches = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 55
        tableView.register(TUICommonTextCell.self, forCellReuseIdentifier: "textCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private var currentIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = TUISwift.timCommonLocalizableString("TranslateMessage")
        view.addSubview(tableView)
    }
    
    // MARK: - UITableView DataSource & Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languageNameList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < languageNameList.count else {
            return UITableViewCell()
        }
        let language = languageNameList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath)
        cell.textLabel?.text = language
        if language == TUITranslationConfig.shared.targetLanguageName {
            cell.accessoryType = .checkmark
            currentIndex = indexPath
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < languageNameList.count, indexPath.row < languageCodeList.count else {
            return
        }
        if indexPath == currentIndex {
            return
        }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        if let lastCell = tableView.cellForRow(at: currentIndex ?? indexPath) {
            lastCell.accessoryType = .none
        }
        currentIndex = indexPath
        
        TUITranslationConfig.shared.targetLanguageCode = languageCodeList[indexPath.row]
        onSelectedLanguage?(languageNameList[indexPath.row])
    }
}
