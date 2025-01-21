// TUISearchGroupViewController_Minimalist.swift
// TUIContact

import UIKit
import TIMCommon

class TUISearchGroupViewController_Minimalist: UIViewController, UISearchControllerDelegate, UISearchBarDelegate {

    var searchController: UISearchController?
    var userView: AddGroupItemView_Minimalist?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = TUISwift.timCommonLocalizableString("ContactsJoinGroup")
        self.view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
        self.definesPresentationContext = true
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.delegate = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = "group ID"
        searchController?.searchBar.delegate = self
        if let searchBar = searchController?.searchBar {
            self.view.addSubview(searchBar)
        }
        setSearchIconCenter(center: true)
        
        userView = AddGroupItemView_Minimalist(frame: .zero)
        if let userView = userView {
            self.view.addSubview(userView)
            let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleUserTap(_:)))
            userView.addGestureRecognizer(singleFingerTap)
        }
    }

    func setSearchIconCenter(center: Bool) {
        if center {
            let size = searchController?.searchBar.placeholder?.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)])
            let width = (size?.width ?? 0) + 60
            searchController?.searchBar.setPositionAdjustment(UIOffset(horizontal: 0.5 * ((searchController?.searchBar.bounds.size.width ?? 0) - width), vertical: 0), for: .search)
        } else {
            searchController?.searchBar.setPositionAdjustment(.zero, for: .search)
        }
    }

    // MARK: - UISearchControllerDelegate
    func didPresentSearchController(_ searchController: UISearchController) {
        print("didPresentSearchController")
        if let searchBar = self.searchController?.searchBar {
            self.view.addSubview(searchBar)
            searchBar.mm_top()(safeAreaTopGap())
            userView?.mm_top()(searchBar.mm_maxY)!.mm_height()(44)!.mm_width()(TUISwift.screen_Width())
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        setSearchIconCenter(center: false)
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        setSearchIconCenter(center: true)
    }

    func safeAreaTopGap() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.view.safeAreaLayoutGuide.layoutFrame.origin.y
        } else {
            return 0
        }
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        print("didDismissSearchController")
        searchController.searchBar.mm_top()(0)
        userView?.groupInfo = nil
    }

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchController?.isActive = true
        return true
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController?.isActive = false
    }

    @objc func handleUserTap(_ sender: Any) {
        if let groupInfo = userView?.groupInfo {
            let frc = TUIGroupRequestViewController_Minimalist()
            frc.groupInfo = groupInfo
            self.navigationController?.pushViewController(frc, animated: true)
        }
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let inputStr = searchBar.text else { return }
        V2TIMManager.sharedInstance().getGroupsInfo([inputStr], succ: { [weak self] groupResultList in
            guard let self = self else { return }
            guard let groupResultList = groupResultList else { return }
            if let result = groupResultList.first, result.resultCode == 0 {
                self.userView?.groupInfo = result.info
            } else {
                self.userView?.groupInfo = nil
            }
        }, fail: { code, desc in
            self.userView?.groupInfo = nil
        })
    }
}

class AddGroupItemView_Minimalist: UIView {
    var groupInfo: V2TIMGroupInfo? {
        didSet {
            if let groupInfo = groupInfo {
                if let groupName = groupInfo.groupName, !groupName.isEmpty {
                    _idLabel.text = "\(groupName) (group id: \(groupInfo.groupID))"
                } else {
                    _idLabel.text = groupInfo.groupID
                }
                _idLabel.mm_sizeToFit()()!.tui_mm_center()()!.mm_left()(8)
                _line.mm_height()(1)!.mm_width()(self.mm_w)!.mm_bottom()(0)
                _line.isHidden = false
            } else {
                _idLabel.text = ""
                _line.isHidden = true
            }
        }
    }
    
    private let _idLabel: UILabel
    private let _line: UIView

    override init(frame: CGRect) {
        _idLabel = UILabel(frame: .zero)
        _line = UIView(frame: .zero)
        super.init(frame: frame)
        
        addSubview(_idLabel)
        _line.backgroundColor = UIColor.gray
        addSubview(_line)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
