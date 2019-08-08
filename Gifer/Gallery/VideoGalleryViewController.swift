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

struct VideoGalleryFetchOptions {
    var mediaType: PHAssetMediaType? = .video
    var mediaSubtype: PHAssetMediaSubtype?
    var localIdentifier: String?
    var localizedTitle: String?
    
    static let `default` = {
        return VideoGalleryFetchOptions(mediaType: .video, mediaSubtype: nil, localIdentifier: nil, localizedTitle: nil)
    }()
    
    var phOptions: PHFetchOptions {
        let options = PHFetchOptions()
        var predicates = [NSPredicate]()
        
        if let subType = mediaSubtype {
            predicates.append(NSPredicate(format: "(mediaSubtype & %d) != 0", subType.rawValue))
        } else if let type = mediaType {
            predicates.append(NSPredicate(format: "mediaType = %d", type.rawValue))
        }
        
        options.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return options
    }
    
    mutating func fillCollectionInfo() {
        if localIdentifier != nil {
            fatalError()
        }
        
        if let col = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
            localizedTitle = col.localizedTitle
            localIdentifier = col.localIdentifier
        }
    }
}

fileprivate let selectPhotoViewHeight = CGFloat(100)

class VideoGalleryViewController: UICollectionViewController {
    
    @IBOutlet var galleryCategoryView: GalleryCategoryTableView!
    @IBOutlet var scrollToBottomButton: UIButton!
    var isScrollToBottomButtonShowed: Bool = false
    
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
        view.frame.size.width = 100
        return view
    }()
    
    @IBOutlet var selectPhotoView: GallerySelectPhotoView!
    
    var galleryCategory: GalleryCategory = .video
    
    var fetchOptions = VideoGalleryFetchOptions.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DarkMode.enable(in: self)
        
        navigationController?.isToolbarHidden = true
        
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
        let openAlbumsItem = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(onOpenAlbums))
        openAlbumsItem.tintColor = UIColor.yellowActiveColor
        navigationItem.leftBarButtonItem = openAlbumsItem
        
        PHPhotoLibrary.shared().register(self)
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == PHAuthorizationStatus.authorized {
                DispatchQueue.main.async {
                    self.reload()

                    self.collectionView.layoutIfNeeded()
                    let totalItemCount: Int = self.collectionView(self.collectionView, numberOfItemsInSection: 0)
                    if totalItemCount > 0 {
                        self.scrollToBottom()
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
        
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomButton.layer.shadowOpacity = 0.1
        NSLayoutConstraint.activate([
            scrollToBottomButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        
        selectPhotoView.customDelegate = self
        
        // FIXME: Test code
        onSelectGalleryCategory(.photo)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if selectPhotoView.superview == nil {
            let navRootView = navigationController!.view!
            selectPhotoView.translatesAutoresizingMaskIntoConstraints = false
            navRootView.addSubview(selectPhotoView)
            NSLayoutConstraint.activate([
                selectPhotoView.widthAnchor.constraint(equalTo: navRootView.widthAnchor),
                selectPhotoView.heightAnchor.constraint(equalToConstant: selectPhotoViewHeight),
                selectPhotoView.topAnchor.constraint(equalTo: navRootView.safeAreaLayoutGuide.topAnchor)
                ])
        }
    }
    
    @objc func onOpenAlbums() {
        let nvc = AppStoryboard.Album.instance.instantiateViewController(withIdentifier: "albumNavigation") as! UINavigationController
        let vc = nvc.topViewController as! AlbumViewController
        vc.customDelegate = self
        vc.initialCollectionIdentifier = fetchOptions.localIdentifier
        navigationController?.present(nvc, animated: true, completion: nil)
    }
    
    func showSelectPhotoView(_ show: Bool, complete: (() -> Void)? = nil) {
        guard show == selectPhotoView.isHidden else { return }
        if show {
            self.selectPhotoView.isHidden = false
            self.selectPhotoView.alpha = 0
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.selectPhotoView.alpha = 1
                self.collectionView.contentInset = UIEdgeInsets(top: selectPhotoViewHeight - self.navigationController!.navigationBar.bounds.height + 8, left: 0, bottom: 0, right: 0)
            }, completion: nil)
        } else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.selectPhotoView.isHidden = true
                self.collectionView.contentInset = .zero
            }, completion: { _ in
                complete?()
            })
        }
    }

    func enableFooterView(_ enable: Bool) {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        if enable {
            flowLayout.footerReferenceSize = CGSize(width: self.collectionView.bounds.width, height: 60)
        } else {
            flowLayout.footerReferenceSize = CGSize.zero
        }
    }
    
    fileprivate func scrollToBottom(animated: Bool = false) {
        let totalItemCount = self.collectionView(self.collectionView, numberOfItemsInSection: 0)
        self.collectionView.scrollToItem(at: IndexPath(row: totalItemCount - 1, section: 0), at: UICollectionView.ScrollPosition.centeredVertically, animated: animated)
    }
    
    
    func reload(scrollToBottom: Bool = false) {
        if let localIdentifier = fetchOptions.localIdentifier {
            let col = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil).firstObject!
            self.videoResult = PHAsset.fetchAssets(in: col, options: fetchOptions.phOptions)
        } else {
            fetchOptions.fillCollectionInfo()
            self.videoResult = PHAsset.fetchAssets(with: fetchOptions.phOptions)
        }
        
        self.collectionView.reloadData()
        
        if let videoResult = videoResult, videoResult.count > 0 {
            self.collectionView.restore()
            enableFooterView(true)
        } else {
            enableFooterView(false)
            self.collectionView.setEmptyMessage("\(fetchOptions.localizedTitle ?? "")中未找到\(galleryCategory.title)")
        }
        
        if scrollToBottom {
            self.scrollToBottom()
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
    
    var targetImageSize: CGSize {
        return UIScreen.main.bounds.size.applying(CGAffineTransform(scaleX: 1/2, y: 1/2))
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
            if self.galleryCategory == .video {
                cell.setVideoDuration(asset.duration.formatTime()!)
            } else if self.galleryCategory == .livePhoto {
                cell.showLivePhotoIcon()
            } else if self.galleryCategory == .photo {
                cell.showAsPhoto(sequence: self.selectPhotoView.getSequence(forIdentifier: asset.localIdentifier))
            }
        }
        cell.tag = Int(requestId)
        
        return cell
    }
    

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer", for: indexPath) as! GalleryBottomInfoView
        footer.setVideoCount(self.collectionView(collectionView, numberOfItemsInSection: 0), category: galleryCategory.title, collectionTitle: fetchOptions.localizedTitle)
        return footer
    }
    
    var selectedIndexPath: IndexPath!
    
    fileprivate func onSelectPlayableItem(at: IndexPath) {
        guard let videoResult = videoResult else {
            fatalError()
        }
        
        selectedIndexPath = at
        
        let videoAsset: PHAsset = videoResult.object(at: at.row)
        let previewImage: UIImage = selectedCell.imageView.image!
        if videoAsset.duration > EditGalleryDurationThreshold.seconds {
            let rangeVC = storyboard!.instantiateViewController(withIdentifier: "videoRange") as! VideoRangeViewController
            rangeVC.previewAsset = videoAsset
            navigationController?.pushViewController(rangeVC, animated: true)
        } else {
            let editVC = storyboard!.instantiateViewController(withIdentifier: "editViewController") as! EditViewController
            editVC.previewImage = previewImage
            if galleryCategory == .video {
                editVC.videoAsset = videoAsset
                editVC.initTrimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: CMTime(seconds: videoAsset.duration, preferredTimescale: 600))
            } else {
                editVC.livePhotoAsset = videoAsset
            }
            navigationController?.pushViewController(editVC, animated: true)
        }
    }
    
    func refreshPhotoCells() {
        showSelectPhotoView(selectPhotoView.items.count > 0)
        collectionView.visibleCells.forEach { cell in
            let asset = videoResult![collectionView.indexPath(for: cell)!.row]
            (cell as! VideoGalleryCell).showAsPhoto(sequence: selectPhotoView.getSequence(forIdentifier: asset.localIdentifier))
        }
    }
    
    private func onSelectPhotoItem(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? VideoGalleryCell, let image = cell.imageView.image else {
            return
        }
        
        if let asset = videoResult?.object(at: indexPath.row) {
            if let sequence = selectPhotoView.getSequence(forIdentifier: asset.localIdentifier) {
                selectPhotoView.removeItem(at: sequence)                
            } else {
                selectPhotoView.addItem(GallerySelectPhotoItem(assetIdentifier: asset.localIdentifier, image: image))
                cell.showAsPhoto(sequence: selectPhotoView.getSequence(forIdentifier: asset.localIdentifier))
            }
            
            refreshPhotoCells()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch galleryCategory {
        case .video, .livePhoto:
            onSelectPlayableItem(at: indexPath)
        case .photo:
            onSelectPhotoItem(at: indexPath)
        }
    }
    
    @IBAction func onScrollToBottomButtonTapped(_ sender: Any) {
        scrollToBottom(animated: true)
    }
    
    func showScrollToBottomButton(_ show: Bool) {
        guard show != isScrollToBottomButtonShowed else { return }
        if show {
            isScrollToBottomButtonShowed = true
            scrollToBottomButton.alpha = 0
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.scrollToBottomButton.alpha = 1
            }, completion: nil)
        } else {
            isScrollToBottomButtonShowed = false
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.scrollToBottomButton.alpha = 0
            }, completion: nil)
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetToTheBottom = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.height)
        showScrollToBottomButton(offsetToTheBottom > 300)
    }
    
    @IBAction func onMakeGifFromPhotos(_ sender: UIBarButtonItem) {
        let identifiers = selectPhotoView.selectedIdentifiers
        self.showSelectPhotoView(false) {
            self.selectPhotoView.items.removeAll()
            self.selectPhotoView.collectionView.reloadData()
            self.selectPhotoView.removeFromSuperview()
            self.refreshPhotoCells()
        }
        let vc = self.storyboard!.instantiateViewController(withIdentifier: "editViewController") as! EditViewController
        vc.photoIdentifiers = identifiers
        self.navigationController?.pushViewController(vc, animated: true)
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
    
    func onSelectGalleryCategory(_ galleryCategory: GalleryCategory) {
        slideDownPanel(false)
        self.galleryCategory = galleryCategory
        switcher.setSelected(false, anim: true)
        fetchOptions.mediaSubtype = galleryCategory.mediaSubtype
        fetchOptions.mediaType = galleryCategory.mediaType
        reload(scrollToBottom: true)
        
        switcher.category = galleryCategory
    }
    
    @objc func onDimClicked(sender: UITapGestureRecognizer) {
        slideDownPanel(false)
        switcher.setSelected(false, anim: true)
    }
}

// MARK: - AlbumViewControllerDelegate
extension VideoGalleryViewController: AlbumViewControllerDelegate {
    func onUpdateFetchOptions(localIdentifier: String?, localizedTitle: String?) {
        fetchOptions.localIdentifier = localIdentifier
        fetchOptions.localizedTitle = localizedTitle
        reload(scrollToBottom: true)
    }
}

// MARK: - GallerySelectPhotoViewDelegate
extension VideoGalleryViewController: GallerySelectPhotoViewDelegate {
    func onRemoveSelectedPhoto(withIdentifier: String) {
        refreshPhotoCells()
    }
    
    func onRemoveAllSelectedPhotos() {
        refreshPhotoCells()
        showSelectPhotoView(false)
    }
}
