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
    func onTrimChangedByTrimer(trimPosition: VideoTrimPosition, state: VideoTrimState, side: ControllerTrim.Side?)
    func onTrimChangedByScrollInGallery(trimPosition position: VideoTrimPosition, state: VideoTrimState, currentPosition: CMTime)
}

enum VideoTrimState {
    case started, moving(seekToSlider: Bool), initial
    case finished(Bool)
}

struct VideoTrimPosition: CustomStringConvertible {
    
    var leftTrim: CMTime
    var rightTrim: CMTime
    
    static var zero: VideoTrimPosition {
        return VideoTrimPosition(leftTrim: .zero, rightTrim: .zero)
    }
    
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
    
    func update(by frames: [ImagePlayerFrame]) -> VideoTrimPosition {
        var trimPosition = self
        trimPosition.leftTrim = frames.first!.time
        trimPosition.rightTrim = frames.last!.time
        return trimPosition
    }
}

struct GalleryRangePosition: CustomStringConvertible {
    var left: CMTime
    var right: CMTime
    
    var duration: CMTime {
        return right - left
    }
    
    func clamp(_ time: CMTime) -> CMTime {
        if time < left {
            return left
        } else if time > right {
            return right
        } else {
            return time
        }
    }
    
    mutating func scroll(by delta: CMTime) {
        left = left + delta
        right = right + delta
    }
    
    var description: String {
        return "\(left.seconds) ------- \(right.seconds)"
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(16)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(8)
}

protocol VideoControllerDelegate: VideoTrimDelegate, SlideVideoProgressDelegate, VideoControllerAttachDelegate {
    func onAddNewPlayerItem()
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

class VideoControllerForEdit: UIStackView {
    
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
    
    weak var delegate: VideoControllerDelegate? {
        didSet {
            videoSlider.delegate = self.delegate
            videoTrim.trimDelegate = self.delegate
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
        return videoSlider.currentPosition
    }
    
    lazy var attachView: VideoControllerAttachView = {
        let attach = VideoControllerAttachView().useAutoLayout()
        return attach
    }()
    
    lazy var attachGalleryView: UIView = {
        return UIView().useAutoLayout()
    }()
    
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
    
    var playerItem: ImagePlayerItem! {
        didSet {
            videoTrim.playerItem = playerItem
        }
    }
    
    var thumbernailCount: Int?
    
    var galleryRangeInSlider: GalleryRangePosition {
        guard let duration = duration else { fatalError() }
        let scrollRect = galleryScrollView.contentSize
        let outerFrame = galleryScrollView.convert(videoTrim.bounds, from: videoTrim)
        let outer = outerFrame.applying(CGAffineTransform(scaleX: 1/scrollRect.width, y: 1/scrollRect.height))
        return GalleryRangePosition(left: CMTimeMultiplyByFloat64(duration, multiplier: Float64(outer.minX)), right: CMTimeMultiplyByFloat64(duration, multiplier: Float64(outer.maxX)))
    }
    
    var galleryRangeInTrimer: GalleryRangePosition {
        guard let duration = duration else { fatalError() }
        let inner = videoTrim.innerFrame.applying(CGAffineTransform(scaleX: 1/galleryScrollView.contentSize.width, y: 1/galleryScrollView.contentSize.height))
        return GalleryRangePosition(left: CMTimeMultiplyByFloat64(duration, multiplier: Float64(inner.minX)), right: CMTimeMultiplyByFloat64(duration, multiplier: Float64(inner.maxX)))
    }
    
    lazy var appendPlayerButton: UIButton = {
        let button = UIButton(type: .custom).useAutoLayout()
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.backgroundColor = UIColor.darkGray.withAlphaComponent(0.6)
        button.tintColor = .white
        button.setImage(#imageLiteral(resourceName: "edit-plus.png"), for: .normal)
        button.addTarget(self, action: #selector(onAddNewPlayerItem), for: .touchUpInside)
        return button
    }()
    
    lazy var attachContainer: UIView = {
        let attachContainer = UIView().useAutoLayout()
        attachContainer.isHidden = true
        return attachContainer
    }()
    
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

        addArrangedSubview(attachContainer)
        attachContainer.addSubview(attachView)
        NSLayoutConstraint.activate([
            attachView.leadingAnchor.constraint(equalTo: attachContainer.leadingAnchor),
            attachView.heightAnchor.constraint(equalTo: attachContainer.heightAnchor),
            attachView.widthAnchor.constraint(equalTo: attachContainer.widthAnchor, constant: -40)
            ])
        attachView.customDelegate = delegate
        
        gallerySlider = VideoControllerGallerySlider()
        addArrangedSubview(gallerySlider)
        gallerySlider.setup()
        gallerySlider.alpha = 0

        setupScrollView()

        galleryView = VideoControllerGallery()
        galleryScrollView.addSubview(galleryView)
//        galleryView.dataSource = self
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView, hasAppendButton: from == "edit")
//        NSLayoutConstraint.activate([
//            videoTrim.widthAnchor.constraint(equalTo: galleryScrollView.widthAnchor)
//            ])
        
        if from == "edit" {
            galleryContainer.addSubview(appendPlayerButton)
            NSLayoutConstraint.activate([
                appendPlayerButton.heightAnchor.constraint(equalToConstant: 48),
                appendPlayerButton.widthAnchor.constraint(equalTo: appendPlayerButton.heightAnchor, constant:  -8),
                appendPlayerButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                appendPlayerButton.trailingAnchor.constraint(equalTo: galleryContainer.trailingAnchor, constant: 16),
                ])
        }

        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
        
        if from == "edit" {
            setupForEditViewController()
        } else {
            setupForVideoRangeViewController()
        }
        let scrollRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.onScroll(sender:)))
        scrollRecognizer.delegate = self
        videoTrim.addGestureRecognizer(scrollRecognizer)
    }
    
