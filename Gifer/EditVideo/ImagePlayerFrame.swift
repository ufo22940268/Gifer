//
//  ImagePlayerFrame.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit
import Photos

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

class ImagePlayerFrame: Equatable {
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
    
    convenience init(time: CMTime, image: UIImage) {
        self.init(time: time)
        saveToDirectory(uiImage: image)
        self.isActive = true
    }
    
    var previewLoader: ImagePlayerItemLabel.PreviewLoader {
        return { () in
            return self.uiImage
        }
    }
    
    static var directory: URL = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
    
    func saveToDirectory(cgImage: CGImage) {
        let directory = ImagePlayerFrame.directory
        let filePath = directory.appendingPathComponent("\(randomString(length: 10))-\(self.time.seconds.description)")
        do {
            try UIImage(cgImage: cgImage).jpegData(compressionQuality: 1)?.write(to: filePath)
            self.path = filePath
        } catch {
            print("error: \(error)")
        }
    }
    
    func saveToDirectory(uiImage: UIImage) {
        let directory = ImagePlayerFrame.directory
        let filePath = directory.appendingPathComponent(self.time.seconds.description)
        do {
            try uiImage.jpegData(compressionQuality: 1)?.write(to: filePath)
            self.path = filePath
        } catch {
            print("error: \(error)")
        }
    }
    
    static func initDirectory() {
        let directory = ImagePlayerFrame.directory
//        try? FileManager.default.removeItem(at: directory)
        if !FileManager.default.fileExists(atPath: directory.absoluteString) {            
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    
    static func == (_ lhs: ImagePlayerFrame, _ rhs: ImagePlayerFrame) -> Bool {
        return lhs.path == rhs.path
    }
}
