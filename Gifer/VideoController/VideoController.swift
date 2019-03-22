//
//  VideoController.swift
 //  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVKit

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to limits: CountableClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension UIImage {
    func draw(centerIn rect: CGRect) {
        let origin = CGPoint(x: rect.midX - size.width/2, y: rect.midY - size.height/2)
        return draw(in: CGRect(origin: origin, size: size))
    }
}



enum SlideState {
    case begin, slide, end
}

protocol SlideVideoProgressDelegate: class {
    func onSlideVideo(state: SlideState, progress: CMTime!)
}

protocol VideoTrimDelegate: class {
    func onTrimChanged(position: VideoTrimPosition, state: VideoTrimState)
}

enum VideoTrimState {
    case started, moving, initial
    case finished(Bool)
}
struct VideoTrimPosition {
    
    var leftTrim: CMTime
    
    var rightTrim: CMTime
    
    @available(*, deprecated, renamed: "galleryDuration")
    var range: CMTime {
        return rightTrim - leftTrim
    }
    
    var timeRange: CMTimeRange {
        return CMTimeRange(start: leftTrim, end: rightTrim)
    }
    
    var galleryDuration: CMTime {
        return rightTrim - leftTrim
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(16)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(8)
}

protocol VideoControllerDelegate: VideoTrimDelegate, SlideVideoProgressDelegate, VideoControllerGallerySliderDelegate {
}

enum VideoControllerScrollReason {
    case other, slider
}

extension Array where Element: NSLayoutConstraint {
    func findById(id: String) -> NSLayoutConstraint {
        return first {$0.identifier == id}!
    }
}

class VideoController: UIStackView {
    
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
    
    var delegate: VideoControllerDelegate? {
        didSet {
            videoSlider.delegate = self.delegate
            videoTrim.trimDelegate = self.delegate
            gallerySlider.delegate = self.delegate
        }
    }
    
    @IBInspectable var from: String = "range"
    var scrollView: UIScrollView!
    var generator: AVAssetImageGenerator?
    var galleryDuration: CMTime {
        return gallerySlider.galleryDuration!
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
    
    override func awakeFromNib() {
        axis = .vertical
        
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        isLayoutMarginsRelativeArrangement = true
        
        galleryContainer = VideoControllerGalleryContainer()
        addArrangedSubview(galleryContainer)
        galleryContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            galleryContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryContainer.heightAnchor.constraint(equalToConstant: 48)])
        
        gallerySlider = VideoControllerGallerySlider()
        addArrangedSubview(gallerySlider)
        gallerySlider.setup()
        gallerySlider.alpha = 0

        setupScrollView()

        galleryView = VideoControllerGallery()
        scrollView.addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView)
        
        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
        
        if from == "edit" {
            setupForEditViewController()
        }
    }
    
    private func setupForEditViewController() {
        scrollView.isScrollEnabled = false
        gallerySlider.isHidden = true
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.layoutMargins.top = 0
        scrollView.layoutMargins.bottom = 0
        scrollView.layoutMargins.left = 0
        scrollView.layoutMargins.right = 0
        scrollView.alwaysBounceVertical = false
        
        galleryContainer.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalTo: galleryContainer.heightAnchor),
            scrollView.topAnchor.constraint(equalTo: galleryContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: galleryContainer.leadingAnchor),
            scrollView.widthAnchor.constraint(equalTo: galleryContainer.widthAnchor)])
        scrollView.delegate = self
    }
    
    fileprivate func loadGallery(withImage image: UIImage, index: Int) -> Void {
        galleryView.setImage(image, on: index)
    }        
    
    func hideSlider(_ hide: Bool) {
        videoSlider.isHidden = hide
    }
    
    func load(playerItem: AVPlayerItem, gifMaxDuration: Double = 8, completion: @escaping () -> Void) -> Void {
        
        guard playerItem.asset.duration.value > 0 else {
            return
        }
        duration = playerItem.asset.duration
        self.videoTrim.duration = duration
        self.videoSlider.duration = duration
        
        gallerySlider.alpha = 1.0
        
        var thumbernailCount: Int
        var galleryDuration: CMTime
        if duration.seconds > gifMaxDuration {
            thumbernailCount = Int(duration.seconds/gifMaxDuration * Double(videoControllerGalleryImageCountPerGroup))
            galleryDuration = CMTime(seconds: gifMaxDuration, preferredTimescale: duration.timescale)
        } else {
            thumbernailCount = videoControllerGalleryImageCountPerGroup
            galleryDuration = duration
        }
        
        galleryDuration = galleryDuration.convertScale(videoTimeScale, method: .default)
        self.videoTrim.galleryDuration = galleryDuration
        self.videoSlider.galleryDuration = galleryDuration
        self.galleryView.galleryDuration = galleryDuration
        self.galleryView.duration = duration
        self.gallerySlider.onVideoLoaded(galleryDuration: galleryDuration, duration: duration)
        
        self.galleryView.prepareImageViews(thumbernailCount)
        self.galleryView.bringSubviewToFront(self.videoSlider)
        self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        completion()
        
        var thumbernailTimes = [NSValue]()
        for i in 0..<thumbernailCount {
            if dismissed {
                return
            }

            let time = CMTimeMultiplyByRatio(playerItem.asset.duration, multiplier: Int32(i), divisor: Int32(thumbernailCount))
            thumbernailTimes.append(NSValue(time: time))
        }

        self.generator = AVAssetImageGenerator(asset: playerItem.asset)
        var index = 0
        self.generator?.maximumSize = CGSize(width: 100, height: 100)
        let queue = DispatchQueue(label: "generate thumbernails")
        self.generator?.appliesPreferredTrackTransform = true
        queue.async {
            self.generator?.generateCGImagesAsynchronously(forTimes: thumbernailTimes) { [weak self] (_, image, _, _, _) in
                guard let self = self else { return }
                
                guard image != nil else { return }
                
                let thumbernail: UIImage = UIImage(cgImage: image!)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.loadGallery(withImage: thumbernail, index: index)
                    index = index + 1
                }
            }
        }
    }
    
    func updateSliderProgress(_ progress: CMTime) {
        videoSlider.updateProgress(progress: progress)
        videoSlider.show(true)
    }
}

// MARK: - Gallery scroll container
extension VideoController: UIScrollViewDelegate {
    
    func scrollTo(position: VideoTrimPosition) {
        let left = CGFloat(position.leftTrim.seconds/duration.seconds)*(scrollView.contentSize.width)
        scrollView.contentOffset = CGPoint(x: left, y: 0)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollReason != .slider else { return }
        delegate?.onTrimChanged(position: trimPosition, state: .started)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollReason != .slider else { return }
        delegate?.onTrimChanged(position: trimPosition, state: .finished(true))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollReason != .slider else { return }
        delegate?.onTrimChanged(position: trimPosition, state: .moving)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollReason != .slider else { return }
        if !scrollView.isDecelerating {
            delegate?.onTrimChanged(position: trimPosition, state: .finished(true))
        }
    }
}
