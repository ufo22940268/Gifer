//
//  ImagePlayerItem.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import AVKit
import UIKit
import  Photos

protocol ItemGenerator {
    func run(complete: @escaping (ImagePlayerItem) -> Void)
    func destroy()
}
