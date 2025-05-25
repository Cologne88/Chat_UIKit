import TIMCommon
import UIKit

protocol TUISearchBarDelegate_Minimalist: AnyObject {
    func searchBarDidEnterSearch(_ searchBar: TUISearchBar_Minimalist)
    func searchBarDidCancelClicked(_ searchBar: TUISearchBar_Minimalist)
    func searchBar(_ searchBar: TUISearchBar_Minimalist, searchText: String)
}

public class TUISearchBar_Minimalist: UIView, UISearchBarDelegate {
    private(set) var searchBar: UISearchBar = .init()
    weak var delegate: TUISearchBarDelegate_Minimalist?
    weak var parentVC: UIViewController?
    
    private var isEntrance: Bool = false
    
    func setEntrance(_ isEntrance: Bool) {
        self.isEntrance = isEntrance
        setupViews()
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
            searchBar.searchTextField.backgroundColor = TUISwift.rgba(246, g: 246, b: 246, a: 1)
        }
        addSubview(searchBar)
        enableCancelButton()
    }
    
    private func bgColorOfSearchBar() -> UIColor {
        return TUISwift.rgba(255, g: 255, b: 255, a: 1)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = CGRect(x: 10, y: 5, width: frame.width - 20, height: frame.height - 10)
        updateSearchIcon()
    }
    
    private func updateSearchIcon() {
        if searchBar.isFirstResponder || !(searchBar.text?.isEmpty ?? true) || !isEntrance {
            backgroundColor = superview?.backgroundColor
        } else {
            backgroundColor = bgColorOfSearchBar()
        }
        searchBar.setPositionAdjustment(UIOffset.zero, for: .search)
    }
    
    private func enableCancelButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let cancelBtn = self.searchBar.value(forKey: "cancelButton") as? UIButton {
                cancelBtn.isEnabled = true
                cancelBtn.isUserInteractionEnabled = true
                cancelBtn.setTitleColor(.systemBlue, for: .normal)
                UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = TUISwift.timCommonLocalizableString("TUIKitSearchItemCancel")
            }
        }
    }
    
    // MARK: - UISearchBarDelegate

    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        showSearchVC()
        
        if isEntrance {
            delegate?.searchBarDidEnterSearch(self)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateSearchIcon()
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
    
    private func showSearchVC() {
        let vc = TUISearchViewController_Minimalist()
        let nav = TUINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        
        parentVC?.present(nav, animated: false, completion: nil)
    }
}
