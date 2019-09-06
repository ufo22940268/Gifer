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
    weak var label: ImagePlayerItemLabel?
    
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
    
    init(time: CMTime, url: URL) {
        self.path = url
        self.time = time
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
        if !FileManager.default.fileExists(atPath: directory.absoluteString) {
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileCountLimit = 1000
        if let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey]), files.count > fileCountLimit {
            let filesToDelete = files.sorted(by: { (u1, u2) in
                if let date1 = try? u1.resourceValues(forKeys: [.creationDateKey]).creationDate, let date2 = try? u2.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    return date1 < date2
                } else {
                    return false
                }
            })[0..<(files.count - fileCountLimit)]
            
            filesToDelete.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }
    
    
    static func == (_ lhs: ImagePlayerFrame, _ rhs: ImagePlayerFrame) -> Bool {
        return lhs.path == rhs.path
    }
}
