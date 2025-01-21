import TIMCommon
import UIKit

public protocol TUIThemeSelectControllerDelegate: AnyObject {
    func onSelectTheme(_ cellModel: TUIThemeSelectCollectionViewCellModel)
}

public class TUIThemeSelectCollectionViewCellModel: NSObject {
    public var backImage: UIImage?
    public var startColor: UIColor?
    public var endColor: UIColor?
    public var selected: Bool = false
    public var themeName: String?
    public var themeID: String?
}

class TUIThemeSelectCollectionViewCell: UICollectionViewCell {
    var onSelect: ((TUIThemeSelectCollectionViewCellModel) -> Void)?

    lazy var backView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var chooseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("add_unselect"))), for: .normal)
        button.setImage(TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("add_selected"))), for: .selected)
        button.isUserInteractionEnabled = false
        return button
    }()

    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        label.textAlignment = .center
        return label
    }()

    var cellModel: TUIThemeSelectCollectionViewCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            chooseButton.isSelected = cellModel.selected
            descLabel.text = cellModel.themeName
            backView.image = cellModel.backImage
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))

        contentView.addSubview(backView)
        contentView.addSubview(chooseButton)
        contentView.addSubview(descLabel)
    }

    @objc private func onTap() {
        if let cellModel = cellModel {
            onSelect?(cellModel)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backView.frame = contentView.bounds
        chooseButton.frame = CGRect(x: contentView.frame.width - 26, y: 6, width: 20, height: 20)
        descLabel.frame = CGRect(x: 0, y: contentView.frame.height - 28, width: contentView.frame.width, height: 28)
    }
}

class TUIThemeHeaderCollectionViewCell: UICollectionViewCell {
    var onSelect: ((TUIThemeSelectCollectionViewCellModel) -> Void)?
    private var switcher: UISwitch = .init()
    private var titleLabel: UILabel = .init()
    private var subTitleLabel: UILabel = .init()

    var cellModel: TUIThemeSelectCollectionViewCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            titleLabel.text = TUISwift.timCommonLocalizableString("TUIKitThemeNameSystemFollowTitle")
            subTitleLabel.text = TUISwift.timCommonLocalizableString("TUIKitThemeNameSystemFollowSubTitle")
            switcher.isOn = cellModel.selected

            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
            layoutIfNeeded()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    private func setupBaseViews() {
        contentView.layer.cornerRadius = 5.0
        contentView.layer.masksToBounds = true
        backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")

        titleLabel.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        titleLabel.font = UIFont.systemFont(ofSize: 16.0)
        titleLabel.rtlAlignment = .leading
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)

        subTitleLabel.textColor = TUISwift.timCommonDynamicColor("form_desc_color", defaultColor: "#888888")
        subTitleLabel.rtlAlignment = .leading
        subTitleLabel.font = UIFont.systemFont(ofSize: 12.0)
        subTitleLabel.backgroundColor = .clear
        subTitleLabel.numberOfLines = 0
        contentView.addSubview(subTitleLabel)

        switcher.onTintColor = TUISwift.timCommonDynamicColor("common_switch_on_color", defaultColor: "#147AFF")
        switcher.addTarget(self, action: #selector(switchClick(_:)), for: .valueChanged)
        contentView.addSubview(switcher)
    }

    override func updateConstraints() {
        super.updateConstraints()

        titleLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(TUISwift.kScale375(24))
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(switcher.snp.leading).offset(-3)
            make.height.equalTo(20)
        }

        subTitleLabel.sizeToFit()
        subTitleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(switcher.snp.leading)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.bottom.equalTo(contentView.snp.bottom)
        }

        switcher.snp.remakeConstraints { make in
            make.trailing.equalTo(contentView.snp.trailing).offset(-TUISwift.kScale375(24))
            make.top.equalTo(titleLabel)
            make.width.equalTo(35)
            make.height.equalTo(20)
        }
    }

    @objc private func switchClick(_ sender: UISwitch) {
        if let cellModel = cellModel {
            onSelect?(cellModel)
        }
        setNeedsUpdateConstraints()
        updateConstraintsIfNeeded()
        layoutIfNeeded()
        backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")
    }
}

