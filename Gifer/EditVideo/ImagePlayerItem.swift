//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

struct ImagePlayerFrame: Equatable {
    var time: CMTime
    var path: URL?
    var key: NSNumber {
        return NSNumber(value: time.seconds)
    }
    var isActive = true
    
    var uiImage: UIImage! {
        if let data = try? Data(contentsOf: path!) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    init(time: CMTime) {
        self.time = time
    }
}

func == (_ l: ImagePlayerFrame, _ r: ImagePlayerFrame) -> Bool {
    return l.path == r.path
}

class ImagePlayerItem {
    var activeFrames: [ImagePlayerFrame] {
        return allFrames.filter { $0.isActive }
    }
    
    var allFrames: [ImagePlayerFrame]
    var duration: CMTime
    lazy var playCache: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 10
        return cache
    }()
    
    lazy var commonCache: NSCache<NSNumber, UIImage> = {
        let cache = NSCache<NSNumber, UIImage>()
        cache.countLimit = 50
        return cache
    }()

    var tasks: [RequestId: DispatchWorkItem] = [RequestId: DispatchWorkItem]()
    
    typealias RequestId = Int
    
    //Frame interval in seconds
    var frameInterval: Double {
        return (allFrames[1].time - allFrames[0].time).seconds
    }
    
    var queue = DispatchQueue(label: "cache")
    
    /// Size of frame
    var size: CGSize
    
    init(frames: [ImagePlayerFrame], duration: CMTime, size: CGSize) {
        self.allFrames = frames
        self.size = size
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
    
    func getImageForPlay(index: Int, direction: PlayDirection, complete: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            var uiImage: UIImage! = nil
            if let image = self.playCache.object(forKey: self.activeFrames[index].key) {
                uiImage = image
            } else {
                if let image = self.activeFrames[index].uiImage {
                    self.playCache.setObject(image, forKey: self.activeFrames[index].key)
                    uiImage = image
                }
            }
            
            DispatchQueue.main.async {
                complete(uiImage)
            }
        }
        
        cacheImage(index: index, with: direction)
    }
    
    private func cacheImage(index: Int, with direction: PlayDirection) {
        queue.async {
            for i in 0..<9 {
                let cacheIndex = self.shiftIndex(index, by: direction == .forward ?  i : -i)
                let frame = self.activeFrames[cacheIndex]
                let cachedImage = self.playCache.object(forKey: frame.key)
                if cachedImage == nil, let image = frame.uiImage {
                    self.playCache.setObject(image, forKey: frame.key)
                }
            }
        }
    }
    
    func requestThumbernail(index: Int, size: CGSize, complete: @escaping (UIImage) -> Void) {
        let frame = allFrames[index]
        requestImage(frame: frame) { image in
            complete(image.resize(inSize: size))
        }
    }
    
    @discardableResult
    func requestImage(frame: ImagePlayerFrame, size: CGSize? = nil, complete: @escaping (UIImage) -> Void) -> RequestId {
        let id = allFrames.firstIndex(of: frame)!
        let workItem = DispatchWorkItem {
            if let image = self.commonCache.object(forKey: NSNumber(value: id)) {
                print("hit")
                DispatchQueue.main.async {                    
                    complete(image)
                }
                return
            }
            
            var image = frame.uiImage!
            if let size = size {
                image = image.resize(inSize: size)
            }
            self.commonCache.setObject(image, forKey: NSNumber(value: id))
            DispatchQueue.main.async {
                complete(image)
            }
        }
        self.tasks[id] = workItem
        workItem.notify(queue: .main) {
            self.tasks.removeValue(forKey: id)
        }
        DispatchQueue.global().async(execute: workItem)
        return id
    }
    
    func cancel(taskId: RequestId) {
        tasks[taskId]?.cancel()
        tasks.removeValue(forKey: taskId)
    }
    
    func getActiveFramesBetween(begin: CMTime, end: CMTime) -> [ImagePlayerFrame] {
        let beginIndex = nearestActiveIndex(time: begin)
        let endIndex = nearestActiveIndex(time: end)
        return Array(activeFrames[beginIndex...endIndex])
    }
    
    /// Calibrate trim position using the player item. There will be minor gap between trimPosition and playeritem.
    func calibarateTrimPositionDuration(_ trimPosition: VideoTrimPosition) -> CMTime {
        let fromIndex = self.nearestActiveIndex(time: trimPosition.leftTrim)
        let toIndex = self.nearestActiveIndex(time: trimPosition.rightTrim)
        return CMTime(seconds: self.frameInterval*Double(toIndex - fromIndex), preferredTimescale: 600)
    }
}
