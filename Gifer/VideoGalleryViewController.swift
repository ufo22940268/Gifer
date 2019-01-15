//
//  VideoGalleryViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"
private let galleryGap = CGFloat(0.5)

extension TimeInterval {
    func formatTime() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
}

class VideoGalleryViewController: UICollectionViewController {
    
    var videoResult:PHFetchResult<PHAsset>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isToolbarHidden = true

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(VideoGalleryCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = galleryGap
        flowLayout.minimumLineSpacing = galleryGap*4
        let itemWidth = self.collectionView.bounds.width/3 - 2*galleryGap
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        self.collectionView.collectionViewLayout = flowLayout
        
        PHPhotoLibrary.shared().register(self)
        
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == PHAuthorizationStatus.authorized {
                DispatchQueue.main.async {
                    self.reload()
                }
            }
        }
    }
    
    func reload() {
        self.videoResult = VideoLibrary.shared().getVideos()
        self.collectionView.reloadData()
    }
    
    func getSelectedCell() -> VideoGalleryCell? {
        return collectionView.cellForItem(at: selectedIndexPath) as? VideoGalleryCell
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let videoResult = videoResult else {
            return 0
        }
        // #warning Incomplete implementation, return the number of items
        return videoResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let videoResult = videoResult else {
            fatalError()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VideoGalleryCell
    
        // Configure the cell
        let asset = videoResult.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset, targetSize: UIScreen.main.bounds.size, contentMode: .aspectFill, options: options) { (uiImage, config) in
            cell.imageView.image = uiImage
            cell.durationView.text = asset.duration.formatTime()
        }
        
        return cell
    }
    
    var selectedIndexPath: IndexPath!
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let videoResult = videoResult else {
            fatalError()
        }
        selectedIndexPath = indexPath
        
        let editVC = storyboard!.instantiateViewController(withIdentifier: "editViewController") as! EditViewController
        editVC.videoAsset = videoResult.object(at: indexPath.row)
        editVC.transitioningDelegate = self
        editVC.modalPresentationCapturesStatusBarAppearance = true
        present(editVC, animated: true, completion: nil)
    }
}


extension VideoGalleryViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ShowEditViewControllerAnimator(selectedCell: collectionView.cellForItem(at: selectedIndexPath) as! VideoGalleryCell)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissEditViewControllerAnimator()
    }
}

extension VideoGalleryViewController: PHPhotoLibraryChangeObserver {
    
    private func containsVideo(changes: [PHAsset]) -> Bool {
        return changes.contains { (asset) -> Bool in
            return asset.mediaType == .video
        }
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        var needReload = false
        if videoResult == nil {
            needReload = true
        } else {
            let changes = changeInstance.changeDetails(for: videoResult!)
            if let changes = changes, containsVideo(changes: changes.insertedObjects) || containsVideo(changes: changes.removedObjects) {
                needReload = true
            }
        }
        
        if needReload {
            self.reload()
        }
    }
}
