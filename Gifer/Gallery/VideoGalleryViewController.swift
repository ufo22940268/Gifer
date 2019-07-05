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

let EditGalleryDurationThreshold = CMTime(seconds: 20, preferredTimescale: 600)
let toggleGalleryCategoryAnimationDuration = 0.3

class VideoGalleryViewController: UICollectionViewController {
    
    @IBOutlet var galleryCategoryView: GalleryCategoryTableView!
    
    lazy var dimView: UIView = {
        let view = UIView().useAutoLayout()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.isHidden = true
        view.tag = 10
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDimClicked(sender:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    var videoResult:PHFetchResult<PHAsset>?
    lazy var switcher: GallerySwitcher = {
        let view = GallerySwitcher(type: .custom)
        view.sizeToFit()
        view.delegate = self
        view.frame.size.width = 80
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        DarkMode.enable(in: self)
        
        navigationController?.isToolbarHidden = true
        view.backgroundColor = .black
        self.collectionView.backgroundColor = .black
        
        // Register cell classes
        self.collectionView!.register(VideoGalleryCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = galleryGap
        flowLayout.minimumLineSpacing = galleryGap*4
        let itemWidth = self.collectionView.bounds.width/3 - 2*galleryGap
        flowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        flowLayout.footerReferenceSize = CGSize(width: self.collectionView.bounds.width, height: 60)

        self.collectionView.collectionViewLayout = flowLayout
        
        self.collectionView.register(GalleryBottomInfoView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
        
        defer {
            switcher.category = .video
        }
        navigationItem.titleView = switcher
        
        PHPhotoLibrary.shared().register(self)
        
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == PHAuthorizationStatus.authorized {
                DispatchQueue.main.async {
                    self.reload()

                    self.collectionView.layoutIfNeeded()
                    let totalItemCount: Int = self.collectionView(self.collectionView, numberOfItemsInSection: 0)
                    if totalItemCount > 0 {
                        self.collectionView.scrollToItem(at: IndexPath(row: totalItemCount - 1, section: 0), at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
                    }
                }
            }
        }
        
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dimView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dimView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            dimView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor)
            ])

        galleryCategoryView.customDelegate = self
        galleryCategoryView.sizeToFit()
        galleryCategoryView.frame.size.width = view.frame.size.width
        galleryCategoryView.autoresizingMask = [.flexibleWidth]
        galleryCategoryView.transform = CGAffineTransform(translationX: 0, y: -galleryCategoryView.frame.height)
        view.addSubview(galleryCategoryView)
        
        NSLayoutConstraint.activate([
            dimView.leadingAnchor.constraint(equalTo: galleryCategoryView.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: galleryCategoryView.trailingAnchor),
            dimView.topAnchor.constraint(equalTo: galleryCategoryView.topAnchor),
            dimView.bottomAnchor.constraint(equalTo: galleryCategoryView.bottomAnchor)
            ])
    }

    func enableFooterView(_ enable: Bool) {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        if enable {
            flowLayout.footerReferenceSize = CGSize(width: self.collectionView.bounds.width, height: 60)
        } else {
            flowLayout.footerReferenceSize = CGSize.zero
        }
    }
    
    func reload() {
        self.videoResult = VideoLibrary.shared().getVideos()
        self.collectionView.reloadData()
        
        if let videoResult = videoResult, videoResult.count > 0 {
            self.collectionView.restore()
            enableFooterView(true)
        } else {
            enableFooterView(false)
            self.collectionView.setEmptyMessage("未找到视频")
        }
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
        
        
        let imageManager: PHImageManager = PHImageManager.default()
        if cell.tag != 0 {
            imageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let requestId = imageManager.requestImage(for: asset, targetSize: UIScreen.main.bounds.size.applying(CGAffineTransform(scaleX: 1/4, y: 1/4)), contentMode: .aspectFill, options: options) { (uiImage, config) in
            cell.imageView.image = uiImage
            cell.durationView.text = asset.duration.formatTime()
        }
        cell.tag = Int(requestId)
        
        return cell
    }
    

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer", for: indexPath) as! GalleryBottomInfoView
        footer.setVideoCount(self.collectionView(collectionView, numberOfItemsInSection: 0))
        return footer
    }
    
    var selectedIndexPath: IndexPath!
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let videoResult = videoResult else {
            fatalError()
        }
        selectedIndexPath = indexPath
        
        let videoAsset: PHAsset = videoResult.object(at: indexPath.row)
        let previewImage: UIImage = selectedCell.imageView.image!
        if videoAsset.duration > EditGalleryDurationThreshold.seconds {
            let rangeVC = storyboard!.instantiateViewController(withIdentifier: "videoRange") as! VideoRangeViewController
            rangeVC.previewAsset = videoAsset
            navigationController?.pushViewController(rangeVC, animated: true)
        } else {
            let editVC = storyboard!.instantiateViewController(withIdentifier: "editViewController") as! EditViewController
            editVC.videoAsset = videoAsset
            editVC.previewImage = previewImage
            editVC.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: CMTime(seconds: videoAsset.duration, preferredTimescale: 600))
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
}

extension VideoGalleryViewController: UINavigationControllerDelegate {

    var selectedCell: VideoGalleryCell {
        return collectionView.cellForItem(at: selectedIndexPath) as! VideoGalleryCell
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
            DispatchQueue.main.async {                
                self.reload()
            }
        }
    }
}

// MARK: - Gallery switcher and panel features
extension VideoGalleryViewController: GallerySwitcherDelegate, GalleryCategoryDelegate {
    
    func slideDownPanel(_ slideDown: Bool) {
        let duration = toggleGalleryCategoryAnimationDuration
        if slideDown {
            UIView.animate(withDuration: duration) {
                self.galleryCategoryView.transform = .identity
            }
        } else {
            UIView.animate(withDuration: duration, animations: {
                self.galleryCategoryView.transform = CGAffineTransform(translationX: 0, y: -self.galleryCategoryView.frame.height)
            })
        }
        
        UIView.transition(with: dimView, duration: duration, options: [.showHideTransitionViews, .transitionCrossDissolve], animations: {
            self.dimView.isHidden = !slideDown
        }, completion: nil)
    }
    
    func onToggleGalleryPanel(slideDown: Bool) {
        slideDownPanel(slideDown)
    }
    
    func onSelect(galleryCategory: GalleryCategory) {
        slideDownPanel(false)
        switcher.setSelected(false, anim: true)
    }
    
    @objc func onDimClicked(sender: UITapGestureRecognizer) {
        slideDownPanel(false)
        switcher.setSelected(false, anim: true)
    }
}
