// TUISearchFriendViewController.swift
// TIMChat
//
// Created by AlexiChen on 16/2/29.
// Copyright © 2016 AlexiChen. All rights reserved.

import TIMCommon
import UIKit

class TUISearchFriendViewController: UIViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    var searchController: UISearchController?
    var userView: AddFriendUserView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = TUISwift.timCommonLocalizableString("ContactsAddFriends")
        view.backgroundColor = TUISwift.timCommonDynamicColor("controller_bg_color", defaultColor: "#F2F3F5")
        edgesForExtendedLayout = []
        automaticallyAdjustsScrollViewInsets = false
        definesPresentationContext = true

        searchController = UISearchController(searchResultsController: nil)
        searchController?.delegate = self
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = TUISwift.timCommonLocalizableString("SearchGroupPlaceholder")
        if let searchBar = searchController?.searchBar {
            view.addSubview(searchBar)
            searchBar.mm__sizeToFit()
            setSearchIconCenter(center: true)
        }

        userView = AddFriendUserView(frame: .zero)
        if let userView = userView {
            view.addSubview(userView)
            let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleUserTap(_:)))
            userView.addGestureRecognizer(singleFingerTap)
        }
    }

    func setSearchIconCenter(center: Bool) {
        guard let searchBar = searchController?.searchBar else { return }
        if center {
            let size = searchBar.placeholder?.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0)]) ?? .zero
            let width = size.width + 60
            searchBar.setPositionAdjustment(UIOffset(horizontal: 0.5 * (searchBar.bounds.size.width - width), vertical: 0), for: .search)
        } else {
            searchBar.setPositionAdjustment(.zero, for: .search)
        }
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        setSearchIconCenter(center: false)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        print("didPresentSearchController")
        let searchBar = searchController.searchBar
        if searchBar.frame != CGRectZero {
            view.addSubview(searchBar)
            searchBar.mm_top(safeAreaTopGap())
            userView?.mm_top(searchBar.mm_maxY).mm_height(44).mm_width(TUISwift.screen_Width())
        }
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
        searchController.searchBar.mm_top(0)
        userView?.profile = nil
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let inputStr = searchController.searchBar.text else { return }
        print("search \(inputStr)")
        V2TIMManager.sharedInstance().getUsersInfo([inputStr], succ: { [weak self] infoList in
            guard let infoList = infoList else { return }
            self?.userView?.profile = infoList.first
        }, fail: { [weak self] _, _ in
            self?.userView?.profile = nil
        })
    }

    @objc func handleUserTap(_ sender: Any) {
        if let userID = userView?.profile?.userID, !userID.isEmpty {
            let frc = TUIFriendRequestViewController()
            frc.profile = userView?.profile
            navigationController?.pushViewController(frc, animated: true)
        }
    }
}

class AddFriendUserView: UIView {
    var profile: V2TIMUserFullInfo? {
        didSet {
            if let profile = profile {
                idLabel.text = profile.userID
                idLabel.mm__sizeToFit().tui_mm__center().mm_left(8)
                line.mm_height(1).mm_width(mm_w).mm_bottom(0)
                line.isHidden = false
            } else {
                idLabel.text = ""
                line.isHidden = true
            }
        }
    }

    private let idLabel = UILabel(frame: .zero)
    private let line: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.gray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(idLabel)
        addSubview(line)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
