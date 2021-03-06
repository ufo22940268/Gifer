//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import Photos

class ImagePlayerItem {
    var activeFrames: [ImagePlayerFrame] {
        return allFrames.filter { $0.isActive }
    }
    
    var allFrames: [ImagePlayerFrame] {
        didSet {
            updateFrameInterval()
        }
    }
    
    var rootFrames: [ImagePlayerFrame]!
    
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
    
    var frameInterval: Double!
    
    var queue = DispatchQueue(label: "cache")
    var labelSequence: Int = 0
    var labels = [ImagePlayerItemLabel]()
    
    init(frames: [ImagePlayerFrame], duration: CMTime, videoAsset: PHAsset? = nil) {
        self.allFrames = frames
        self.rootFrames = frames
        self.duration = duration
        updateFrameInterval()
        
        let newLabel: ImagePlayerItemLabel = createLabel(first: frames.first!)
        labels.append(newLabel)
        frames.forEach { $0.label = newLabel }
        
        if let videoAsset = videoAsset {
            labels.last!.videoAsset = videoAsset
        }
    }    
    
    func createLabel(first frame: ImagePlayerFrame) -> ImagePlayerItemLabel {
        let label = ImagePlayerItemLabel(previewLoader: frame.previewLoader, sequence: labelSequence)
        labelSequence += 1
        return label
    }
    
    func updateFrameInterval() {
        frameInterval = duration.seconds/Double(activeFrames.count)
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
        let id = rootFrames.firstIndex(of: frame)!
        let workItem = DispatchWorkItem {
            if let image = self.commonCache.object(forKey: NSNumber(value: id)) {
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
    
    func resetAllFrameTimes() {
        let interval = duration.seconds/Double(allFrames.count)
        for (index, _) in allFrames.enumerated() {
            allFrames[index].time = (Double(index)*interval).toTime()
        }
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
    
    /// Mark the frame which is not in trim postition range as inactive.
    func update(byTrimPosition trimPosition: VideoTrimPosition) {
        let left = nearestIndex(time: trimPosition.leftTrim)
        let right = nearestIndex(time: trimPosition.rightTrim)
        for i in 0..<allFrames.count where i < left || i > right {
            allFrames[i].isActive = false
        }        
    }
    
    func deleteLabel(_ label: ImagePlayerItemLabel) {
        labels.removeAll { $0 === label }
        allFrames.removeAll { $0.label === label }
        rootFrames.removeAll { $0.label === label }
    }
    
    var allRangeTrimPosition: VideoTrimPosition {
        if allFrames.count < 2 {
            return .zero
        }
        return VideoTrimPosition(leftTrim: allFrames.first!.time, rightTrim: allFrames.last!.time)
    }
    
    func concat(_ playerItem: ImagePlayerItem) {
        allFrames.append(contentsOf: playerItem.allFrames)
        rootFrames.append(contentsOf: playerItem.rootFrames)
        let newLabel: ImagePlayerItemLabel = createLabel(first: playerItem.allFrames.first!)
        labels.append(newLabel)
        playerItem.allFrames.forEach { $0.label = newLabel }
    }
    
    private func replace(frames: inout [ImagePlayerFrame], with newFrames: [ImagePlayerFrame], on label: ImagePlayerItemLabel) {
        let all = frames.enumerated().filter { $0.element.label === label }.map { $0.offset }.sorted(by: < )
        frames.replaceSubrange(all.first!...all.last!, with: newFrames.map {
            $0.label = label
            return $0
        })
    }
    
    func replace(with playerItem: ImagePlayerItem, on label: ImagePlayerItemLabel) {
        replace(frames: &allFrames, with: playerItem.allFrames, on: label)
        replace(frames: &rootFrames, with: playerItem.rootFrames, on: label)
    }
}

extension Array where Element == ImagePlayerFrame {
    func nearestIndex(time: CMTime) -> Int {
        return (self.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
    }
}

class ImagePlayerItemLabel {
    typealias PreviewLoader = () -> UIImage
    var previewLoader: PreviewLoader
    var sequence: Int
    var videoAsset: PHAsset?
    
    var color: UIColor {
        var colors = [UIColor.yellowActiveColor]
        colors.append(contentsOf: [Palette.LightGreen, Palette.Blue])
        return colors[sequence%colors.count]
    }
    
    internal init(previewLoader: @escaping ImagePlayerItemLabel.PreviewLoader, sequence: Int) {
        self.previewLoader = previewLoader
        self.sequence = sequence
    }
}
