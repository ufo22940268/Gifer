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
    case wechat, photo, wechatSticker, email
    
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
        case .photo, .email:
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
        case .email:
            return #imageLiteral(resourceName: "share-email.png")
        }
    }
    
    var label: String {
        switch self {
        case .wechat:
            return NSLocalizedString("Wechat", comment: "")
        case .photo:
            return NSLocalizedString("Library", comment: "")
        case .wechatSticker:
            return NSLocalizedString("Sticker", comment: "")
        case .email:
            return NSLocalizedString("Email", comment: "")
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
    
//    @available(*, deprecated)
//    func isEnabled(duration: CMTime) -> Bool {
//        switch self {
//        case .wechatSticker:
//            return Wechat.canBeShared(duration: duration)
//        default:
//            return true
//        }
//    }
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
    static let darkBackground = UIColor(named: "darkBackgroundColor")!    
    static let darkContent = UIColor(named: "darkContentColor")!
}

class ShareCell: DarkTableCell {
    
    lazy var stackView: UIStackView =  {
        let view = UIStackView().useAutoLayout()
        view.axis = .horizontal
        view.spacing = 20
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 16, right: 16)
        return view
    }()
    
    var shareHandler: ((_ shareType: ShareType) -> Void)!
    var items: [ShareType]!
    
    lazy var questionButton: UIButton = {
        let button = UIButton(type: .custom).useAutoLayout()
        button.setImage(#imageLiteral(resourceName: "question-circle.png"), for: .normal)
        button.imageView?.tintColor = .lightText
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor)
            ])
        
        contentView.addSubview(questionButton)
        NSLayoutConstraint.activate([
            questionButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor, constant: -8),
            questionButton.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -24)
            ])
    }
    
    func buildItemView(icon: UIImage, label: String) -> UIButton {
        let button = UIButton().useAutoLayout()
        button.setImage(icon, for: .normal)
        button.imageView?.tintColor = .white
        button.setTitle(label, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: -2)
        button.sizeToFit()
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
    
    func setup(items: [ShareType], wechatEnabled: Bool, viewController: ShareViewController, shareHandler: @escaping (_ shareType: ShareType) -> Void) {
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
            
            if [ShareType.wechat, ShareType.wechatSticker].contains(item) && !wechatEnabled {
                itemView.isEnabled = false
                itemView.setTitleColor(.darkGray, for: .normal)
            } else {
                itemView.isEnabled = true
                itemView.setTitleColor(.white, for: .normal)
            }
        }
        
        questionButton.addTarget(viewController, action: #selector(ShareViewController.onQuestionButtonTapped), for: .touchUpInside)
    }
}

enum ShareConfig: Int, CaseIterable {
    case loopCount = 0
    case videoSize = 1
    case shareCell = 2
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
    var shareTypes: [ShareType] {
        var types = [ShareType]()
        types.append(.photo)
        types.append(.wechat)
        types.append(.wechatSticker)
        types.append(.email)
        return types
    }
    
    var wechatEnabled: Bool!
    
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
    
    init(wechatEnabled: Bool, shareHandler: @escaping ShareHandler, cancelHandler: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.shareHandler = shareHandler
        self.cancelHandler = cancelHandler
        self.wechatEnabled = wechatEnabled
        customTransitioningDelegate = ShareTransitioningDelegate(dismiss: cancelHandler, interator: interactiveAnimator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.darkBackground
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
        tableView.register(ShareCell.self, forCellReuseIdentifier: "share")
    }
    
    @objc func onQuestionButtonTapped() {
        let vc = AppStoryboard.Edit.instance.instantiateViewController(withIdentifier: "shareInstruction")
        navigationController?.pushViewController(vc, animated: true)
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
        nvc.view.layer.cornerRadius = 2
        nvc.view.clipsToBounds = true
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
            cell.textLabel?.text = NSLocalizedString("Size", comment: "")
            cell.detailTextLabel?.text = videoSize.label
            return cell
        } else if indexPath.row == ShareConfig.loopCount.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loopCount", for: indexPath)
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = NSLocalizedString("Loop Count", comment: "")
            cell.detailTextLabel?.text = loopCount.description
            return cell
        } else if indexPath.row == ShareConfig.shareCell.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "share") as! ShareCell
            let handler = {(shareType: ShareType) in
                self.dismissImediately()
                self.shareHandler(shareType, self.videoSize, self.loopCount)
            }
            cell.setup(items: shareTypes, wechatEnabled: wechatEnabled, viewController: self, shareHandler: handler)
            return cell
        }
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == ShareConfig.videoSize.rawValue {
            let vc: VideoSizeConfigViewController = VideoSizeConfigViewController(videoSize: videoSize)
            vc.largestGifSize = 5.3
            vc.customDelegate = self
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == ShareConfig.loopCount.rawValue {
            let vc: LoopCountConfigViewController = LoopCountConfigViewController(loopCount: loopCount)
            vc.customDelegate = self
            vc.view.addGestureRecognizer(panGesture)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == tableView.numberOfRows(inSection: 0) - 1 {
            return tableView.bounds.height - CGFloat(tableView.numberOfRows(inSection: 0) - 1)*44
        } else {
            return 44
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
