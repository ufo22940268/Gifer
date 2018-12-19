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


protocol VideoProgressDelegate: class {
    func onProgressChanged(progress: CGFloat)
}

enum SlideState {
    case begin, slide, end
}

protocol SlideVideoProgressDelegate: class {
    func onSlideVideo(state: SlideState, progress: CGFloat!)
}

protocol VideoTrimDelegate: class {
    func onTrimChanged(position: VideoTrimPosition)
}

struct VideoTrimPosition {
    
    /// Propotional to video duration. Ranged from 0 to 1
    var leftTrim: CGFloat
    
    /// Propotional to video duration. Ranged from 0 to 1
    var rightTrim: CGFloat
    
    static var initialState: VideoTrimPosition {
        return VideoTrimPosition(leftTrim: 0, rightTrim: 1)
    }
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
    var progressSlider: VideoControllerSlider!
    var videoTrim: VideoControllerTrim!
    static let galleryThumbernailCount = 15
    
    var slideDelegate: SlideVideoProgressDelegate? {
        get {
            return progressSlider.delegate
        }
        set {
            progressSlider.delegate = newValue
        }
    }
    
    override func awakeFromNib() {
        backgroundColor = #colorLiteral(red: 0.262745098, green: 0.262745098, blue: 0.262745098, alpha: 1)

        layoutMargins.top = 0
        layoutMargins.bottom = 0
        layoutMargins.left = 0
        layoutMargins.right = 0

        galleryView = VideoControllerGallery(totalImageCount: VideoController.galleryThumbernailCount)
        addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoControllerTrim()
        addSubview(videoTrim)
        videoTrim.setup()
        
        progressSlider = VideoControllerSlider()
        addSubview(progressSlider)
        progressSlider.setup(trimView: videoTrim)
    }
    
    fileprivate func loadGallery(withImage image: UIImage, index: Int) -> Void {
        galleryView.setImage(image, on: index)
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        guard playerItem.asset.duration.value > 0 else {
            return
        }
        
        let group = DispatchGroup()
        for i in 0..<VideoController.galleryThumbernailCount {
            let time = playerItem.asset.duration/VideoController.galleryThumbernailCount*i
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
            self.galleryView.bringSubviewToFront(self.progressSlider)
            
            //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
            self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
        }
    }
    
    func updateSliderProgress(_ progress: CGFloat) {
        progressSlider.updateProgress(progress: progress)
        progressSlider.show(true)
    }
    
    func updateTrim(position: VideoTrimPosition) {
        galleryView.updateByTrim(trimPosition: position)
        progressSlider.show(false)
    }
}

func / (time: CMTime, divider: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)/CGFloat(divider)), timescale: time.timescale)
}

func * (time: CMTime, factor: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)*CGFloat(factor)), timescale: time.timescale)
}
