import TIMCommon
import UIKit

protocol TUISearchBarDelegate: AnyObject {
    func searchBarDidEnterSearch(_ searchBar: TUISearchBar)
    func searchBarDidCancelClicked(_ searchBar: TUISearchBar)
    func searchBar(_ searchBar: TUISearchBar, searchText: String)
}

public class TUISearchBar: UIView, UISearchBarDelegate {
    private(set) var searchBar = UISearchBar()
    private var isEntrance = false
    weak var delegate: TUISearchBarDelegate?
    weak var parentVC: UIViewController?

    func setEntrance(_ isEntrance: Bool) {
        self.isEntrance = isEntrance
        setupViews()
    }

    private func bgColorOfSearchBar() -> UIColor {
        return TUISwift.timCommonDynamicColor("head_bg_gradient_start_color", defaultColor: "#EBF0F6")
    }

    private func setupViews() {
        backgroundColor = bgColorOfSearchBar()
        searchBar.placeholder = TUISwift.timCommonLocalizableString("Search")
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = .red
        searchBar.showsCancelButton = !isEntrance
        searchBar.delegate = self
        searchBar.searchTextField.textAlignment = TUISwift.isRTL() ? .right : .left
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = TUISwift.timCommonDynamicColor("search_textfield_bg_color", defaultColor: "#FEFEFE")
        }
        addSubview(searchBar)
        enableCancelButton()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = CGRect(x: 10, y: 5, width: frame.width - 20, height: frame.height - 10)
        updateSearchIcon()
    }

    private func updateSearchIcon() {
        if searchBar.isFirstResponder || !(searchBar.text?.isEmpty ?? true) || !isEntrance {
            searchBar.setPositionAdjustment(.zero, for: .search)
            backgroundColor = superview?.backgroundColor
        } else {
            searchBar.setPositionAdjustment(UIOffset(horizontal: 0.5 * (frame.width - 20) - 40, vertical: 0), for: .search)
            backgroundColor = bgColorOfSearchBar()
        }
    }

    private func showSearchVC() {
        let vc = TUISearchViewController()
        let nav = TUINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = UIModalPresentationStyle.fullScreen

        parentVC?.present(nav, animated: false, completion: nil)
    }

    // MARK: - UISearchBarDelegate

    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        showSearchVC()

        if isEntrance {
            delegate?.searchBarDidEnterSearch(self)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateSearchIcon()
        }
        return !isEntrance
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchBarDidCancelClicked(self)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchBar(self, searchText: searchBar.text ?? "")
    }

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.searchBar(self, searchText: searchText)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        enableCancelButton()
    }

    private func enableCancelButton() {
        DispatchQueue.main.async {
            if let cancelBtn = self.searchBar.value(forKeyPath: "cancelButton") as? UIButton {
                for subview in cancelBtn.subviews {
                    if let button = subview as? UIButton {
                        button.isUserInteractionEnabled = true
                        button.isEnabled = true
                    }
                }
                cancelBtn.isEnabled = true
                cancelBtn.isUserInteractionEnabled = true
                cancelBtn.setTitleColor(.systemBlue, for: .normal)
            }

            UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("TUIKitSearchItemCancel")
        }
    }
}
