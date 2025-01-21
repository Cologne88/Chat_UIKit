//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

import UIKit
import TIMCommon
import TUICore
import ReactiveObjC
import SDWebImage

class TUIContactAvatarViewController: UIViewController, UIScrollViewDelegate {
    
    var avatarData: TUICommonContactProfileCardCellData?
    private var avatarView: UIImageView?
    private var avatarScrollView: TUIScrollView?
    private var saveBackgroundImage: UIImage?
    private var saveShadowImage: UIImage?
    private var avatarUrlObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveBackgroundImage = navigationController?.navigationBar.backgroundImage(for: .default)
        saveShadowImage = navigationController?.navigationBar.shadowImage
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        let rect = view.bounds
        avatarScrollView = TUIScrollView(frame: .zero)
        if let avatarScrollView = avatarScrollView {
            view.addSubview(avatarScrollView)
            avatarScrollView.backgroundColor = .black
            avatarScrollView.frame = rect
        }
        
        if let avatarImage = avatarData?.avatarImage {
            avatarView = UIImageView(image: avatarImage)
            avatarScrollView?.imageView = avatarView ?? UIImageView()
            avatarScrollView?.maximumZoomScale = 4.0
            avatarScrollView?.delegate = self
            avatarView?.image = avatarImage
        }
        
        if let data = avatarData {
            avatarUrlObserver = data.observe(\.avatarUrl, options: [.new, .initial]) { [weak self] (data, change) in
                guard let self = self else { return }
                self.avatarView?.sd_setImage(with: change.newValue as? URL, placeholderImage: self.avatarData?.avatarImage)
                self.avatarScrollView?.setNeedsLayout()
            }
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return avatarView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            navigationController?.navigationBar.setBackgroundImage(saveBackgroundImage, for: .default)
            navigationController?.navigationBar.shadowImage = saveShadowImage
        }
    }
}
