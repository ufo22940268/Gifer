//
//  ItemGeneratorWithPhotoFiles.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/6.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class ItemGeneratorWithPhotoFiles: ItemGenerator {
    
    var photos: [URL]
    
    init(photos: [URL]) {
        self.photos = photos
    }
    
    func run(complete: @escaping (ImagePlayerItem) -> Void) {
        let frames = photos.enumerated()
            .map { (offset, url) in ImagePlayerFrame(time: (FPSFigure.default.interval*Double(offset)).toTime(), url: url) }
        complete(ImagePlayerItem(frames: frames, duration: frames.last!.time))
    }
    
    func destroy() {
        
    }
}
