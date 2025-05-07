//
//  TUILanguageSelectController.m
//  TUIKitDemo
//
//  Created by harvy on 2022/1/6.
//  Copyright © 2022 Tencent. All rights reserved.
//

import SnapKit
import TIMCommon
import TUICore
import UIKit

typealias TUILanguageSelectCallback = (TUILanguageSelectCellModel) -> Void

public protocol TUILanguageSelectControllerDelegate: AnyObject {
    func onSelectLanguage(_ cellModel: TUILanguageSelectCellModel)
}

class TUILanguageSelectCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = "1233"
        label.textAlignment = TUISwift.isRTL() ? .right : .left
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()
    
    let detailNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.text = "1233"
        label.textAlignment = TUISwift.isRTL() ? .right : .left
        label.textColor = UIColor.gray
        return label
    }()
    
    let chooseIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TUISwift.timCommonBundleImage("default_choose")
        return imageView
    }()
    
    var cellModel: TUILanguageSelectCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            nameLabel.text = cellModel.languageName
            detailNameLabel.text = cellModel.nameInCurrentLanguage
            chooseIconView.isHidden = !cellModel.selected
            detailNameLabel.isHidden = cellModel.selected
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailNameLabel)
        contentView.addSubview(chooseIconView)
    }
    
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        chooseIconView.snp.remakeConstraints { make in
            make.centerY.equalTo(contentView)
            make.width.height.equalTo(20)
            make.trailing.equalTo(-16)
        }
        
        if detailNameLabel.isHidden {
            nameLabel.snp.remakeConstraints { make in
                make.leading.equalTo(16)
                make.trailing.equalTo(chooseIconView.snp.leading).offset(-2)
                make.height.equalTo(nameLabel.font.lineHeight)
                make.centerY.equalTo(contentView)
            }
        } else {
            nameLabel.snp.remakeConstraints { make in
                make.leading.equalTo(16)
                make.trailing.equalTo(chooseIconView.snp.leading).offset(-2)
                make.top.equalTo(3)
                make.height.equalTo(nameLabel.font.lineHeight)
            }
            
            detailNameLabel.snp.remakeConstraints { make in
                make.leading.equalTo(16)
                make.trailing.equalTo(chooseIconView.snp.leading).offset(-2)
                make.bottom.equalTo(-3)
                make.height.equalTo(nameLabel.font.lineHeight)
            }
        }
    }
}

public class TUILanguageSelectCellModel {
    var languageID: String?
    var displayName: String?
    var languageName: String?
    var nameInCurrentLanguage: String?
    var selected: Bool = false
}

public class TUILanguageSelectController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    public weak var delegate: TUILanguageSelectControllerDelegate?
    
    private let titleView = TUINaviBarIndicatorView()
    private var tableView: UITableView?
    private var datas = [TUILanguageSelectCellModel]()
    private var selectModel: TUILanguageSelectCellModel?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        prepareData()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = nil
            appearance.backgroundEffect = nil
            appearance.backgroundColor = tintColor
            navigationController?.navigationBar.backgroundColor = tintColor
            navigationController?.navigationBar.barTintColor = tintColor
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.backgroundColor = tintColor
            navigationController?.navigationBar.barTintColor = tintColor
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        navigationController?.view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        navigationController?.isNavigationBarHidden = false
    }
    
    private var tintColor: UIColor {
        return TUISwift.timCommonDynamicColor("head_bg_gradient_start_color", defaultColor: "#EBF0F6")
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    private func setupViews() {
        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true
        navigationController?.isNavigationBarHidden = false

        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMChangeLanguage"))
        navigationItem.titleView = titleView
        navigationItem.title = ""
        
        let image = TUISwift.timCommonDynamicImage("nav_back_img", defaultImage: UIImage.safeImage(TUISwift.tuiDemoImagePath("ic_back_white"))).rtlImageFlippedForRightToLeftLayoutDirection()
        let backButton = UIButton(type: .custom)
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.hidesBackButton = true
        
        tableView = UITableView(frame: view.bounds, style: UITableView.Style.grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.backgroundColor = UIColor.groupTableViewBackground
        tableView?.register(TUILanguageSelectCell.self, forCellReuseIdentifier: "cell")
        if let tableview = tableView {
            view.addSubview(tableview)
        }
    }
    
    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }
    
    private func prepareData() {
        let languageID = TUIGlobalization.tk_localizableLanguageKey()
        
        let chinese = TUILanguageSelectCellModel()
        chinese.languageID = "zh-Hans"
        chinese.languageName = "简体中文"
        chinese.nameInCurrentLanguage = TUISwift.timCommonLocalizableString("zh-Hans")
        chinese.selected = false
        
        let english = TUILanguageSelectCellModel()
        english.languageID = "en"
        english.languageName = "English"
        english.nameInCurrentLanguage = TUISwift.timCommonLocalizableString("en")
        english.selected = false
        
        let ar = TUILanguageSelectCellModel()
        ar.languageID = "ar"
        ar.languageName = "عربي"
        ar.nameInCurrentLanguage = TUISwift.timCommonLocalizableString("ar")
        ar.selected = false
        
        let traditionalChinese = TUILanguageSelectCellModel()
        traditionalChinese.languageID = "zh-Hant"
        traditionalChinese.languageName = "繁體中文"
        traditionalChinese.nameInCurrentLanguage = "繁體中文" // TUISwift.timCommonLocalizableString("zh-Hant")
        traditionalChinese.selected = false
        
        datas = [chinese, english, ar, traditionalChinese]
        
        for cellModel in datas {
            if cellModel.languageID == languageID {
                cellModel.selected = true
                selectModel = cellModel
                break
            }
        }
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = datas[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TUILanguageSelectCell {
            cell.cellModel = cellModel
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cellModel = datas[indexPath.row]
        
        if cellModel.languageID?.hasPrefix("ar") == true {
            TUIGlobalization.setRTLOption(true)
        } else {
            TUIGlobalization.setRTLOption(false)
        }
        
        TUIGlobalization.setPreferredLanguage(cellModel.languageID ?? "")
        TUITool.configIMErrorMap()
        
        selectModel?.selected = false
        cellModel.selected = true
        selectModel = cellModel
        tableView.reloadData()
        
        DispatchQueue.main.async { [weak self] in
            if let delegate = self?.delegate {
                delegate.onSelectLanguage(cellModel)
            }
        }
    }
}
