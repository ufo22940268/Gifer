//
//  VideoSizeConfigViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/7.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

enum VideoSize: CaseIterable {
    case auto
    case large
    case middle
    case small
    
    var label: String {
        switch self {
        case .auto:
            return "自动"
        case .large:
            return "高"
        case .middle:
            return "中"
        case .small:
            return "低"
        }
    }
}

class VideoSizeCell: DarkTableCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class VideoSizeConfigViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    lazy var tableView: UITableView = {
        let view = DarkTableView().useAutoLayout()
        return view
    }()
    
    var centerX: NSLayoutConstraint!
    var videoSizes: [VideoSize] = VideoSize.allCases
    
    var selectedVideoSize: VideoSize?
    let interactiveAnimator: UIPercentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
    lazy var configTransitioningDelegate: ConfigTransitionDelegate = {ConfigTransitionDelegate(interactive: interactiveAnimator)}()
    
    init(videoSize: VideoSize) {
        super.init(nibName: nil, bundle: nil)
        selectedVideoSize = videoSize
        modalPresentationStyle = .custom
        transitioningDelegate = configTransitioningDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
        view.backgroundColor = .clear
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
        tableView.register(VideoSizeCell.self, forCellReuseIdentifier: "cell")
        
        tableView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(sender:))))
    }
    
    @objc func onPan(sender: UIPanGestureRecognizer) {
        let progress = sender.translation(in: tableView).x/tableView.bounds.width
        switch sender.state {
        case .began:
            dismiss(animated: true, completion: nil)
        case .changed:
            interactiveAnimator.update(progress)
        case .ended:
            if progress > 0.5 || sender.velocity(in: tableView).x > 300 {
                interactiveAnimator.finish()
            } else {
                interactiveAnimator.cancel()
            }
        default:
            interactiveAnimator.cancel()
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return videoSizes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! VideoSizeCell
        let videoSize = videoSizes[indexPath.row]
        cell.textLabel?.text = videoSize.label
        if videoSize == selectedVideoSize {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedVideoSize = videoSizes[indexPath.row]
        tableView.reloadData()
        tableView.cellForRow(at: indexPath)?.isSelected = true
        (presentingViewController as! ShareViewController).videoSize = selectedVideoSize!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true, completion: nil)
            self.interactiveAnimator.finish()
        }
    }
}

class ConfigTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var interactiveAnimator: UIPercentDrivenInteractiveTransition!
    
    init(interactive: UIPercentDrivenInteractiveTransition) {
        self.interactiveAnimator = interactive
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ConfigPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ConfigTransitionAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ConfigTransitionAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveAnimator
    }
}

class ConfigPresentationController: UIPresentationController {
    
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

class ConfigTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
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
                if transitionContext.transitionWasCancelled {
                    transitionContext.completeTransition(false)
                } else {
                    transitionContext.completeTransition(true)
                    configVC.view.removeFromSuperview()
                }
            })
        }
    }
}
