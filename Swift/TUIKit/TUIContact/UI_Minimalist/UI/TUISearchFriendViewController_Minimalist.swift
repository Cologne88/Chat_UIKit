// TUISearchFriendViewController_Minimalist.swift
// TUIContact

import TIMCommon
import UIKit

class TUISearchFriendViewController_Minimalist: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    var searchController: UISearchController!
    var userView: AddFriendUserView_Minimalist!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = TUISwift.timCommonLocalizableString("ContactsAddFriends")

        self.view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")

        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
        self.definesPresentationContext = true

        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.delegate = self
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = TUISwift.timCommonLocalizableString("SearchGroupPlaceholder")
        self.view.addSubview(self.searchController.searchBar)
        self.searchController.searchBar.sizeToFit()
        self.setSearchIconCenter(center: true)

        self.userView = AddFriendUserView_Minimalist(frame: .zero)
        self.view.addSubview(self.userView)

        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(self.handleUserTap(_:)))
        self.userView.addGestureRecognizer(singleFingerTap)
    }

    func setSearchIconCenter(center: Bool) {
        if center {
            let size = self.searchController.searchBar.placeholder?.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
            let width = (size?.width ?? 0) + 60
            self.searchController.searchBar.setPositionAdjustment(UIOffset(horizontal: 0.5 * (self.searchController.searchBar.bounds.size.width - width), vertical: 0), for: .search)
        } else {
            self.searchController.searchBar.setPositionAdjustment(.zero, for: .search)
        }
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        self.setSearchIconCenter(center: false)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        print("didPresentSearchController")
        self.view.addSubview(self.searchController.searchBar)

        self.searchController.searchBar.frame.origin.y = self.safeAreaTopGap()
        self.userView.frame = CGRect(x: 0, y: self.searchController.searchBar.frame.maxY, width: TUISwift.screen_Width(), height: 44)
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.setSearchIconCenter(center: true)
    }

    func safeAreaTopGap() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaInsets.top
        } else {
            return 0
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        print("didDismissSearchController")
        self.searchController.searchBar.frame.origin.y = 0
        self.userView.profile = nil
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let inputStr = searchController.searchBar.text else { return }
        print("search \(inputStr)")
        V2TIMManager.sharedInstance().getUsersInfo([inputStr], succ: { [weak self] infoList in
            guard let self = self, let infoList = infoList else { return }
            self.userView.profile = infoList.first
        }, fail: { [weak self] _, _ in
            guard let self = self else { return }
            self.userView.profile = nil
        })
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.searchController.isActive = true
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchController.isActive = false
    }

    @objc func handleUserTap(_ sender: Any) {
        if let userID = self.userView.profile?.userID, !userID.isEmpty {
            let frc = TUIFriendRequestViewController_Minimalist()
            frc.profile = self.userView.profile
            self.navigationController?.pushViewController(frc, animated: true)
        }
    }
}

class AddFriendUserView_Minimalist: UIView {
    var profile: V2TIMUserFullInfo? {
        didSet {
            if let profile = profile {
                self._idLabel.text = profile.userID
                self._idLabel.sizeToFit()
                self._idLabel.center = CGPoint(x: 8, y: self.center.y)
                self._line.frame = CGRect(x: 0, y: self.bounds.height - 1, width: self.bounds.width, height: 1)
                self._line.isHidden = false
            } else {
                self._idLabel.text = ""
                self._line.isHidden = true
            }
        }
    }

    private let _idLabel: UILabel
    private let _line: UIView

    override init(frame: CGRect) {
        self._idLabel = UILabel(frame: .zero)
        self._line = UIView(frame: .zero)
        self._line.backgroundColor = .gray

        super.init(frame: frame)

        self.addSubview(self._idLabel)
        self.addSubview(self._line)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
