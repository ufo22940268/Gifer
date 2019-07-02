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
typealias ShareHandler = (_ type: ShareType, _ videoSize: VideoSize, _ loopCount: LoopCount) -> Void
typealias DismissHandler = () -> Void

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
            return #imageLiteral(resourceName: "wechat-color.png")
        case .photo:
            return #imageLiteral(resourceName: "folder-color.png")
        case .wechatSticker:
            return #imageLiteral(resourceName: "emoji-color.png")
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

class VideoSizeConfigCell: DarkTableCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LoopCountConfigCell: DarkTableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIColor {
    static let dark = UIColor(named: "darkBackgroundColor")!
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
    
    var shareHandler: ((_ shareType: ShareType) -> Void)!
    var items: [ShareType]!
    
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
        button.setTitleColor(.lightText, for: .normal)
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
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        let item = items[sender.view!.tag]
        shareHandler(item)
    }
    
    func setup(items: [ShareType], shareHandler: @escaping (_ shareType: ShareType) -> Void) {
        self.selectionStyle = .none
        stackView.subviews.forEach {$0.removeFromSuperview()}
        
        self.shareHandler = shareHandler
        self.items = items
        for (index, item) in items.enumerated() {
            let itemView = buildItemView(icon: item.icon, label: item.label)
            itemView.gestureRecognizers?.forEach({ (recognizer) in
                itemView.removeGestureRecognizer(recognizer)
            })
            itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
            itemView.tag = index
            stackView.addArrangedSubview(itemView)
        }
    }
}

class DividerCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 2)])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum ShareConfig: Int, CaseIterable {
    case loopCount = 0
    case videoSize = 1
    case divider = 2
    case shareCell = 3
}

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var customTransitioningDelegate: ShareTransitioningDelegate!
    
    lazy var tableView: UITableView = {
        let view = DarkTableView().useAutoLayout()
        return view
    }()
    
    var centerX: NSLayoutConstraint!
    var shareHandler: ShareHandler!
    var cancelHandler: (() -> Void)!
    var galleryDuration: CMTime!
    var shareTypes: [ShareType] {
        var types = [ShareType]()
        types.append(.wechat)
        types.append(.photo)
        if let duration = galleryDuration, duration.seconds < 3 {
            types.append(.wechatSticker)
        }
        return types
    }
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:)))
        panGesture.cancelsTouchesInView = false
        return panGesture
    }()
    
    var videoSize: VideoSize = VideoSize.auto {
        didSet {
            tableView.reloadData()
        }
    }
    
    var loopCount: LoopCount = LoopCount.infinite {
        didSet {
            tableView.reloadData()
        }
    }
    
    lazy var interactiveAnimator: ShareInteractiveAnimator = {
        let animator = ShareInteractiveAnimator()
        animator.wantsInteractiveStart = false
        return animator
    }()
    
    init(galleryDuration: CMTime, shareHandler: @escaping ShareHandler, cancelHandler: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.shareHandler = shareHandler
        self.cancelHandler = cancelHandler
        self.galleryDuration = galleryDuration
        customTransitioningDelegate = ShareTransitioningDelegate(dismiss: cancelHandler, interator: interactiveAnimator)
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
        tableView.isScrollEnabled = false
        tableView.register(VideoSizeConfigCell.self, forCellReuseIdentifier: "videoSize")
        tableView.register(LoopCountConfigCell.self, forCellReuseIdentifier: "loopCount")
        tableView.register(DividerCell.self, forCellReuseIdentifier: "divider")
        tableView.register(ShareCell.self, forCellReuseIdentifier: "share")
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        let translateY = sender.translation(in: sender.view!).y
        let progress = translateY/sender.view!.bounds.height
        switch sender.state {
        case .began:
            interactiveAnimator.wantsInteractiveStart = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactiveAnimator.update(progress)
        case .ended:
            if progress > 0.5 || sender.velocity(in: sender.view!).y > 300 {
                interactiveAnimator.finish()
            } else {
                interactiveAnimator.cancel()
            }
            interactiveAnimator.wantsInteractiveStart = false
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.addGestureRecognizer(panGesture)
        for row in 0..<self.tableView(self.tableView, numberOfRowsInSection: 0) {
            self.tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
//        view.removeGestureRecognizer(panGesture)
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return ShareConfig.allCases.count
    }
    
    func present(by controller: UIViewController) {
        let nvc = UINavigationController(rootViewController: self)
        nvc.isNavigationBarHidden = true
        nvc.modalPresentationStyle = .custom
        nvc.transitioningDelegate = customTransitioningDelegate
        self.transitioningDelegate = customTransitioningDelegate
        controller.present(nvc, animated: true) {
        }
    }
    
    func dismissImediately() {
        interactiveAnimator.finish()
        dismiss(animated: false, completion: nil)
    }
    
    var rowCount: Int {
        return tableView(tableView, numberOfRowsInSection: 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == ShareConfig.videoSize.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "videoSize", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "视频清晰度"
            cell.detailTextLabel?.text = videoSize.label
            return cell
        } else if indexPath.row == ShareConfig.loopCount.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loopCount", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "循环次数"
            cell.detailTextLabel?.text = loopCount.description
            return cell
        } else if indexPath.row == ShareConfig.divider.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "divider") as! DividerCell
            return cell
        } else if indexPath.row == ShareConfig.shareCell.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "share") as! ShareCell
            let handler = {(shareType: ShareType) in
                self.dismissImediately()
                self.shareHandler(shareType, self.videoSize, self.loopCount)
            }
            cell.setup(items: shareTypes, shareHandler: handler)
            return cell
        }
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == ShareConfig.videoSize.rawValue {
            let vc: VideoSizeConfigViewController = VideoSizeConfigViewController(videoSize: videoSize)
            vc.largestGifSize = 5.3
            vc.view.addGestureRecognizer(panGesture)
            vc.customDelegate = self
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == ShareConfig.loopCount.rawValue {
            let vc: LoopCountConfigViewController = LoopCountConfigViewController(loopCount: loopCount)
            vc.customDelegate = self
            vc.view.addGestureRecognizer(panGesture)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

fileprivate class ShareTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var dismissHandler: DismissHandler!
    var interactiveAnimator: ShareInteractiveAnimator!
    
    init(dismiss: @escaping DismissHandler, interator: ShareInteractiveAnimator) {
        self.dismissHandler = dismiss
        self.interactiveAnimator = interator
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ShareAnimator()
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SharePresentationController(presentedViewController: presented, presentingViewController: presenting, dismiss: dismissHandler, interactiveAnimator: interactiveAnimator)
    }
    
    class ShareAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.25
        }
        
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            let targetView = transitionContext.view(forKey: .from)!
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                targetView.frame.origin.y = transitionContext.containerView.frame.height
            }, completion: {success in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

class ShareInteractiveAnimator: UIPercentDrivenInteractiveTransition {}


class SharePresentationController: UIPresentationController {
    
    lazy var dimmingView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = .black
        view.alpha = 0.7
        return view
    } ()
    
    var dismissHandler: DismissHandler?
    var interactiveAnimator: UIPercentDrivenInteractiveTransition!
    
    init(presentedViewController: UIViewController, presentingViewController: UIViewController?, dismiss: @escaping DismissHandler, interactiveAnimator: UIPercentDrivenInteractiveTransition) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        dismissHandler = dismiss
        self.interactiveAnimator = interactiveAnimator
    }
    
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
            dismissHandler?()
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
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            dismissHandler?()
        }
    }
}


extension ShareViewController: VideoSizeConfigDelegate, LoopCountConfigDelegate {
    func onUpdate(loopCount: LoopCount) {
        self.loopCount = loopCount
    }
    
    func onUpdate(videoSize: VideoSize) {
        self.videoSize = videoSize
    }
}
