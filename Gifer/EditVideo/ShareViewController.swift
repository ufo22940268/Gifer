//
//  ShareViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class SharePresentationController: UIPresentationController {
    
    lazy var dimmingView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = .black
        view.alpha = 0.3
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

class EditCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        textLabel?.textColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    fileprivate var customTransitioningDelegate: TransitioningDelegate = TransitioningDelegate()
    fileprivate var modalTransitioningDelegate: ModalTransitionDelegate = ModalTransitionDelegate()
    
    lazy var tableView: UITableView = {
        let view = UITableView().useAutoLayout()
        view.backgroundColor = .dark
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.dark
        view.clipsToBounds = true
        
        view.addSubview(tableView)
        tableView.useSameSizeAsParent()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(EditCell.self, forCellReuseIdentifier: "edit")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    func present(by controller: UIViewController) {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = customTransitioningDelegate
        controller.present(self, animated: true) {
            print("presented")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "edit", for: indexPath)
        if indexPath.row == 0 {
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = "视频清晰度"
            cell.detailTextLabel?.text = "自动"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: VideoSizeConfigViewController = VideoSizeConfigViewController()
        vc.transitioningDelegate = modalTransitioningDelegate
        vc.modalPresentationStyle = .custom
        present(vc, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
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
        _ = transitionContext.viewController(forKey: .from)! as! ShareViewController
        let target = transitionContext.viewController(forKey: .to) as! VideoSizeConfigViewController
        
        let toView = transitionContext.view(forKey: .to)!
        
        transitionContext.containerView.addSubview(toView)
        let duration = 0.3
        target.view.layoutIfNeeded()
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [], animations: {
//            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
//                source.view.clipsToBounds = true
//                let tableView = (source as! ShareViewController).tableView
//                tableView.frame.origin.x = -tableView.frame.width/3
//            })
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                target.centerX.constant = 0
                target.view.layoutIfNeeded()
            })
        }) { (success) in
            transitionContext.completeTransition(true)
        }
    }
}
