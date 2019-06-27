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
        }
    }
    
    var interval: TimeInterval {
        let frameCount = playerItem.frames.count
        let duration = playerItem.duration
        return duration.seconds/Double(frameCount)
    }
    
    var timer: Timer!
    var paused = true
    
    override func awakeFromNib() {
        backgroundColor = .yellow
        addSubview(frameView)
        frameView.useSameSizeAsParent()
    }
    
    func load(playerItem: ImagePlayerItem) {
        self.playerItem = playerItem
        currentTime = playerItem.frames.first!.time
    }
    
    func play() {
        paused = false
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { (timer) in
            guard !self.paused else { return }
            self.step(by: 1)
        }
        
        timer.tolerance = 0
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
