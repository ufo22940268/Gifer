//
//  EditTextInfo.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/4/1.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

struct EditTextInfo {
    var text: String
    var fontName: String
    var textColor: UIColor
    
    static let preferredTextSize = CGFloat(30)
    
    static var initial: EditTextInfo {
        return EditTextInfo(text: "", fontName: UIFont.systemFont(ofSize: 12).fontName, textColor: .white)
    }
}
