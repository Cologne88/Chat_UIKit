import TIMCommon
import TUICore
import UIKit

public class TUIAboutUsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let titleView = TUINaviBarIndicatorView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        tableView.register(TUICommonTextCell.self, forCellReuseIdentifier: "textCell")
        tableView.tableFooterView = footerView
        return tableView
    }()

    private var data: [Any] = []
    private lazy var footerView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 200))
        appendSubViewForFooterView(footerView)
        return footerView
    }()

    // MARK: - Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        applyData()
    }

    private func setupView() {
        view.addSubview(tableView)
        titleView.setTitle(TUISwift.timCommonLocalizableString("TIMAppMeAbout"))
        navigationItem.titleView = titleView
        navigationItem.title = ""
    }

    private func applyData() {
        data.removeAll()
        let aboutUsUrl = "https://cloud.tencent.com/document/product/269/59590"
        let versionText = V2TIMManager.sharedInstance().getVersion()
        let versionData = TUICommonTextCellData()
        versionData.key = TUISwift.timCommonLocalizableString("TUIKitAboutUsSDKVersion")
        versionData.value = versionText
        versionData.showAccessory = false
        versionData.ext = ["event_type": "0"]

        let keysArray = [TUISwift.timCommonLocalizableString("TUIKitAboutUsContactUs")]
        let extssArray: [[String: String]] = [
            ["event_type": "101", "url": aboutUsUrl]
        ]

        var clickArray: [TUICommonTextCellData] = [versionData]

        for (index, key) in keysArray.enumerated() {
            let data = TUICommonTextCellData()
            data.key = key
            data.showAccessory = true
            data.ext = extssArray[index]
            data.cselector = #selector(click(_:))
            clickArray.append(data)
        }

        data.append(clickArray)
        tableView.reloadData()
    }

    private func appendSubViewForFooterView(_ footerView: UIView) {
        // PRIVATEMARK
        // You can draw content here, such as adding the company's homepage and contact information to the footer view.
    }

    // MARK: - Actions

    @objc private func click(_ data: Any?) {
        guard let cell = data as? TUICommonTextCell else { return }
        guard let dic = cell.data?.ext as? [String: String] else { return }
        let eventType = dic["event_type"]
        let urlStr = dic["url"] ?? ""
        let txt = dic["txt"] ?? ""

        switch eventType {
        case "101":
            if let url = URL(string: urlStr) {
                TUIUtil.openLinkWithURL(url)
            }
        case "102":
            showAlert(withText: txt)
        case "103":
            if let cls = NSClassFromString("TUICancelAccountViewController") as? UIViewController.Type {
                let vc = cls.init()
                navigationController?.pushViewController(vc, animated: true)
            }
        default:
            break
        }
    }

    private func showAlert(withText text: String) {
        let alertController = UIAlertController(title: TUISwift.timCommonLocalizableString("TUIKitAboutUsDisclaimer"),
                                                message: text,
                                                preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: TUISwift.timCommonLocalizableString("Accept"), style: .destructive, handler: nil)
        alertController.tuitheme_addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource

    public func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 10
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let array = data[section] as? [Any] else { return 0 }
        return array.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let array = data[indexPath.section] as? [TUICommonCellData] else { return 0 }
        let data = array[indexPath.row]
        return data.height(ofWidth: TUISwift.screen_Width())
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let array = data[indexPath.section] as? [TUICommonTextCellData] else { return UITableViewCell() }
        let data = array[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as? TUICommonTextCell {
            cell.fill(with: data)
            return cell
        }
        return UITableViewCell()
    }
}
