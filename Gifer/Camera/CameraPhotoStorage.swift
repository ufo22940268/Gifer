//
//  CameraPhotoCache.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/5.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CameraPhotoStorage {
    static let instance = CameraPhotoStorage()
    
    var directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("capturePhotos", isDirectory: true)
    
    func save(_ data: Data?) -> URL? {
        let filename = randomString(length: 10) + ".jpg"
        if let directory = directory {
            if !FileManager.default.fileExists(atPath: directory.absoluteString) {
                try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let filePath: URL = directory.appendingPathComponent(filename)
            guard let _ = try? data?.write(to: filePath)  else { return nil }
            return filePath
        }
        
        return nil
    }
    
    func clear() {
        guard let directory = directory else { return }
        FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)?.forEach({ (url) in
            try? FileManager.default.removeItem(at: url as! URL)
        })
    }
}
