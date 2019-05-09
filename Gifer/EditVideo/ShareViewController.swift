//
//  ShareViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

typealias ShareGifFileHandler = (_ file: URL) -> Void
typealias ShareHandler = (_ type: ShareType) -> Void

enum ShareType {
    case wechat, photo, wechatSticker
    
    var initialGifSize: CGSize {
        switch self {
        case .wechatSticker:
            return CGSize(width: 150, height: 150)
        default:
            return CGSize(width: 500, height: 500)
        }
    }
    
    var sizeLimitation: Double {
        switch self {
        case .wechat:
            return 5
        case .photo:
            return 40
        case .wechatSticker:
            return 0.5
        }
    }
    
    var icon: UIImage {
        switch self {
        case .wechat:
            return #imageLiteral(resourceName: "weixin-brands.png")
        case .photo:
            return #imageLiteral(resourceName: "file-outline.png")
        case .wechatSticker:
            return #imageLiteral(resourceName: "smile-wink-regular.png")
        }
    }
    
    var label: String {
        switch self {
        case .wechat:
            return "微信"
        case .photo:
            return "保存"
        case .wechatSticker:
            return "表情"
        }
    }
    
    var lowestSize: CGSize {
        switch self {
        case .wechatSticker:
            return CGSize(width: 100, height: 100)
        default:
            return CGSize(width: 200, height: 200)
        }
    }
    
    func isEnabled(duration: CMTime) -> Bool {
        switch self {
        case .wechatSticker:
            return duration.seconds <= 5
        default:
            return true
        }
    }
}


class SharePresentationController: UIPresentationController {
    
    lazy var dimmingView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    } ()
    
    override func presentationTransitionWillBegin() {
        containerView?.addSubview(dimmingView)
        dimmingView.useSameSizeAsParent()
        
        guard let presentedView = presentedView, let sourceView = presentingViewController.view else { return }
        presentedView.layer.cornerRadius = 20
        let size = containerView!.bounds.size
        presentedView.frame.origin.y = size.height
        sourceView.layer.cornerRadius = 20
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        gesture.cancelsTouchesInView = false
        containerView?.addGestureRecognizer(gesture)
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        if !presentedView!.frame.contains(sender.location(in: containerView)) {
            presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if (!completed) {
            dimmingView.removeFromSuperview()
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = CGFloat(300)
        var rect = CGRect(origin: CGPoint(x: 0, y: containerView!.bounds.height - height), size: CGSize(width: presentingViewController.view.bounds.width, height: height))
        rect = rect.insetBy(dx: 8, dy: 0)
        rect = rect.applying(CGAffineTransform(translationX: 0, y: -presentingViewController.view.safeAreaInsets.bottom))
        return rect
    }
    
}

extension UIColor {
    static let dark = UIColor(named: "darkBackgroundColor")!
}

class EditCell: DarkTableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ShareCell: DarkTableCell {
    
    lazy var stackView: UIStackView =  {
        let view = UIStackView().useAutoLayout()
        view.axis = .horizontal
        view.spacing = 16
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        
    }
    
    func buildItemView(icon: UIImage, label: String) -> UIView {
        let button = UIButton().useAutoLayout()
        button.setImage(icon, for: .normal)
        button.imageView?.tintColor = .white
        button.setTitle(label, for: .normal)
        button.alignTextUnderImage()
        
        let height = button.heightAnchor.constraint(equalToConstant: 90)
        height.priority = .defaultHigh
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            height,
            ])
        
        return button
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(items: [ShareType]) {
        for item in items {
            let itemView = buildItemView(icon: item.icon, label: item.label)
            stackView.addArrangedSubview(itemView)
        }
    }
}

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var customTransitioningDelegate: TransitioningDelegate = TransitioningDelegate()
    fileprivate var modalTransitioningDelegate: ModalTransitionDelegate = ModalTransitionDelegate()
    
    lazy var tableView: UITableView = {
        let view = DarkTableView().useAutoLayout()
        return view
    }()
    
    var centerX: NSLayoutConstraint!
    var shareHandler: ShareHandler!
    var cancelHandler: (() -> Void)!
    var duration: CMTime!
    var shareTypes: [ShareType] {
        var types = [ShareType]()
        types.append(.wechat)
        types.append(.photo)
        if let duration = duration, duration.seconds < 3 {
            types.append(.wechatSticker)
        }
        return types
    }
    
    var videoSize: VideoSize = VideoSize.auto {
        didSet {
            tableView.reloadData()
        }
    }
    
    init(duration: CMTime, shareHandler: @escaping ShareHandler, cancelHandler: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.shareHandler = shareHandler
        self.cancelHandler = cancelHandler
        self.duration = duration
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.dark
        view.clipsToBounds = true
        
        view.addSubview(tableView)
        centerX = tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        NSLayoutConstraint.activate([
            centerX,
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            tableView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EditCell.self, forCellReuseIdentifier: "edit")
        tableView.register(ShareCell.self, forCellReuseIdentifier: "share")
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    
    func present(by controller: UIViewController) {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = customTransitioningDelegate
        controller.present(self, animated: true) {
            print("presented")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "edit", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "视频清晰度"
            cell.detailTextLabel?.text = videoSize.label
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "share") as! ShareCell
            cell.setup(items: shareTypes)
            return cell
        }
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: VideoSizeConfigViewController = VideoSizeConfigViewController(videoSize: videoSize)        
        vc.transitioningDelegate = modalTransitioningDelegate
        vc.modalPresentationStyle = .custom
        present(vc, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }    
}

fileprivate class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SharePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class ModalTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalTransitionAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalTransitionAnimator()
    }
}

