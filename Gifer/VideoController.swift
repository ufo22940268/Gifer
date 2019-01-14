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
    case moving, finished
}
struct VideoTrimPosition {
    

    /// Propotional to video duration. Ranged from 0 to 1
    var leftTrim: CMTime
    
    /// Propotional to video duration. Ranged from 0 to 1
    var rightTrim: CMTime
    
    var range: CMTime {
        return rightTrim - leftTrim
    }
}

struct VideoControllerConstants {
    static var trimWidth = CGFloat(16)
    static var topAndBottomInset = CGFloat(2)
    static var sliderWidth = CGFloat(8)
    static let height = CGFloat(40)
    static let heightWithMargin = CGFloat(72)
}

protocol VideoControllerDelegate: VideoTrimDelegate, SlideVideoProgressDelegate {
}

class VideoController: UIView {
    
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
    
    var delegate: VideoControllerDelegate {
        get {
            return self.delegate
        }
        
        set {
            videoSlider.delegate = newValue
            videoTrim.trimDelegate = newValue
        }
    }
    
    var scrollView: UIScrollView!
    var generator: AVAssetImageGenerator?
    
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
        scrollView.alwaysBounceVertical = false

        
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
        self.videoTrim.duration = duration
        self.videoSlider.duration = duration
        
        let group = DispatchGroup()
        _ = DispatchQueue(label: "loader", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
        let thumbernailCount = calThumbernailCount(by: duration)
        
        group.enter()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.galleryView.prepareImageViews(thumbernailCount)
            group.leave()
        }
        
        var thumbernailTimes = [NSValue]()
        for i in 0..<thumbernailCount {
            if dismissed {
                return
            }
            
            let time = playerItem.asset.duration/thumbernailCount*i
            thumbernailTimes.append(NSValue(time: time))
            group.enter()
        }
        
        self.generator = AVAssetImageGenerator(asset: playerItem.asset)
        var index = 0
        self.generator?.generateCGImagesAsynchronously(forTimes: thumbernailTimes) { [weak self] (_, image, _, _, _) in
            guard let self = self else { return }
            
            guard image != nil else { return }
            
            var thumbernail: UIImage = UIImage(cgImage: image!)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                thumbernail = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50)).image(actions: { (context) in
                    thumbernail.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50)))
                })
                self.loadGallery(withImage: thumbernail, index: index)
                index = index + 1
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            self.videoTrim.onVideoLoaded()
            self.galleryView.bringSubviewToFront(self.videoSlider)
            
            //Not good implementation to change background color. Because the background is set by UIAppearance, so should find better way to overwrite it.
            self.videoTrim.backgroundColor = UIColor(white: 0, alpha: 0)
            print("finish load video \(Date())")
        }
    }
    
    func updateTrim(position: VideoTrimPosition, state: VideoTrimState) {
//        videoSlider.show(false)
    }

    func updateSliderProgress(_ progress: CMTime) {
        videoSlider.updateProgress(progress: progress)
        videoSlider.show(true)
    }
}

func / (time: CMTime, divider: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)/CGFloat(divider)), timescale: time.timescale)
}

func * (time: CMTime, factor: Int) -> CMTime {
    return CMTime(value: CMTimeValue(CGFloat(time.value)*CGFloat(factor)), timescale: time.timescale)
}
