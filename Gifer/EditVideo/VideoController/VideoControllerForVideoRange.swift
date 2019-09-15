//
//  VideoControllerForVideoRange.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/14.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class VideoControllerForVideoRange: UIStackView {
    
    var galleryView: VideoControllerGallery!
    var videoSlider: VideoControllerSlider!
    var videoTrim: VideoControllerTrim!
    var dismissed = false {
        didSet {
            if dismissed {
                generator?.cancelAllCGImageGeneration()
            }
        }
    }
    
    enum Size {
        case full, half
        
        var height: CGFloat {
            switch self {
            case .full:
                return 48
            case .half:
                return 20
            }
        }
    }
    
    weak var customDelegate: VideoControllerForVideoRangeDelegate? {
        didSet {
            videoSlider.delegate = self.customDelegate
            videoTrim.trimDelegate = self.customDelegate
        }
    }
    
    var generator: AVAssetImageGenerator?
    var galleryDuration: CMTime {
        return videoTrim.trimPosition.galleryDuration
    }
    var trimPosition: VideoTrimPosition {
        get {
            return videoTrim.trimPosition
        }
    }
    var galleryContainer: VideoControllerGalleryContainer!
    var gallerySlider: VideoControllerGallerySlider!
    var duration: CMTime!
    
    var scrollReason: VideoControllerScrollReason = .other
    let queue = DispatchQueue(label: "generate thumbernails")
    var currentTimeOnSlider: CMTime {
        return videoSlider.currentPosition
    }
    
    var stickToSide: ControllerTrim.Side? {
        didSet {
            guard let stickToSide = stickToSide else { return }
            switch stickToSide {
            case .left:
                videoSlider.updateProgress(percent: 0)
            case .right:
                videoSlider.updateProgress(percent: 1)
            }
            videoSlider.show(true)
        }
        
    }
    
    var layoutSize: Size = .full {
        didSet {
            galleryContainer.constraints.findById(id: "height").constant = layoutSize.height
        }
    }
    
    var playerItem: AVPlayerItem?
    var thumbernailTimes: [NSValue]?
    
    var thumbernailCount: Int?
    
    override func awakeFromNib() {
        axis = .vertical
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        isLayoutMarginsRelativeArrangement = true
        spacing = 4
        tintColor = UIColor(named: "yellowColor")
        
        galleryContainer = VideoControllerGalleryContainer()
        addArrangedSubview(galleryContainer)
        galleryContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            galleryContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryContainer.heightAnchor.constraint(equalToConstant: 48).with(identifier: "height")])
        
        gallerySlider = VideoControllerGallerySlider()
        addArrangedSubview(gallerySlider)
        gallerySlider.setup()
        gallerySlider.alpha = 0
        gallerySlider.customDelegate = self
        
        galleryView = VideoControllerGallery()
        galleryContainer.addSubview(galleryView)
        galleryView.dataSource = self
        galleryView.delegate = self
        galleryView.register(VideoControllerGalleryImageCell.self, forCellWithReuseIdentifier: "image")
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView, hasAppendButton: false)
        
        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
    }
    
    func stickTo(side: ControllerTrim.Side?) {
        stickToSide = side
    }
    
    func onVideoReady(playerItem: AVPlayerItem, gifMaxDuration: Double = 8, completion: @escaping () -> Void) -> Void {
        guard playerItem.asset.duration.value > 0 else {
            return
        }
        self.playerItem = playerItem
        duration = playerItem.asset.duration
        self.videoTrim.duration = duration
        self.videoSlider.duration = duration
        
        gallerySlider.alpha = 1.0
        
        var galleryDuration: CMTime
        var thumbernailCount: Int
        var galleryWidth: CGFloat
        if duration.seconds > gifMaxDuration {
            //Every 20s video have about 8 thumbernails. And each thumbernail has the same size.
            //So the width of gallery is critical, it must be the same relative to duration.
            thumbernailCount = Int(CGFloat(8)/CGFloat(20)*CGFloat(duration.seconds))
            galleryWidth = CGFloat(thumbernailCount)*galleryView.frame.width/8
            galleryDuration = CMTime(seconds: gifMaxDuration, preferredTimescale: duration.timescale)
        } else {
            thumbernailCount = Int(galleryView.frame.width/40)
            galleryWidth = galleryView.frame.width
            galleryDuration = duration
        }
        self.thumbernailCount = thumbernailCount
        galleryView.setItemSize(CGSize(width: galleryWidth/CGFloat(thumbernailCount), height: galleryView.bounds.height))

        videoTrim.galleryDuration = galleryDuration
        videoTrim.onVideoReady()
        galleryView.galleryDuration = galleryDuration
        galleryView.duration = duration
        gallerySlider.onVideoLoaded(galleryDuration: galleryDuration, duration: duration)
        galleryView.bringSubviewToFront(self.videoSlider)
        videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        galleryView.reloadData()
        completion()
        
        var thumbernailTimes = [NSValue]()
        for i in 0..<thumbernailCount {
            if dismissed {
                return
            }
            
            let time = CMTimeMultiplyByRatio(playerItem.asset.duration, multiplier: Int32(i), divisor: Int32(thumbernailCount))
            thumbernailTimes.append(NSValue(time: time))
        }
        self.thumbernailTimes = thumbernailTimes
    }
    
    func updateSliderProgress(percent: CGFloat) {
        if stickToSide != nil {
            return
        }
        videoSlider.updateProgress(percent: percent)
        videoSlider.show(true)
    }
    
    func updateRange(trimPosition: VideoTrimPosition) {
        videoTrim.updateRange(trimPosition: trimPosition)
    }
    
    func onActive(component: OverlayComponent) {
        layoutSize = .half
    }
    
    func onDeactiveComponents() {
        layoutSize = .full
    }
}

