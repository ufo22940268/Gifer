//
//  PromotionManager.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import StoreKit

class PromotionManager {
    
    static var `default` = PromotionManager()
    
    func increaseShareTimes() {
        let times = UserDefaults.standard.integer(forKey: UserDefaultKeys.shareTimes.rawValue)
        UserDefaults.standard.set(times + 1, forKey: UserDefaultKeys.shareTimes.rawValue)
    }
    
    func shouldShowDialog() -> Bool {
        return UserDefaults.standard.integer(forKey: UserDefaultKeys.shareTimes.rawValue) == 3
    }
    
    func showDialog() {
        SKStoreReviewController.requestReview()
    }
}
