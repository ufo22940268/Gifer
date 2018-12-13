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
    static var trimWidth = CGFloat(10)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(10)
}

class VideoController: UIView {
    
    var galleryView: VideoGallery!
    var progressSlider: VideoProgressSlider!
    var videoTrim: VideoTrim!
    
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

        galleryView = VideoGallery(frame: CGRect.zero)
        addSubview(galleryView)
        galleryView.setup()
        
        videoTrim = VideoTrim()
        addSubview(videoTrim)
        videoTrim.setup()
        
        progressSlider = VideoProgressSlider()
        galleryView.addSubview(progressSlider)
        progressSlider.setup(trimView: videoTrim)
    }
    
    fileprivate func loadGallery(withImages images: [UIImage]) -> Void {
        for image in images {
            galleryView.addImage(image, totalCount: images.count)
        }
        
        galleryView.bringSubviewToFront(progressSlider)
        galleryView.bringSubviewToFront(galleryView.leftFader)
        galleryView.bringSubviewToFront(galleryView.rightFader)

        //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
        videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        DispatchQueue.global().async {
            let thumbernails = playerItem.asset.extractThumbernails()
            DispatchQueue.main.async {
                self.loadGallery(withImages: thumbernails)
            }
        }
    }
    
    func updateSliderProgress(_ progress: CGFloat) {
        print(progress)
        progressSlider.updateProgress(progress: progress)
        progressSlider.show(true)
    }
    
    func updateTrim(position: VideoTrimPosition) {
        galleryView.updateByTrim(trimPosition: position)
        progressSlider.show(false)
    }
}