    @objc func onAddNewPlayerItem() {
        delegate?.onAddNewPlayerItem()
    }
    
    private func setupForEditViewController() {
        galleryScrollView.isScrollEnabled = false
    }
    
    private func setupForVideoRangeViewController() {
        galleryScrollView.delegate = self
    }
    
    @objc func onScroll(sender: UIPanGestureRecognizer) {
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
            galleryScrollView.leadingAnchor.constraint(equalTo: galleryContainer.leadingAnchor, constant: VideoControllerConstants.trimWidth),
            galleryScrollView.trailingAnchor.constraint(equalTo: galleryContainer.trailingAnchor, constant: -VideoControllerConstants.trimWidth)])
    }
    
    func stickTo(side: ControllerTrim.Side?) {
        stickToSide = side
    }
    
    func updatePlayerItem(_ playerItem: ImagePlayerItem) {
        let duration = playerItem.duration
        self.videoTrim.duration = duration
        self.videoSlider.duration = duration
        self.videoTrim.galleryDuration = duration
        self.galleryView.galleryDuration = duration
        self.galleryView.duration = duration
        self.attachView.duration = duration
        self.attachView.trimView.playerItem = playerItem
    }
    
    func loadGalleryImagesFromPlayerItem() {
//        let expectThumbernailCount = max(Int(self.galleryView.bounds.width/40), 8)
//        let thumbernailCount = min(expectThumbernailCount, playerItem.activeFrames.count)
//        self.galleryView.prepareImageViews(thumbernailCount)
//
//        let step = Int(floor(Double(playerItem.activeFrames.count)/Double(thumbernailCount)))
//        var galleryIndex = 0
//        for i in stride(from: 0, to: playerItem.activeFrames.count, by: step) {
//            if galleryIndex >= thumbernailCount {
//                break
//            }
//
//            let frame = playerItem.activeFrames[i]
//            let index = galleryIndex
//            playerItem.requestImage(frame: frame) { [weak self] (image) in
//                guard let self = self else { return }
//                self.galleryView.setImage(image, on: index)
//            }
//            galleryIndex += 1
//        }
    }
    
    func loadInEditVideo(playerItem: ImagePlayerItem, completion: @escaping () -> Void) -> Void {
        let duration = playerItem.duration
        
        updatePlayerItem(playerItem)
        
        gallerySlider.alpha = 1.0
        // TODO: When image player item generate process is synchronize, the gallery view width is 0.
        self.videoTrim.onVideoReady()
        self.gallerySlider.onVideoLoaded(galleryDuration: galleryDuration, duration: duration)
        self.galleryView.bringSubviewToFront(self.videoSlider)
        self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        completion()
        
        loadGalleryImagesFromPlayerItem()
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
        attachContainer.isHidden = false
        attachView.load(image: component.image, component: component)
        layoutSize = .half
    }
    
    func onDeactiveComponents() {
        attachContainer.isHidden = true
        layoutSize = .full
    }
    
}

// MARK: - Gallery scroll container
extension VideoControllerForEdit: UIScrollViewDelegate {
    
    var inEditing: Bool {
        return from == "edit"
    }
    
    func galleryScrollTo(galleryRange: GalleryRangePosition) {
        let leading = galleryRange.left.seconds/duration.seconds
        let offsetX = CGFloat(leading)*galleryScrollView.contentSize.width
        galleryScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
    }
}

extension VideoControllerForEdit: UIGestureRecognizerDelegate {
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



