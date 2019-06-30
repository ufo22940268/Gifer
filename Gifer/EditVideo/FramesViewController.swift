//
//  FramesViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class FramesViewController: UIViewController {
    
    var playerItem: ImagePlayerItem!
    var frames: [ImagePlayerFrame] {
        return playerItem.allFrames
    }
    @IBOutlet weak var collectionView: UICollectionView!
    var customTransitioningDelegate: FramePreviewTransitioningDelegate =  FramePreviewTransitioningDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        collectionView.backgroundColor = UIColor(named: "darkBackgroundColor")
        
        if isInitial() {
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
        }

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let gap = CGFloat(2)
        let width: CGFloat = (view.bounds.width - 3*gap)/4
        flowLayout.minimumLineSpacing = gap
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.itemSize = CGSize(width: width, height: width)
    }
}

extension FramesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerItem != nil ? frames.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FrameCell
        let frame = frames[indexPath.row]
        cell.image.image = frame.uiImage
        cell.sequence = playerItem.getActiveSequence(of: frame)
        cell.delegate = self
        cell.index = indexPath.row
        return cell
    }
}

extension FramesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var frame = frames[indexPath.row]
        frame.isActive = !frame.isActive
        playerItem.allFrames[indexPath.row] = frame
        collectionView.reloadData()
    }
}

extension FramesViewController: FrameCellDelegate {
    func onOpenPreview(index: Int) {
        let nvc = storyboard?.instantiateViewController(withIdentifier: "framePreview") as! UINavigationController
        let vc = nvc.topViewController as! FramePreviewViewController
        vc.loadViewIfNeeded()
        vc.previewView.image = frames[index].uiImage
        customTransitioningDelegate.cellIndex = index
        vc.sequence = playerItem.getActiveSequence(of: frames[index])
//        nvc.transitioningDelegate = customTransitioningDelegate
//        nvc.modalTransitionStyle = .crossDissolve
//        nvc.modalPresentationStyle = .custom
        present(nvc, animated: true, completion: nil)
    }
}
