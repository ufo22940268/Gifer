//
//  StickerFile.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

class StickerFileModel: Object {
    @objc dynamic var image: Data?
    @objc dynamic var createdDate = Date()
    
    var uiImage: UIImage? {
        return image != nil ? UIImage(data: image!) : nil
    }
}
