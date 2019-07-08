//
//  StickerResourceCategory.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation

struct StickerResourceCategory {
    var name: String
    var indexURL: String
}

var AllStickerResourceCategories: [StickerResourceCategory] = {
    var categories = [StickerResourceCategory]()
    categories.append(StickerResourceCategory(name: "开心鸭", indexURL: "https://raw.githubusercontent.com/ufo22940268/ChineseBQB/master/008HappyDuck_开心鸭🐥BQB/index.md"))
    categories.append(StickerResourceCategory(name: "开心鸭", indexURL: "https://raw.githubusercontent.com/ufo22940268/ChineseBQB/master/008HappyDuck_开心鸭🐥BQB/index.md"))
    return categories
}()
