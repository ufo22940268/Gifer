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
    
    var uiImage: UIImage {
        let data = try! Data(contentsOf: path!)
        return UIImage(data: data)!
    }
    
    init(time: CMTime) {
        self.time = time
    }
}

class ImagePlayerItem {
    var frames: [ImagePlayerFrame]
    var duration: CMTime
    lazy var imageCache: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 10
        return cache
    }()
    
    var queue = DispatchQueue(label: "cache")
    
    init(frames: [ImagePlayerFrame], duration: CMTime) {
        self.frames = frames
        self.duration = duration
    }
    
    func nearestIndex(time: CMTime) -> Int {
        return (self.frames.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
    }
    
    func nearestFrame(time: CMTime) -> ImagePlayerFrame {
        return frames[nearestIndex(time: time)]
    }
    
    private func shiftIndex(_ index: Int, by delta: Int) -> Int {
        let newIndex = index + delta
        if newIndex < frames.count && newIndex >= 0 {
            return newIndex
        } else if newIndex < 0 {
            return shiftIndex(frames.count - abs(newIndex), by: 0)
        } else {
            return shiftIndex(newIndex - frames.count, by: 0)
        }
    }
    
    func getImageForPlay(index: Int, direction: PlayDirection) -> UIImage {
        var uiImage: UIImage
        if let image = imageCache.object(forKey: frames[index].key) {
            uiImage = image
        } else {
            let image = frames[index].uiImage
            imageCache.setObject(image, forKey: frames[index].key)
            uiImage = image
        }
        
        cacheImage(index: index, with: direction)
        return uiImage
    }
    
    private func cacheImage(index: Int, with direction: PlayDirection) {
        queue.async {
            for i in 0..<9 {
                let cacheIndex = self.shiftIndex(index, by: direction == .forward ?  i : -i)
                let frame = self.frames[cacheIndex]
                let cachedImage = self.imageCache.object(forKey: frame.key)
                if cachedImage == nil {
                    self.imageCache.setObject(frame.uiImage, forKey: frame.key)
                }
            }
        }
    }
}