public class TUIThemeSelectController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    public weak var delegate: TUIThemeSelectControllerDelegate?
    public var disable: Bool = false
    private var titleView: TUINaviBarIndicatorView = .init()
    private var datas: [TUIThemeSelectCollectionViewCellModel] = []
    private var selectModel: TUIThemeSelectCollectionViewCellModel?
    private var systemModel: TUIThemeSelectCollectionViewCellModel?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (UIScreen.main.bounds.size.width - 12.0 - 32.0) * 0.5
        let itemHeight = itemWidth * 232.0 / 331.0
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        if !TUIThemeSelectController.gDisableFollowSystemStyle {
            layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.size.width, height: 120)
        }

        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(TUIThemeSelectCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(TUIThemeHeaderCollectionViewCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.backgroundColor = TUISwift.timCommonDynamicColor("form_bg_color", defaultColor: "#FFFFFF")

        return collectionView
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        prepareData()
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: NSNotification.Name(rawValue: TUIDidApplyingThemeChangedNotfication), object: nil)
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

    var tintColor: UIColor {
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
        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppChangeTheme"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        var image = TUISwift.timCommonDynamicImage("nav_back_img", defaultImage: UIImage(named: TUISwift.timCommonImagePath("nav_back")))
        image = image?.withRenderingMode(.alwaysOriginal)
        image = image?.rtl_imageFlippedForRightToLeftLayoutDirection()
        let backButton = UIButton(type: .custom)
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.hidesBackButton = true

        view.addSubview(collectionView)
    }

    private func prepareData() {
        let lastThemeID = Self.getCacheThemeID()
        var isSystemDark = false
        var isSystemLight = false
        if #available(iOS 13.0, *) {
            if lastThemeID == "system" {
                if traitCollection.userInterfaceStyle == .dark {
                    isSystemDark = true
                } else {
                    isSystemLight = true
                }
            }
        }

        let system = TUIThemeSelectCollectionViewCellModel()
        system.backImage = imageWithColors(["#FEFEFE", "#FEFEFE"])
        system.themeID = "system"
        system.themeName = TUISwift.timCommonLocalizableString("TUIKitThemeNameSystem")
        system.selected = lastThemeID == system.themeID
        systemModel = system

        let serious = TUIThemeSelectCollectionViewCellModel()
        serious.backImage = TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("theme_cover_serious")))
        serious.themeID = "serious"
        serious.themeName = TUISwift.timCommonLocalizableString("TUIKitThemeNameSerious")
        serious.selected = lastThemeID == serious.themeID

        let light = TUIThemeSelectCollectionViewCellModel()
        light.backImage = TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("theme_cover_light")))
        light.themeID = "light"
        light.themeName = TUISwift.timCommonLocalizableString("TUIKitThemeNameLight")
        light.selected = (lastThemeID == light.themeID || isSystemLight)

        let mingmei = TUIThemeSelectCollectionViewCellModel()
        mingmei.backImage = TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("theme_cover_lively")))
        mingmei.themeID = "lively"
        mingmei.themeName = TUISwift.timCommonLocalizableString("TUIKitThemeNameLivey")
        mingmei.selected = lastThemeID == mingmei.themeID

        let dark = TUIThemeSelectCollectionViewCellModel()
        dark.backImage = TUISwift.tuiContactDynamicImage("", defaultImage: UIImage(named: TUISwift.tuiContactImagePath("theme_cover_dark")))
        dark.themeID = "dark"
        dark.themeName = TUISwift.timCommonLocalizableString("TUIKitThemeNameDark")
        dark.selected = (lastThemeID == dark.themeID || isSystemDark)

        datas = [light, serious, mingmei, dark]

        for cellModel in datas {
            if cellModel.selected {
                selectModel = cellModel
                break
            }
        }

        if TUIThemeSelectController.gDisableFollowSystemStyle {
            return
        }

        if selectModel == nil || lastThemeID == "system" {
            selectModel = system
        }
    }

    @objc private func back() {
        if disable {
            return
        }
        navigationController?.popViewController(animated: true)
    }

    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.frame = view.bounds
    }

    static func cacheThemeID(_ themeID: String) {
        UserDefaults.standard.set(themeID, forKey: "current_theme_id")
        UserDefaults.standard.synchronize()
    }

    static func getCacheThemeID() -> String {
        let lastThemeID = UserDefaults.standard.string(forKey: "current_theme_id") ?? "system"
        return lastThemeID
    }

    static func changeFollowSystemChangeThemeSwitch(_ flag: Bool) {
        UserDefaults.standard.set(flag ? "0" : "1", forKey: "followSystemChangeThemeSwitch")
        UserDefaults.standard.synchronize()
    }

    static func followSystemChangeThemeSwitch() -> Bool {
        if getCacheThemeID() == "system" {
            return true
        }
        let followSystemChangeThemeSwitch = UserDefaults.standard.string(forKey: "followSystemChangeThemeSwitch")
        return followSystemChangeThemeSwitch == "1"
    }

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return datas.count
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = TUIThemeHeaderCollectionViewCell()
        if !TUIThemeSelectController.gDisableFollowSystemStyle && kind == UICollectionView.elementKindSectionHeader {
            let changeThemeswitch = Self.followSystemChangeThemeSwitch()
            let system = TUIThemeSelectCollectionViewCellModel()
            system.selected = changeThemeswitch
            if let headerview = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView", for: indexPath) as? TUIThemeHeaderCollectionViewCell {
                headerview.cellModel = system
                headerview.onSelect = { [weak self] cellModel in
                    guard let self else { return }
                    self.onSelectFollowSystem(cellModel)
                }
                reusableView = headerview
            }
        }
        return reusableView
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellModel = datas[indexPath.item]
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? TUIThemeSelectCollectionViewCell {
            cell.cellModel = cellModel
            cell.onSelect = { [weak self] cellModel in
                guard let self else { return }
                self.onSelectTheme(cellModel)
            }
            return cell
        }
        return UICollectionViewCell()
    }

    private func onSelectFollowSystem(_ cellModel: TUIThemeSelectCollectionViewCellModel) {
        Self.changeFollowSystemChangeThemeSwitch(cellModel.selected)

        if cellModel.selected {
            for cellModel in datas {
                if cellModel.selected {
                    selectModel = cellModel
                    break
                }
            }
            onSelectTheme(selectModel!)
        } else {
            onSelectTheme(systemModel!)
        }
    }

    private func onSelectTheme(_ cellModel: TUIThemeSelectCollectionViewCellModel) {
        if disable {
            return
        }
        if cellModel.themeID != "system" {
            Self.changeFollowSystemChangeThemeSwitch(true)
        }

        selectModel?.selected = false
        cellModel.selected = true
        selectModel = cellModel
        collectionView.reloadData()

        Self.cacheThemeID(selectModel!.themeID!)

        Self.applyTheme(selectModel!.themeID)

        delegate?.onSelectTheme(selectModel!)
    }

    static var gDisableFollowSystemStyle: Bool = false

    public static func disableFollowSystemStyle() {
        gDisableFollowSystemStyle = true
    }

    public static func applyLastTheme() {
        applyTheme(nil)
    }

    public static func applyTheme(_ themeID: String?) {
        var lastThemeID = getCacheThemeID()
        if let themeID = themeID, !themeID.isEmpty {
            lastThemeID = themeID
        }

        if lastThemeID.isEmpty || lastThemeID == "system" {
            TUIThemeManager.share().unApplyTheme(for: .all)
        } else {
            TUIThemeManager.share().applyTheme(lastThemeID, for: .all)
        }

        if gDisableFollowSystemStyle {
            return
        }

        DispatchQueue.main.async {
            if #available(iOS 13.0, *) {
                if lastThemeID.isEmpty || lastThemeID == "system" {
                    TUITool.applicationKeywindow()?.overrideUserInterfaceStyle = .unspecified
                } else if lastThemeID == "dark" {
                    TUITool.applicationKeywindow()?.overrideUserInterfaceStyle = .dark
                } else {
                    TUITool.applicationKeywindow()?.overrideUserInterfaceStyle = .light
                }
            }
        }
    }

    static func getLastThemeName() -> String {
        let themeID = getCacheThemeID()
        switch themeID {
        case "system":
            return TUISwift.timCommonLocalizableString("TUIKitThemeNameSystem")
        case "serious":
            return TUISwift.timCommonLocalizableString("TUIKitThemeNameSerious")
        case "light":
            return TUISwift.timCommonLocalizableString("TUIKitThemeNameLight")
        case "lively":
            return TUISwift.timCommonLocalizableString("TUIKitThemeNameLivey")
        case "dark":
            return TUISwift.timCommonLocalizableString("TUIKitThemeNameDark")
        default:
            return ""
        }
    }

    private func imageWithColors(_ hexColors: [String]) -> UIImage? {
        let imageSize = CGSize(width: 165, height: 116)
        let colors = hexColors.compactMap { UIColor.tui_color(withHex: $0).cgColor }
        let locations: [CGFloat] = [0.5, 1.0]

        UIGraphicsBeginImageContextWithOptions(imageSize, true, 1)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.saveGState()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else { return nil }
        let start = CGPoint(x: 0.0, y: 0.0)
        let end = CGPoint(x: imageSize.width, y: imageSize.height)
        context.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        context.restoreGState()
        UIGraphicsEndImageContext()
        return image
    }

    public func setBackGroundColor(_ color: UIColor) {
        view.backgroundColor = color
        collectionView.backgroundColor = color
    }

    @objc private func onThemeChanged() {
        DispatchQueue.main.async {
            self.prepareData()
            self.collectionView.reloadData()
        }
    }
}
