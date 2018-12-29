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
    func onTrimChanged(position: VideoTrimPosition)
}

struct VideoTrimPosition {
    
    /// Propotional to video duration. Ranged from 0 to 1
    var leftTrim: CMTime
    
    /// Propotional to video duration. Ranged from 0 to 1
    var rightTrim: CMTime    
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(16)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(8)
    static let height = CGFloat(40)
    static let heightWithMargin = CGFloat(72)
}

class VideoController: UIView {
    
    var galleryView: VideoControllerGallery!
    var videoSlider: VideoControllerSlider!
    var videoTrim: VideoControllerTrim!
    
    var slideDelegate: SlideVideoProgressDelegate? {
        get {
            return videoSlider.delegate
        }
        set {
            videoSlider.delegate = newValue
        }
    }
    
    var scrollView: UIScrollView!
    
    override func awakeFromNib() {
        backgroundColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)

        setupScrollView()

        galleryView = VideoControllerGallery()
        scrollView.addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        addSubview(videoTrim)
        videoTrim.setup()
        
        videoSlider = VideoControllerSlider()
        addSubview(videoSlider)
        videoSlider.setup(trimView: videoTrim)
    }
    
    func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.layoutMargins.top = 0
        scrollView.layoutMargins.bottom = 0
        scrollView.layoutMargins.left = 0
        scrollView.layoutMargins.right = 0
        
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalTo: heightAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor)])
    }
    
    fileprivate func loadGallery(withImage image: UIImage, index: Int) -> Void {
        galleryView.setImage(image, on: index)
    }
    
    
    /// Every 20s video should have 8 thumbernails
    ///
    /// - Parameter duration: video duration
    /// - Returns: thumbernail count
    private func calThumbernailCount(by duration: CMTime) -> Int {
        return max(Int(duration.seconds/20.0 * Double(videoControllerGalleryImageCountPerGroup)), videoControllerGalleryImageCountPerGroup)
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        guard playerItem.asset.duration.value > 0 else {
            return
        }
        
        let duration = playerItem.asset.duration
        videoTrim.duration = duration
        videoSlider.duration = duration
        
        let group = DispatchGroup()
        let thumbernailCount = calThumbernailCount(by: duration)
        galleryView.prepareImageViews(thumbernailCount)
        for i in 0..<thumbernailCount {
            let time = playerItem.asset.duration/thumbernailCount*i
            group.enter()
            DispatchQueue.global().async {
                let thumbernail = playerItem.asset.extractThumbernail(on: time)
                DispatchQueue.main.async {
                    self.loadGallery(withImage: thumbernail, index: i)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.galleryView.bringSubviewToFront(self.videoSlider)
            
            //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
            self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        }
    }
    
    func updateSliderProgress(_ progress: CMTime) {
        videoSlider.updateProgress(progress: progress)
        videoSlider.show(true)
    }
    
    func updateTrim(position: VideoTrimPosition) {
        videoSlider.show(false)
    }    
}

func / (time: CMTime, divider: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)/CGFloat(divider)), timescale: time.timescale)
}

func * (time: CMTime, factor: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)*CGFloat(factor)), timescale: time.timescale)
}
