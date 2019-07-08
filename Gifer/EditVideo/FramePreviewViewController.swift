//
//  FramePreviewViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol FramePreviewDelegate: class {
    func onCheck(index: Int, actived: Bool)
}

class FramePreviewCell: UICollectionViewCell {    
    @IBOutlet weak var imageView: UIImageView!
}

class FramePreviewViewController: UIViewController {

    @IBOutlet weak var checkItem: UIBarButtonItem!
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var previewFlowLayout: UICollectionViewFlowLayout!
    
    weak var delegate: FramePreviewDelegate?
    var currentIndex: Int!
    var playerItem: ImagePlayerItem!
    var frames: [ImagePlayerFrame] {
        return playerItem.allFrames
    }
    
    var customTransitioning: FramePreviewTransitionDelegate = FramePreviewTransitionDelegate()
    
    var sequence: Int? {
        didSet {
            navigationItem.title = sequence == nil ? "" : String(sequence!)
        }
    }
    
    var isActive: Bool! {
        didSet {
            if isActive {
                checkItem.image = #imageLiteral(resourceName: "check-circle-solid.png")
                checkItem.tintColor = view.tintColor
            } else {
                checkItem.image = #imageLiteral(resourceName: "check-circle-regular.png")
                checkItem.tintColor = .lightText
            }
        }
    }
    
    var displayPageIndex: Int? {
        guard let cell = previewCollectionView.visibleCells.first else { return nil }
        return previewCollectionView.indexPath(for: cell)!.row
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        view.tintColor = .yellowActiveColor
        navigationController?.navigationBar.tintColor = .white
        // Do any additional setup after loading the view.
        
        isActive = false
        load(frame: frames[currentIndex])
        previewCollectionView.contentInset = UIEdgeInsets.zero
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanToDismiss(sender:)))
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewFlowLayout.itemSize = previewCollectionView.frame.size
        previewCollectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .left, animated: false)
    }
    
    @objc func onPanToDismiss(sender: UIPanGestureRecognizer) {
        let translateY = sender.translation(in: view).y
        let interactiveAnimator = customTransitioning.interactiveAnimator
        let progress = translateY/view.frame.height
        switch sender.state {
        case .began:
            interactiveAnimator.wantsInteractiveStart = true
            navigationController?.dismiss(animated: true, completion: nil)
        case .changed:
            interactiveAnimator.update(progress)
        case .ended:
            if progress < 0.3 {
                interactiveAnimator.cancel()
            } else {
                interactiveAnimator.finish()
            }
            interactiveAnimator.wantsInteractiveStart = false
        default:
            break
        }
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCheck(_ sender: Any) {
        isActive = !isActive
        delegate?.onCheck(index: currentIndex, actived: isActive)
        playerItem!.allFrames[currentIndex].isActive = isActive
        
        load(frame: frames[currentIndex])
    }
}

extension FramePreviewViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FramePreviewCell
        let frame = frames[indexPath.row]
        DispatchQueue.global(qos: .userInteractive).async {
            let image = frame.uiImage
            DispatchQueue.main.async {
                cell.imageView.image = image
            }
        }
        return cell
    }
}

extension FramePreviewViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func load(frame: ImagePlayerFrame) {
        sequence = playerItem.getActiveSequence(of: frame)
        isActive = frame.isActive
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let displayPageIndex = displayPageIndex else { return }
        load(frame: frames[displayPageIndex])
        currentIndex = displayPageIndex
    }
}
