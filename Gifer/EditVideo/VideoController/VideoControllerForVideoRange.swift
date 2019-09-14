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
    
    weak var delegate: VideoControllerDelegate? {
        didSet {
            videoSlider.delegate = self.delegate
            videoTrim.trimDelegate = self.delegate
            gallerySlider.delegate = self.delegate
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
    var gallerySlider: VideoControllerGallerySlider!
    var duration: CMTime!
    
    var scrollReason: VideoControllerScrollReason = .other
    let queue = DispatchQueue(label: "generate thumbernails")
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
    
    var playerItem: AVPlayerItem?
    var thumbernailTimes: [NSValue]?
    
    var thumbernailCount: Int?
    
    var galleryRangeInSlider: GalleryRangePosition {
        fatalError()
//        guard let duration = duration else { fatalError() }
//        let scrollRect = galleryScrollView.contentSize
//        let outerFrame = galleryScrollView.convert(videoTrim.bounds, from: videoTrim)
//        let outer = outerFrame.applying(CGAffineTransform(scaleX: 1/scrollRect.width, y: 1/scrollRect.height))
//        return GalleryRangePosition(left: CMTimeMultiplyByFloat64(duration, multiplier: Float64(outer.minX)), right: CMTimeMultiplyByFloat64(duration, multiplier: Float64(outer.maxX)))
    }
    
    var galleryRangeInTrimer: GalleryRangePosition {
        fatalError()
//        guard let duration = duration else { fatalError() }
//        let inner = videoTrim.innerFrame.applying(CGAffineTransform(scaleX: 1/galleryScrollView.contentSize.width, y: 1/galleryScrollView.contentSize.height))
//        return GalleryRangePosition(left: CMTimeMultiplyByFloat64(duration, multiplier: Float64(inner.minX)), right: CMTimeMultiplyByFloat64(duration, multiplier: Float64(inner.maxX)))
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
        
        galleryView = VideoControllerGallery()
        galleryContainer.addSubview(galleryView)
        galleryView.dataSource = self
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        galleryContainer.addSubview(videoTrim)
        videoTrim.setup(galleryView: galleryView, hasAppendButton: from == "edit")
        
        videoSlider = VideoControllerSlider()
        galleryContainer.addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
        
//        let scrollRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.onScroll(sender:)))
//        scrollRecognizer.delegate = self
//        videoTrim.addGestureRecognizer(scrollRecognizer)
    }
    
    @objc func onAddNewPlayerItem() {
        delegate?.onAddNewPlayerItem()
    }
    
    @objc func onScroll(sender: UIPanGestureRecognizer) {
//        let translation = sender.translation(in: videoTrim)
//        if videoTrim.move(by: translation.x) {
//            delegate?.onTrimChangedByScrollInGallery(trimPosition: trimPosition, state: sender.videoTrimState, currentPosition: videoSlider.currentPosition)
//        }
//        sender.setTranslation(CGPoint.zero, in: videoTrim)
    }
    
    
    func stickTo(side: ControllerTrim.Side?) {
        stickToSide = side
    }
    
    func loadInVideoRange(playerItem: AVPlayerItem, gifMaxDuration: Double = 8, completion: @escaping () -> Void) -> Void {
        guard playerItem.asset.duration.value > 0 else {
            return
        }
        self.playerItem = playerItem
        duration = playerItem.asset.duration
        self.videoTrim.duration = duration
        self.videoSlider.duration = duration
        
        gallerySlider.alpha = 1.0
        
        galleryView.register(VideoControllerGalleryImageCell.self, forCellWithReuseIdentifier: "image")
        var galleryDuration: CMTime
        var thumbernailCount: Int
        var galleryWidth: CGFloat
        if duration.seconds > gifMaxDuration {
            //Every 20s video have about 8 thumbernails. And each thumbernail has the same size.
            //So the width of gallery is critical, it must be the same relative to duration.
            thumbernailCount = Int(CGFloat(8)/CGFloat(20)*CGFloat(duration.seconds))
            galleryWidth = CGFloat(thumbernailCount)*galleryView.frame.width/8
            galleryDuration = CMTime(seconds: gifMaxDuration, preferredTimescale: duration.timescale)
            NSLayoutConstraint.activate([
                galleryView.widthAnchor.constraint(equalToConstant: galleryWidth)
                ])
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
        attachView.duration = duration
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
        attachContainer.isHidden = false
        attachView.load(image: component.image, component: component)
        layoutSize = .half
    }
    
    func onDeactiveComponents() {
        attachContainer.isHidden = true
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
extension VideoControllerForVideoRange: UIScrollViewDelegate {
    
    var inEditing: Bool {
        return from == "edit"
    }
    
    func galleryScrollTo(galleryRange: GalleryRangePosition) {
//        let leading = galleryRange.left.seconds/duration.seconds
//        let offsetX = CGFloat(leading)*galleryScrollView.contentSize.width
//        galleryScrollView.contentOffset = CGPoint(x: offsetX, y: 0)
//        fatalError()
    }
}


