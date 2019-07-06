//
//  VideoLibrary.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/24.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import AVKit
import Photos

class VideoLibrary {

    private static var instance: VideoLibrary = {
        return VideoLibrary()
    }()

    class func shared() -> VideoLibrary {        
        return instance
    }
    
    func getVideos() -> PHFetchResult<PHAsset> {        
        return PHAsset.fetchAssets(with: .video, options: nil)
    }
    
    func getLivePhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        return PHAsset.fetchAssets(with: .image, options: options)
    }
}
