//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit
import Photos

protocol ItemGenerator: class {
    var progressDelegate: GenerateProgressDelegate? {
        get set
    }
    func run(complete: @escaping (ImagePlayerItem) -> Void)
    func destroy()
}

protocol GenerateProgressDelegate: class {
    func onProgress(_ progress: CGFloat)
}

extension GenerateProgressDelegate {
    func onComplete() {
        onProgress(1)
    }
}
