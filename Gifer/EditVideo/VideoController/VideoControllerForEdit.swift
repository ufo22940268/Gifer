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
    var duration: CMTime!
    
    var scrollReason: VideoControllerScrollReason = .other
    var currentTimeOnSlider: CMTime {
        return videoSlider.currentPosition
    }
    
    lazy var attachView: VideoControllerAttachView = {
        let attach = VideoControllerAttachView().useAutoLayout()
        return attach
    }()
    
    var galleryFrames = [ImagePlayerFrame]()
    
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
        
        galleryView = VideoControllerGallery()
        galleryContainer.addSubview(galleryView)
        galleryView.dataSource = self
        galleryView.setup(hasAppendButton: true)
        galleryView.register(VideoControllerGalleryImageCell.self, forCellWithReuseIdentifier: "image")
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView, hasAppendButton: true)
        
        galleryContainer.addSubview(appendPlayerButton)
        NSLayoutConstraint.activate([
            appendPlayerButton.heightAnchor.constraint(equalToConstant: 48),
            appendPlayerButton.widthAnchor.constraint(equalTo: appendPlayerButton.heightAnchor, constant:  -8),
            appendPlayerButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            appendPlayerButton.trailingAnchor.constraint(equalTo: galleryContainer.trailingAnchor, constant: 16),
            ])

        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
        
        let scrollRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.onScroll(sender:)))
        scrollRecognizer.delegate = self
        videoTrim.addGestureRecognizer(scrollRecognizer)
    }
    
    @objc func onAddNewPlayerItem() {
        delegate?.onAddNewPlayerItem()
    }
        
    @objc func onScroll(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: videoTrim)
        if videoTrim.move(by: translation.x) {
            delegate?.onTrimChangedByScrollInGallery(trimPosition: trimPosition, state: sender.videoTrimState, currentPosition: videoSlider.currentPosition)
        }
        sender.setTranslation(CGPoint.zero, in: videoTrim)
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
        let expectThumbernailCount = max(Int(self.galleryView.bounds.width/40), 8)
        let thumbernailCount = min(expectThumbernailCount, playerItem.activeFrames.count)
        
        var itemWidth = galleryView.frame.width/CGFloat(thumbernailCount)
        galleryView.setItemSize(CGSize(width: itemWidth, height: galleryView.frame.height))

        galleryFrames.removeAll()
        let step = Int(floor(Double(playerItem.activeFrames.count)/Double(thumbernailCount)))
        var galleryIndex = 0
        for i in stride(from: 0, to: playerItem.activeFrames.count, by: step) {
            if galleryIndex >= thumbernailCount {
                break
            }

            let frame = playerItem.activeFrames[i]
            galleryFrames.append(frame)
            galleryIndex += 1
        }
        galleryView.reloadData()
    }
    
    func loadInEditVideo(playerItem: ImagePlayerItem, completion: @escaping () -> Void) -> Void {
        updatePlayerItem(playerItem)
        self.videoTrim.onVideoReady()
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
        switch component.info.type! {
        case .sticker:
            attachView.load(image: component.image, component: component)
        case .text:
            let textRender = component.render as! TextRender
            attachView.load(text: textRender.info.text, component: component)
        }
        layoutSize = .half
    }
    
    func onDeactiveComponents() {
        attachContainer.isHidden = true
        layoutSize = .full
    }
    
}

// MARK: - Gallery scroll container
extension VideoControllerForEdit: UIScrollViewDelegate {
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

extension VideoControllerForEdit: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return galleryFrames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! VideoControllerGalleryImageCell
        loadImage(at: indexPath, for: cell)
        return cell
    }
    
    func loadImage(at index: IndexPath, for cell: VideoControllerGalleryImageCell) {
        let frame = galleryFrames[index.row]
        playerItem.requestImage(frame: frame) { (image) in
            cell.imageView.image = image
        }
    }
}
