//
//  FramesViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import Photos

protocol FramesDelegate: class {
    func onUpdateFrames(_ frames: [ImagePlayerFrame])
}

class FramesViewController: UIViewController {
    
    var playerItem: ImagePlayerItem! {
        didSet {
            if isViewLoaded {
                frameLabelCollectionView.playerItem = playerItem
            }
        }
    }
    
    var openAddPlayerItemPage = false
    
    @IBOutlet weak var frameCollectionView: UICollectionView!
    weak var customDelegate: FramesDelegate?
    var trimPosition: VideoTrimPosition!
    var customTransitionDelegate = OverlayTransitionAnimator()
    
    var loadingDialog = LoadingDialog(label: "加载中...")

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
            getTestPlayerItem { (playerItem, asset) in
                self.playerItem = ImagePlayerItem(frames: playerItem.allFrames, duration: CMTime(seconds: 3, preferredTimescale: 600), videoAsset: asset)
                self.trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: CMTime(seconds: 2, preferredTimescale: 600))
                self.frameCollectionView.reloadData()
                self.frameLabelCollectionView.reloadData()
            }
        }
        
        frameLabelCollectionView.playerItem = playerItem
        frameLabelCollectionView.customDelegate = self
        let flowLayout = frameCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let gap = CGFloat(2)
        let width: CGFloat = (view.bounds.width - 3*gap)/4
        flowLayout.minimumLineSpacing = gap
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.itemSize = CGSize(width: width, height: width)
        
        frameCollectionView.allowsMultipleSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard playerItem != nil else { return }
        frameCollectionView.reloadData()
        rootFrames.enumerated()
            .filter { !$0.element.isActive }.map { $0.offset }
            .forEach { frameCollectionView.selectItem(at: IndexPath(row: $0, section: 0), animated: false, scrollPosition: .left)}
        frameCollectionView.contentOffset = .zero
        
        if openAddPlayerItemPage {
            onAppendPlayerItem()
        }
    }
    
    @IBAction func onDone(_ sender: Any) {
        customDelegate?.onUpdateFrames(playerItem.allFrames)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func onTapRootView(_ sender: Any) {
        frameLabelCollectionView.dismissSelection()
    }
}

extension FramesViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !frameLabelCollectionView.visibleCells.contains { (cell) -> Bool in
            return cell.point(inside: gestureRecognizer.location(in: cell), with: nil)
        }
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
        
        let id = playerItem.requestImage(frame: frame, size: CGSize(width: 200, height: 200), complete: { (image) in
            cell.image.image = image
        })
        
        cell.tag = id
        cell.imageFrame = frame
        cell.sequence = sequence(for: frame)
        if let color = frame.label?.color {
            cell.sequenceView.backgroundColor = color
        }
        cell.delegate = self
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
    
    fileprivate func updateSequences() {
        frameCollectionView.visibleCells.forEach { cell in
            let cell = cell as! FrameCell
            cell.sequence = sequence(for: cell.imageFrame)
        }
    }
    
    fileprivate func sequence(for frame: ImagePlayerFrame) -> Int? {
        if let seq = (rootFrames.filter { $0.isActive }.enumerated().first { $0.element == frame}.map { $0.offset }) {
            return seq + 1
        } else {
            return nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _ = rootFrames[indexPath.row]
        rootFrames[indexPath.row].isActive = false
        updateSequences()
   }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        _ = rootFrames[indexPath.row]
        rootFrames[indexPath.row].isActive = true
        updateSequences()
    }
}

