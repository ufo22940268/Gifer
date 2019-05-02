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
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState)
    func onTrimChangedByScrollInGallery(trimPosition position: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime)
}

enum VideoTrimState {
    case started, moving(seekToSlider: Bool), initial
    case finished(Bool)
}

struct VideoTrimPosition: CustomStringConvertible {
    
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
    
    func getSliderPosition(sliderRelativeToTrim: CGFloat) -> CMTime {
        return leftTrim + CMTimeMultiplyByFloat64(galleryDuration, multiplier: Float64(sliderRelativeToTrim))
    }
    
    func contains(_ time: CMTime) -> Bool {
        return time >= leftTrim && time <= rightTrim
    }
    
    var description: String {
        return "left trim: \(leftTrim.seconds)s right trim: \(rightTrim.seconds)s"
    }
    
    mutating func scrollBy(_ delta: CMTime) {
        leftTrim = leftTrim + delta
        rightTrim = rightTrim + delta
    }
    
    func leftPercent(in duration: CMTime) -> CGFloat {
        return CGFloat(leftTrim.seconds/duration.seconds)
    }
    
    func rightPercent(in duration: CMTime) -> CGFloat {
        return CGFloat(rightTrim.seconds/duration.seconds)
    }
}

struct GalleryRangePosition {
    var left: CMTime
    var right: CMTime
    
    var duration: CMTime {
        return right - left
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(16)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(8)
}

protocol VideoControllerDelegate: VideoTrimDelegate, SlideVideoProgressDelegate, VideoControllerGallerySliderDelegate, VideoControllerAttachDelegate {
}

enum VideoControllerScrollReason {
    case other, slider
}

extension Array where Element: NSLayoutConstraint {
    func findById(id: String) -> NSLayoutConstraint {
        return first {$0.identifier == id}!
    }
}

extension UIGestureRecognizer {
    var videoTrimState: VideoTrimState {
        switch self.state {
        case .began:
            return .started
        case .ended:
            return .finished(false)
        default:
            return .moving(seekToSlider: true)
        }
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
    
    var delegate: VideoControllerDelegate? {
        didSet {
            videoSlider.delegate = self.delegate
            videoTrim.trimDelegate = self.delegate
            gallerySlider.delegate = self.delegate
            attachView.customDelegate = self.delegate
        }
    }
    
    @IBInspectable var from: String = "range"
    var galleryScrollView: UIScrollView!
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
    var currentTimeOnSlider: CMTime {
        let range = galleryRangeInTrim
        let sliderCenter = videoSlider.frame.center.x - videoSlider.sliderRangeGuide.layoutFrame.minX
        let sliderPosition = sliderCenter/(videoSlider.sliderRangeGuide.layoutFrame.width)
        return range.left + CMTimeMultiplyByFloat64(range.duration, multiplier: Double(sliderPosition))
    }
    
    lazy var attachView: VideoControllerAttachView = {
        let attach = VideoControllerAttachView().useAutoLayout()
        attach.isHidden = true
        return attach
    }()
    
    lazy var attachGalleryView: UIView = {
        return UIView().useAutoLayout()
    }()
    
    var layoutSize: Size = .full {
        didSet {
            galleryContainer.constraints.findById(id: "height").constant = layoutSize.height
        }
    }
    
    var galleryRangeInTrim: GalleryRangePosition {
        guard let duration = duration else { fatalError() }
        let trimFrame = videoTrim.frame.applying(CGAffineTransform(scaleX: 1/bounds.width, y: 1/bounds.height))
        let convertRelativeToDuration = {(ratio: CGFloat) in
            return (Double(ratio)*self.galleryDuration.seconds + self.trimPosition.leftTrim.seconds)/duration.seconds
        }
        let left = CMTimeMultiplyByFloat64(duration, multiplier: convertRelativeToDuration(trimFrame.minX))
        let right = CMTimeMultiplyByFloat64(duration, multiplier: convertRelativeToDuration(trimFrame.maxX))
        return GalleryRangePosition(left: left, right: right)
    }
    
    override func awakeFromNib() {
        axis = .vertical
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        isLayoutMarginsRelativeArrangement = true
        spacing = 4
        
        galleryContainer = VideoControllerGalleryContainer()
        addArrangedSubview(galleryContainer)
        galleryContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            galleryContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            galleryContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            galleryContainer.heightAnchor.constraint(equalToConstant: 48).with(identifier: "height")])

