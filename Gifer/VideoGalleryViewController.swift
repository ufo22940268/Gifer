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
    
    var videoResult:PHFetchResult<PHAsset>!

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
        
        // Do any additional setup after loading the view.
        videoResult = VideoLibrary.shared().getVideos()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return videoResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VideoGalleryCell
    
        // Configure the cell
        let asset = videoResult.object(at: indexPath.row)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: options) { (uiImage, config) in
            cell.imageView.image = uiImage
            cell.durationView.text = asset.duration.formatTime()
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("click at \(indexPath.row)")
//        performSegue(withIdentifier: "editVideo", sender: indexPath)
        
        let editVC = storyboard!.instantiateViewController(withIdentifier: "editViewController") as! EditViewController
        editVC.videoAsset = videoResult.object(at: indexPath.row)
        editVC.transitioningDelegate = self
        present(editVC, animated: true, completion: nil)
//        show(editVC, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EditViewController, let indexPath = sender as? IndexPath {
            destination.transitioningDelegate = self
            destination.videoAsset = videoResult.object(at: indexPath.row)
        }
    }

}


extension VideoGalleryViewController: UIViewControllerTransitioningDelegate {
    
}
