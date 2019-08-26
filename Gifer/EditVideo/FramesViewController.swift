//
//  FramesViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

protocol FramesDelegate: class {
    func onUpdateFrames(_ frames: [ImagePlayerFrame])
}

class FramesViewController: UIViewController {
    
    var playerItem: ImagePlayerItem! {
        didSet {
            frameLabelCollectionView.playerItem = playerItem
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    weak var customDelegate: FramesDelegate?
    var trimPosition: VideoTrimPosition!
    
    @IBOutlet weak var frameLabelCollectionView: FrameLabelCollectionView!
    
    var rootFrames: [ImagePlayerFrame] {
        get {
            return playerItem.rootFrames
        }
        
        set {
            playerItem.rootFrames = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        
        if playerItem == nil {
            let directory = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
            let paths = (try! FileManager.default.contentsOfDirectory(atPath: directory.path)).map { (file: String) -> URL in
                var path = directory
                path.appendPathComponent(file)
                return path
            }
            let frames = paths.map { (path: URL) -> ImagePlayerFrame in
                var frame = ImagePlayerFrame(time: .zero)
                frame.path = path
                return frame
            }
            playerItem = ImagePlayerItem(frames: frames, duration: CMTime(seconds: 3, preferredTimescale: 600))
            trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: CMTime(seconds: 2, preferredTimescale: 600))
        }
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let gap = CGFloat(2)
        let width: CGFloat = (view.bounds.width - 3*gap)/4
        flowLayout.minimumLineSpacing = gap
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        collectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
        rootFrames.enumerated()
            .filter { !$0.element.isActive }.map { $0.offset }
            .forEach { collectionView.selectItem(at: IndexPath(row: $0, section: 0), animated: false, scrollPosition: .left)}
        collectionView.contentOffset = .zero
    }
    
    @IBAction func onDone(_ sender: Any) {
        customDelegate?.onUpdateFrames(playerItem.allFrames)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension FramesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerItem != nil ? rootFrames.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FrameCell
        let frame = rootFrames[indexPath.row]
        
        if cell.tag != 0 {
            playerItem.cancel(taskId: cell.tag)
        }
        
        let id = playerItem.requestImage(frame: frame, complete: { (image) in
            cell.image.image = image
        })
        
        cell.tag = id
        cell.sequence = playerItem.getActiveSequence(of: frame)
        cell.delegate = self
        cell.index = indexPath.row
        return cell
    }
}

extension FramesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if rootFrames[indexPath.row].isActive && (rootFrames.filter { $0.isActive }.count == 1) {
            makeToast(message: "最少选择一个图片")
            return false
        } else {
            return true
        }
    }
    
    fileprivate func updateVisibleCells() {
        let newFrames = rootFrames
        collectionView.visibleCells.forEach { cell in
            let cell = cell as! FrameCell
            let frame: ImagePlayerFrame = newFrames[cell.index]
            cell.sequence = playerItem.getActiveSequence(of: frame)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let frame = rootFrames[indexPath.row]
        rootFrames[indexPath.row].isActive = false
        updateVisibleCells()
   }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let frame = rootFrames[indexPath.row]
        rootFrames[indexPath.row].isActive = true
        updateVisibleCells()
    }
}

extension FramesViewController: FrameCellDelegate {
    func onOpenPreview(index: Int) {
        let nvc = storyboard?.instantiateViewController(withIdentifier: "framePreview") as! UINavigationController
        let vc = nvc.topViewController as! FramePreviewViewController
        vc.currentIndex = index
        vc.playerItem = playerItem
        vc.delegate = self
        nvc.modalTransitionStyle = .coverVertical
        nvc.modalPresentationStyle = .overCurrentContext
        nvc.transitioningDelegate = vc.customTransitioning
        present(nvc, animated: true, completion: nil)
    }    
}

extension FramesViewController: FramePreviewDelegate {
    func onCheck(index: Int, actived: Bool) {
        let frame = rootFrames[index]
        playerItem.allFrames[playerItem.allFrames.firstIndex(of: frame)!].isActive = actived
    }
}