extension FramesViewController: FrameCellDelegate {
    func onOpenPreview(frame: ImagePlayerFrame) {
        let nvc = storyboard?.instantiateViewController(withIdentifier: "framePreview") as! UINavigationController
        let vc = nvc.topViewController as! FramePreviewViewController
        vc.currentIndex = rootFrames.firstIndex { $0 === frame}!
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

extension FramesViewController: FrameLabelCollectionViewDelegate {
    func onDeleteLabel(_ label: ImagePlayerItemLabel) {
        let labelIndexesToDelete: [IndexPath] = [IndexPath(row: playerItem.labels.firstIndex { $0 === label }!, section: 0)]
        let frameIndexesToDelete: [IndexPath] = rootFrames.enumerated().filter { $0.1.label === label }.map { IndexPath(row: $0.0, section: 0) }
        playerItem.deleteLabel(label)
        frameLabelCollectionView.deleteItems(at: labelIndexesToDelete)
        frameCollectionView.deleteItems(at: frameIndexesToDelete)
        updateSequences()
    }
    
    func onAppendPlayerItem() {
        let vc = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "root") as! RootNavigationController
        vc.transitioningDelegate = self.customTransitionDelegate
        vc.modalPresentationStyle = .custom
        vc.modalPresentationCapturesStatusBarAppearance = true
        vc.customDelegate = self
        vc.mode = .append
        vc.appendFPS = FPSFigure.build(fromInterval: playerItem.frameInterval)
        vc.currentFrameCount = playerItem.rootFrames.count
        self.present(vc, animated: true, completion: nil)
    }
    
    func onLabelSelected(_ label: ImagePlayerItemLabel) {
        let firstIndex = rootFrames.firstIndex { $0.label === label }
        frameCollectionView.scrollToItem(at: IndexPath(row: firstIndex!, section: 0), at: .top, animated: true)
    }
    
    func onClipLabel(_ label: ImagePlayerItemLabel) {
        let rangeVC = AppStoryboard.Main.instance.instantiateViewController(withIdentifier: "videoRange") as! VideoRangeViewController
        rangeVC.previewAsset = label.videoAsset
        
        let nvc = RootNavigationController(rootViewController: rangeVC)
        nvc.transitioningDelegate = self.customTransitionDelegate
        nvc.modalPresentationStyle = .custom
        nvc.modalPresentationCapturesStatusBarAppearance = true
        nvc.customDelegate = self
        nvc.mode = .append
        nvc.appendFPS = FPSFigure.build(fromInterval: playerItem.frameInterval)
        nvc.editLabel = label
        nvc.currentFrameCount = playerItem.rootFrames.count
        self.present(nvc, animated: true, completion: nil)
    }
}

extension FramesViewController: RootNavigationControllerDelegate {
    fileprivate func appendPlayerItem(_ playerItem: ImagePlayerItem) {
        let originCount = self.rootFrames.count
        self.playerItem.concat(playerItem)
        self.frameLabelCollectionView.animateAfterInsertItem()
        self.frameCollectionView.insertItems(at: (originCount..<(originCount + playerItem.allFrames.count)).map { IndexPath(row: $0, section: 0) })
        self.frameCollectionView.scrollToItem(at: IndexPath(row: originCount, section: 0), at: .top, animated: true)
    }
    
    fileprivate func replacePlayerItem(with playerItem: ImagePlayerItem, on label: ImagePlayerItemLabel) {
        self.playerItem.replace(with: playerItem, on: label)
        self.frameCollectionView.reloadData()
    }
    
    func completeSelectVideo(asset: PHAsset, trimPosition: VideoTrimPosition, label: ImagePlayerItemLabel?) {
        loadingDialog.show(by: self)
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, _) in
            guard let avAsset = avAsset else { return }
            let playerItemGenerator = ImagePlayerItemGenerator(avAsset: avAsset, asset: asset, trimPosition: trimPosition, fps: .f5, shouldCleanDirectory: false)
            playerItemGenerator.run { playerItem in
                if let label = label {
                    self.replacePlayerItem(with: playerItem, on: label)
                } else {
                    self.appendPlayerItem(playerItem)
                }
                self.loadingDialog.dismiss()
            }
        }
    }
    
    func completeSelectPhotos(identifiers: [String]) {
        loadingDialog.show(by: self)
        let makePlayerItemFromPhotosTask = MakePlayerItemFromPhotosTask(identifiers: identifiers)
        makePlayerItemFromPhotosTask.run { playerItem in
            if let playerItem = playerItem {
                self.appendPlayerItem(playerItem)
            }
            self.loadingDialog.dismiss()
        }
    }
}