        addArrangedSubview(attachView)
        attachView.customDelegate = delegate
        
        gallerySlider = VideoControllerGallerySlider()
        addArrangedSubview(gallerySlider)
        gallerySlider.setup()
        gallerySlider.alpha = 0

        setupScrollView()

        galleryView = VideoControllerGallery()
        galleryScrollView.addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView)
        
        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
        
        if from == "edit" {
            setupForEditViewController()
        } else {
            setupForVideoRangeViewController()
        }
        videoTrim.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.onTrimPan(sender:))))
    }
    
    private func setupForEditViewController() {
        galleryScrollView.isScrollEnabled = false
        gallerySlider.isHidden = true
        
        videoTrim.disableScroll = false
    }
    
    private func setupForVideoRangeViewController() {
        videoTrim.disableScroll = false
        galleryScrollView.delegate = self
    }
    
    @objc func onTrimPan(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: videoTrim)
        if videoTrim.move(by: translation.x) {
            delegate?.onTrimChangedByScrollInGallery(trimPosition: trimPosition, state: sender.videoTrimState, currentPosition: videoSlider.currentPosition)
        }
        sender.setTranslation(CGPoint.zero, in: videoTrim)
    }
    
    func setupScrollView() {
        galleryScrollView = UIScrollView()
        galleryScrollView.translatesAutoresizingMaskIntoConstraints = false
        galleryScrollView.layoutMargins.top = 0
        galleryScrollView.layoutMargins.bottom = 0
        galleryScrollView.layoutMargins.left = 0
        galleryScrollView.layoutMargins.right = 0
        galleryScrollView.alwaysBounceVertical = false
        galleryScrollView.isScrollEnabled = false
        
        galleryContainer.addSubview(galleryScrollView)
        NSLayoutConstraint.activate([
            galleryScrollView.heightAnchor.constraint(equalTo: galleryContainer.heightAnchor),
            galleryScrollView.topAnchor.constraint(equalTo: galleryContainer.topAnchor),
            galleryScrollView.leadingAnchor.constraint(equalTo: galleryContainer.leadingAnchor),
            galleryScrollView.widthAnchor.constraint(equalTo: galleryContainer.widthAnchor)])
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
        self.galleryView.galleryDuration = galleryDuration
        self.galleryView.duration = duration
        self.gallerySlider.onVideoLoaded(galleryDuration: galleryDuration, duration: duration)
        self.galleryView.prepareImageViews(thumbernailCount)
        self.galleryView.bringSubviewToFront(self.videoSlider)
        self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        self.attachView.duration = duration
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
    
    func vupdateFrameColor(duration: CMTime) {
        videoTrim.updateFrameColor(duration: duration)
    }
    
    func onActive(component: OverlayComponent) {
        attachView.isHidden = false
        attachView.load(image: component.image, component: component)
        layoutSize = .half
    }
    
    func onDeactiveComponents() {
        attachView.isHidden = true
        layoutSize = .full
    }
    
}

// MARK: - Gallery scroll container
extension VideoController: UIScrollViewDelegate {
    
    var inEditing: Bool {
        return from == "edit"
    }
    
    func galleryScrollTo(galleryRange: GalleryRangePosition) {
        let leading = galleryRange.left.seconds/duration.seconds
        let offsetX = CGFloat(leading)*galleryScrollView.contentSize.width
        galleryScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
    }
    
    func keepSliderPosition() {
        
    }
}
