//
//  Font.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/28.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    static func listAllFonts() -> [UIFont] {
        let allFontNames = UIFont.familyNames.map {UIFont.fontNames(forFamilyName: $0)}.flatMap {$0}
        return allFontNames.map {UIFont(name: $0, size: UIFont.systemFontSize)!}
    }
}
