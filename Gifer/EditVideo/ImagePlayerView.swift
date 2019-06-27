//
//  ImagePlayerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class ImagePlayerView: UIView {
    
    lazy var frameView: ImagePlayerFrameView = {
        let view = ImagePlayerFrameView().useAutoLayout()
        return view
    }()
    
    var playerItem: ImagePlayerItem!
    var currentTime: CMTime = .zero {
        didSet {
            let index = playerItem.nearestIndex(time: currentTime)
            frameView.image = playerItem.frames[index].uiImage
            customDelegate?.onProgressChanged(progress: currentTime)
        }
    }
    
    var interval: TimeInterval {
        let frameCount = playerItem.frames.count
        let duration = playerItem.duration
        return duration.seconds/Double(frameCount)
    }
    
    var timer: Timer!
    var paused = true
    var trimPosition: VideoTrimPosition!
    var playDirection: PlayDirection = .forward {
        didSet {
        }
    }
    
    weak var customDelegate: ImagePlayerDelegate?
    
    override func awakeFromNib() {
        backgroundColor = .yellow
        addSubview(frameView)
        frameView.useSameSizeAsParent()
    }
    
    func load(playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
        trimPosition = VideoTrimPosition(leftTrim: .zero, rightTrim: playerItem.duration)
        currentTime = playerItem.frames.first!.time
    }
    
    func play() {
        paused = false
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            guard !self.paused else { return }
            
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
        
        timer.tolerance = 0
    }
    
    func destroy() {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
    
    private func canStep(by delta: Int) -> Bool {
        let index = playerItem.nearestIndex(time: currentTime)
        let minIndex = playerItem.nearestIndex(time: trimPosition.leftTrim)
        let maxIndex = playerItem.nearestIndex(time: trimPosition.rightTrim)
        return index + delta >= minIndex && index + delta <= maxIndex
    }
    
    func step(by delta: Int) {
        guard let playerItem = playerItem else { fatalError() }
        let index = playerItem.nearestIndex(time: currentTime)
        let frames = playerItem.frames
        let frame = frames[(index + delta)%frames.count]
        currentTime = frame.time
    }
    
    func seek(to progress: CMTime) {
        currentTime = playerItem.nearestFrame(time: progress).time
    }
}
