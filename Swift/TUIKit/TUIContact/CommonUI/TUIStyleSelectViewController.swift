import SnapKit
import TIMCommon
import UIKit

let kTUIKitFirstInitAppStyleID = "Classic" // Classic / Minimalist

class TUIStyleSelectCell: UITableViewCell {
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.text = "1233"
        label.textAlignment = TUISwift.isRTL() ? .right : .left
        label.textColor = TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
        return label
    }()

    let chooseIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TUISwift.timCommonBundleImage("default_choose")
        return imageView
    }()

    var cellModel: TUIStyleSelectCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            nameLabel.text = cellModel.styleName
            nameLabel.textColor = cellModel.selected ? UIColor(red: 0/255, green: 110/255, blue: 255/255, alpha: 1) : TUISwift.timCommonDynamicColor("form_title_color", defaultColor: "#000000")
            chooseIconView.isHidden = !cellModel.selected
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

        nameLabel.snp.remakeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(chooseIconView.snp.leading).offset(-2)
            make.height.equalTo(nameLabel.font.lineHeight)
            make.centerY.equalTo(contentView)
        }
    }
}

@objc public class TUIStyleSelectCellModel: NSObject {
    public var styleID: String?
    var styleName: String?
    var selected: Bool = false
}

public protocol TUIStyleSelectControllerDelegate: AnyObject {
    func onSelectStyle(_ cellModel: TUIStyleSelectCellModel)
}

public class TUIStyleSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    public weak var delegate: TUIStyleSelectControllerDelegate?

    private let titleView = TUINaviBarIndicatorView()
    private var datas = [TUIStyleSelectCellModel]()
    private var selectModel: TUIStyleSelectCellModel?

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#FFFFFF")
        tableView.register(TUIStyleSelectCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

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
        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppSelectStyle"))
        navigationItem.titleView = titleView
        navigationItem.title = ""

        let image = UIImage.safeImage("ic_back_white").withRenderingMode(.alwaysOriginal).rtlImageFlippedForRightToLeftLayoutDirection()
        let backButton = UIButton(type: .custom)
        backButton.setImage(image, for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.hidesBackButton = true

        view.addSubview(tableView)
    }

    @objc private func back() {
        navigationController?.popViewController(animated: true)
    }

    private func prepareData() {
        let classic = TUIStyleSelectCellModel()
        classic.styleID = "Classic"
        classic.styleName = TUISwift.timCommonLocalizableString("TUIKitClassic")
        classic.selected = false

        let mini = TUIStyleSelectCellModel()
        mini.styleID = "Minimalist"
        mini.styleName = TUISwift.timCommonLocalizableString("TUIKitMinimalist")
        mini.selected = false

        datas = [classic, mini]

        if let styleID = UserDefaults.standard.string(forKey: "StyleSelectkey") {
            for cellModel in datas {
                if cellModel.styleID == styleID {
                    cellModel.selected = true
                    selectModel = cellModel
                    break
                }
            }
        }
    }

    // UITableViewDelegate, UITableViewDataSource methods
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? TUIStyleSelectCell ?? TUIStyleSelectCell(style: .default, reuseIdentifier: "cell")
        cell.cellModel = cellModel
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let cellModel = datas[indexPath.row]

        UserDefaults.standard.setValue(cellModel.styleID, forKey: "StyleSelectkey")
        UserDefaults.standard.synchronize()

        selectModel?.selected = false
        cellModel.selected = true
        selectModel = cellModel
        tableView.reloadData()

        DispatchQueue.main.async { [weak self] in
            if let delegate = self?.delegate {
                delegate.onSelectStyle(cellModel)
            }
        }
    }

    public func setBackGroundColor(_ color: UIColor) {
        view.backgroundColor = color
        tableView.backgroundColor = color
    }

    static func getCurrentStyleSelectID() -> String {
        if let styleID = UserDefaults.standard.string(forKey: "StyleSelectkey"), !styleID.isEmpty {
            return styleID
        } else {
            let initStyleID = kTUIKitFirstInitAppStyleID
            UserDefaults.standard.setValue(initStyleID, forKey: "StyleSelectkey")
            UserDefaults.standard.synchronize()
            return initStyleID
        }
    }

    public static func isClassicEntrance() -> Bool {
        let styleID = getCurrentStyleSelectID()
        return styleID == "Classic"
    }
}