extension VideoControllerForVideoRange: UIGestureRecognizerDelegate {
    //Trimer scroll recognizer should begin.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var validArea = videoTrim.sliderRangeGuide.owningView!.convert(videoTrim.sliderRangeGuide.layoutFrame, to: videoTrim)
        if validArea.width > 80 {
            validArea = validArea.insetBy(dx: 20, dy: 0)
        }
        let p = gestureRecognizer.location(in: videoTrim)
        return p.x < validArea.maxX && p.x > validArea.minX
    }
}

//MARK: Gallery view thumbernails.
extension VideoControllerForVideoRange: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbernailCount ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! VideoControllerGalleryImageCell
        loadImage(at: indexPath.row, cell: cell)
        return cell
    }
    
    func loadImage(at row: Int, cell: VideoControllerGalleryImageCell) {
        guard let playerItem = playerItem, let thumbernailTimes = thumbernailTimes else { return }
        self.generator = AVAssetImageGenerator(asset: playerItem.asset)
        self.generator?.maximumSize = CGSize(width: 300, height: 300)
        self.generator?.appliesPreferredTrackTransform = true
        queue.async {
            self.generator?.generateCGImagesAsynchronously(forTimes: [thumbernailTimes[row]]) { [weak self] (_, image, _, _, _) in
                guard let self = self else { return }
                guard image != nil else { return }
                let thumbernail: UIImage = UIImage(cgImage: image!)
                DispatchQueue.main.async { [weak self] in
                    guard let _ = self else { return }
                    cell.imageView.image = thumbernail
                }
            }
        }
    }
}

// MARK: - Gallery scroll container
extension VideoControllerForVideoRange: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        customDelegate?.videoControllerGalleryDidScrolled(self, didFinished: false)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        customDelegate?.videoControllerGalleryDidScrolled(self, didFinished: true)
    }    
}

// MARK: - Gallery slider delegate
extension VideoControllerForVideoRange: VideoControllerGallerySliderDelegate {
    func onScroll(_ slider: VideoControllerGallerySlider, leftPercentage: CGFloat, didEndDragging: Bool) {
        if didEndDragging {
            customDelegate?.videoControllerGalleryDidScrolled(self, didFinished: true)
        } else {
            galleryView.contentOffset = CGPoint(x: galleryView.contentSize.width*leftPercentage, y: 0)
        }
    }
}

protocol VideoControllerForVideoRangeDelegate: VideoTrimDelegate, SlideVideoProgressDelegate, VideoControllerAttachDelegate {
    
    func videoControllerGalleryDidScrolled(_ videoController: VideoControllerForVideoRange, didFinished: Bool)
}

