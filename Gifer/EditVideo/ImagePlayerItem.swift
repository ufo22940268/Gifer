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

struct ImagePlayerFrame: Equatable {
    var time: CMTime
    var path: URL?
    var key: NSNumber {
        return NSNumber(value: time.seconds)
    }
    var isActive = true
    
    var uiImage: UIImage! {
        if let path = path, let data = try? Data(contentsOf: path) {
            return UIImage(data: data)
        } else {
            return nil
        }
    }
    
    init(time: CMTime) {
        self.time = time
    }
    
    init(time: CMTime, image: UIImage) {
        self.init(time: time)
        ImagePlayerFrame.saveToDirectory(uiImage: image, frame: &self)
        self.isActive = true
    }
    
    static var directory: URL = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
    
    static func saveToDirectory(cgImage: CGImage, frame: inout ImagePlayerFrame) {
        let directory = ImagePlayerFrame.directory
        let filePath = directory.appendingPathComponent(frame.time.seconds.description)
        do {
            try UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)?.write(to: filePath)
            frame.path = filePath
        } catch {
            print("error: \(error)")
        }
    }
    
    static func saveToDirectory(uiImage: UIImage, frame: inout ImagePlayerFrame) {
        let directory = ImagePlayerFrame.directory
        let filePath = directory.appendingPathComponent(frame.time.seconds.description)
        do {
            try uiImage.jpegData(compressionQuality: 1)?.write(to: filePath)
            frame.path = filePath
        } catch {
            print("error: \(error)")
        }
    }

    static func initDirectory() {
        let directory = ImagePlayerFrame.directory
        try? FileManager.default.removeItem(at: directory)
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    

    static func == (_ lhs: ImagePlayerFrame, _ rhs: ImagePlayerFrame) -> Bool {
        return lhs.path == rhs.path
    }
}

class ImagePlayerItem {
    var activeFrames: [ImagePlayerFrame] {
        return allFrames.filter { $0.isActive }
    }
    
    var allFrames: [ImagePlayerFrame] {
        didSet {
            updateFrameInterval()
        }
    }
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
    
    init(frames: [ImagePlayerFrame], duration: CMTime) {
        self.allFrames = frames
        self.duration = duration
        updateFrameInterval()
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
        let id = allFrames.firstIndex(of: frame)!
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
    
    var allRangeTrimPosition: VideoTrimPosition {
        if allFrames.count < 2 {
            return .zero
        }
        return VideoTrimPosition(leftTrim: allFrames.first!.time, rightTrim: allFrames.last!.time)
    }
}

extension Array where Element == ImagePlayerFrame {
    func nearestIndex(time: CMTime) -> Int {
        return (self.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
    }
    
//    func nearestActiveIndex(time: CMTime) -> Int {
//        return (self.filter { $0.isActive }.enumerated().min(by: { abs(($0.1.time - time).seconds) < abs(($1.1.time - time).seconds) }))!.0
//    }
}

class MakePlayerItemFromPhotosTask {
    
    var identifiers: [String]?
    var requestIds: [Int32] = [Int32]()
    
    init(identifiers: [String]) {
        self.identifiers = identifiers
    }
    
    func run(complete: @escaping (ImagePlayerItem?) -> Void) {
        guard let identifiers = identifiers else {
            complete(nil)
            return
        }
        
        var images = Array<UIImage?>(repeating: nil, count: identifiers.count)
        let group = DispatchGroup()
        identifiers.forEach { _ in group.enter() }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let targetSize = AVMakeRect(aspectRatio: CGSize(width: assets.firstObject!.pixelWidth, height: assets.firstObject!.pixelHeight), insideRect: CGRect(origin: .zero, size: CGSize(width: 600, height: 600))).size
        assets.enumerateObjects { (asset, index, _) in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            let id = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image, _) in
                images[index] = image
                group.leave()
            })
            self.requestIds.append(id)
        }
        
        group.notify(queue: .main) {
            ImagePlayerFrame.initDirectory()
            var frames = [ImagePlayerFrame]()
            guard (images.allSatisfy { $0 != nil }) else {
                complete(nil)
                return
            }
            for (index, image) in images.enumerated() {
                let time = CMTimeMultiply(Double(1).toTime(), multiplier: Int32(index))
                let frame = ImagePlayerFrame(time: time, image: image!)
                frames.append(frame)
            }
            let playerItem = ImagePlayerItem(frames: frames, duration: CMTimeMultiply(Double(1).toTime(), multiplier: Int32(frames.count)))
            complete(playerItem)
        }
    }
    
    func release() {
        requestIds.forEach { PHImageManager.default().cancelImageRequest($0) }
    }
}
