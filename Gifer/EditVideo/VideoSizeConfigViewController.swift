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

class VideoSizeConfigViewController: ConfigViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView
    var videoSizes: [VideoSize] = VideoSize.allCases
    
    var selectedVideoSize: VideoSize?
    init(videoSize: VideoSize) {
        let tableView = DarkTableView().useAutoLayout()
        self.tableView = tableView
        super.init(contentView: tableView)
        self.tableView = tableView
        selectedVideoSize = videoSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VideoSizeCell.self, forCellReuseIdentifier: "cell")
        
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
