//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

struct ImagePlayerFrame {
    var time: CMTime
    var path: URL?
    var key: NSNumber {
        return NSNumber(value: time.seconds)
    }
    var isActive = true
    
    var uiImage: UIImage {
        let data = try! Data(contentsOf: path!)
        return UIImage(data: data)!
    }
    
    init(time: CMTime) {
        self.time = time
    }
}

class ImagePlayerItem {
    var activeFrames: [ImagePlayerFrame] {
        return allFrames.filter { $0.isActive }
    }
    var allFrames: [ImagePlayerFrame]
    var duration: CMTime
    lazy var imageCache: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 10
        return cache
    }()
    
    //Frame interval in seconds
    var frameInterval: Double {
        return (allFrames[1].time - allFrames[0].time).seconds
    }
    
    var queue = DispatchQueue(label: "cache")
    
    init(frames: [ImagePlayerFrame], duration: CMTime) {
        self.allFrames = frames
        self.duration = duration
    }
    
    func getActiveSequence(of frame: ImagePlayerFrame) -> Int? {
        var index = 0
        for af in activeFrames {
            if af.path != frame.path {
                index += 1
            } else {
                return index + 1
            }
        }
        
        return nil
    }
    
    func nearestIndex(time: CMTime) -> Int {
        return nearestIndex(time: time, on: allFrames)
    }
    
    func nearestActiveIndex(time: CMTime) -> Int {
        return nearestIndex(time: time, on: self.activeFrames)
    }
    
    func nearestActiveFrame(time: CMTime) -> ImagePlayerFrame {
        return activeFrames[nearestActiveIndex(time: time)]
    }
    
    private func nearestIndex(time: CMTime, on frames: [ImagePlayerFrame]) -> Int {
        return (frames.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
    }
    
    private func shiftIndex(_ index: Int, by delta: Int) -> Int {
        let newIndex = index + delta
        if newIndex < activeFrames.count && newIndex >= 0 {
            return newIndex
        } else if newIndex < 0 {
            return shiftIndex(activeFrames.count - abs(newIndex), by: 0)
        } else {
            return shiftIndex(newIndex - activeFrames.count, by: 0)
        }
    }
    
    func getImageForPlay(index: Int, direction: PlayDirection) -> UIImage {
        var uiImage: UIImage
        if let image = imageCache.object(forKey: activeFrames[index].key) {
            uiImage = image
        } else {
            let image = activeFrames[index].uiImage
            imageCache.setObject(image, forKey: activeFrames[index].key)
            uiImage = image
        }
        
        cacheImage(index: index, with: direction)
        return uiImage
    }
    
    private func cacheImage(index: Int, with direction: PlayDirection) {
        queue.async {
            for i in 0..<9 {
                let cacheIndex = self.shiftIndex(index, by: direction == .forward ?  i : -i)
                let frame = self.activeFrames[cacheIndex]
                let cachedImage = self.imageCache.object(forKey: frame.key)
                if cachedImage == nil {
                    self.imageCache.setObject(frame.uiImage, forKey: frame.key)
                }
            }
        }
    }
    
    func getActiveFramesBetween(begin: CMTime, end: CMTime) -> [ImagePlayerFrame] {
        let beginIndex = nearestActiveIndex(time: begin)
        let endIndex = nearestActiveIndex(time: end)
        return Array(activeFrames[beginIndex...endIndex])
    }
}
