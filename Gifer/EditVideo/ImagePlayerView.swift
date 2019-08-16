//
//  ImagePlayerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

protocol ImagePlayerDelegate: class {
    
    func onProgressChanged(progress: CMTime)
    
    func onBuffering(_ inBuffering: Bool)
}



class ImagePlayerView: UIView {
    
    lazy var frameView: ImagePlayerFrameView = {
        let view = ImagePlayerFrameView().useAutoLayout()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    var imageView: UIImageView {
        return frameView.imageView
    }
    
    var playerItem: ImagePlayerItem!
    var currentTime: CMTime = .zero {
        didSet {
            let loadTime = currentTime
            let index = playerItem.nearestActiveIndex(time: loadTime)
            playerItem.getImageForPlay(index: index, direction: playDirection) {
                image in
                if self.currentTime == loadTime, let image = image {
                    let image = self.applyFilter(image)
                    self.frameView.image = image
                }
            }
            customDelegate?.onProgressChanged(progress: currentTime)
        }
    }
    
    var cropArea: CGRect? {
        set(newCropArea) {
            frameView.cropArea = newCropArea
        }
        
        get {
            return frameView.cropArea
        }
    }
    
    var interval: TimeInterval {
        let n = playerItem.frameInterval/Double(rate)
        return n
    }
    
    var timer: Timer!
    var isPaused = true
    var trimPosition: VideoTrimPosition!
    var playDirection: PlayDirection = .forward {
        didSet {
        }
    }
    var filter: YPFilter?
    var context: CIContext!
    
    var rate: Float = Config.defaultRate {
        didSet {
            timer.invalidate()

            timer = createTimer(with: interval)
        }
    }
    
    weak var customDelegate: ImagePlayerDelegate?
    
    override func awakeFromNib() {
        addSubview(frameView)
        frameView.useSameSizeAsParent()
        context = CIContext(options: nil)
    }
    
    func load(playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
        trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
        currentTime = playerItem.activeFrames.first!.time
        play()
    }
    
    func updatePlayerItem(_ playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
        trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
    }
    
    func applyFilter(_ image: UIImage) -> UIImage {
        guard let filter = filter  else { return image }
        var ciImage = CIImage(image: image)!
        ciImage = filter.applyFilter(image: ciImage)
        let image = UIImage(cgImage: context.createCGImage(ciImage, from: ciImage.extent)!)
        return image
    }
    
    private func play() {
        isPaused = false
        if timer != nil {
            fatalError("stop first")
        }
        
        timer = createTimer(with: interval)
    }
    
    private func createTimer(with interval: TimeInterval) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            guard !self.isPaused else { return }
            
            switch self.playDirection {
            case .forward:
                if self.canStep(by: 1) {
                    self.step(by: 1)
                } else {
                    self.currentTime = self.trimPosition.leftTrim
                }
            case .backward:
                if self.canStep(by: -1) {
                    self.step(by: -1)
                } else {
                    self.currentTime = self.trimPosition.rightTrim
                }
            }
        }
        
        timer.tolerance = interval*0.1
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }
    
    func useBlankImage() {
        self.imageView.image = nil
    }
    
    func destroy() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    private func canStep(by delta: Int) -> Bool {
        let index = playerItem.nearestActiveIndex(time: currentTime)
        let minIndex = playerItem.nearestActiveIndex(time: trimPosition.leftTrim)
        let maxIndex = playerItem.nearestActiveIndex(time: trimPosition.rightTrim)
        return index + delta >= minIndex && index + delta <= maxIndex
    }
    
    func step(by delta: Int) {
        guard let playerItem = playerItem else { fatalError() }
        let index = playerItem.nearestActiveIndex(time: currentTime)
        let frames = playerItem.activeFrames
        let frame = frames[(index + delta)%frames.count]
        currentTime = frame.time
    }
    
    func seek(to progress: CMTime) {
        currentTime = playerItem.nearestActiveFrame(time: progress).time
    }
}