class ModalPresentationController: UIPresentationController {
    
    override func presentationTransitionWillBegin() {
        guard let _ = containerView, let presentedView = presentedView, let presentedViewController = presentedViewController as? VideoSizeConfigViewController, let sourceView = presentingViewController.view else { return }
        presentedView.layer.cornerRadius = 20
        sourceView.layer.cornerRadius = 20
        
        presentedView.frame = frameOfPresentedViewInContainerView
        let presentedTableView = (presentedViewController ).tableView
        presentedTableView.frame.origin.x = presentedTableView.frame.width
        
        presentedViewController.centerX.constant = presentedViewController.view.bounds.width
        presentedViewController.view.layoutIfNeeded()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        gesture.cancelsTouchesInView = false
        containerView?.addGestureRecognizer(gesture)
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended && !presentedView!.frame.contains(sender.location(in: containerView)) {
            (presentingViewController as! ShareViewController).tableView.isHidden = true
            presentingViewController.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let height = CGFloat(300)
        var rect = CGRect(origin: CGPoint(x: 0, y: containerView!.bounds.height - height), size: CGSize(width: containerView!.bounds.width, height: height))
        rect = rect.insetBy(dx: 8, dy: 0)
        rect = rect.applying(CGAffineTransform(translationX: 0, y: -containerView!.safeAreaInsets.bottom))
        return rect
    }
}

class ModalTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresent = transitionContext.viewController(forKey: .to)?.presentingViewController == transitionContext.viewController(forKey: .from)
        var shareVC: ShareViewController
        var configVC: VideoSizeConfigViewController
        
        if isPresent {
            shareVC = transitionContext.viewController(forKey: .from)! as! ShareViewController
            configVC = transitionContext.viewController(forKey: .to) as! VideoSizeConfigViewController
        } else {
            shareVC = transitionContext.viewController(forKey: .to)! as! ShareViewController
            configVC = transitionContext.viewController(forKey: .from) as! VideoSizeConfigViewController
        }
        
        
        let duration = 0.3
        
        if isPresent {
            let toView = transitionContext.view(forKey: .to)!
            transitionContext.containerView.addSubview(toView)
            configVC.view.layoutIfNeeded()
            UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    let tableView = (shareVC ).tableView
                    shareVC.centerX.constant = -tableView.frame.width/3
                    shareVC.view.layoutIfNeeded()
                })
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                    configVC.centerX.constant = 0
                    configVC.view.layoutIfNeeded()
                })
            }) { (success) in
                transitionContext.completeTransition(true)
            }
        } else {
            shareVC.centerX.constant = -shareVC.view.bounds.width
            shareVC.view.layoutIfNeeded()
            UIView.animate(withDuration: duration, animations: {
                configVC.centerX.constant = configVC.tableView.bounds.width
                shareVC.centerX.constant = 0
                configVC.view.layoutIfNeeded()
                shareVC.view.layoutIfNeeded()
            }, completion: { success in
                transitionContext.completeTransition(true)
                configVC.view.removeFromSuperview()
            })
        }
    }
}
