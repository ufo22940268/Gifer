//
//  UIKItLocalizedString.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/13.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation

@available(*, deprecated)
class UIKitLocalizedString {
    static let bundle = Bundle(identifier: "com.apple.UIKit")
    class var ok: String {
        return localizedStringForKey("Ok")
    }
    class var search: String {
        return localizedStringForKey("Search")
    }
    class var cancel: String {
        return localizedStringForKey("Cancel")
    }
    class var done: String {
        return localizedStringForKey("Done")
    }
    static func localizedStringForKey(_ key: String) -> String {
        return NSLocalizedString("Cancel", comment: "")
    }
}
