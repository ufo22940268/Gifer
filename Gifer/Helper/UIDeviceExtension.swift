//
//  DeviceExtension.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

extension UIDevice {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// 在有 Taptic Engine 的设备上触发一个轻微的振动
    ///
    /// - Parameter params: level  (number)  0 ~ 3 表示振动等级
    func taptic(level: Int = 0, isSupportTaptic: Bool = true) {
        if #available(iOS 10.0, *),
            isSupportTaptic,
            let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: level) {
            let tapticEngine = UIImpactFeedbackGenerator(style: style)
            tapticEngine.prepare()
            tapticEngine.impactOccurred()
        } else {
            switch level {
            case 3:
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            case 2:
                // 连续三次短震
                AudioServicesPlaySystemSound(1521)
            case 1:
                // 普通短震，3D Touch 中 Pop 震动反馈
                AudioServicesPlaySystemSound(1520)
            default:
                // 普通短震，3D Touch 中 Peek 震动反馈
                AudioServicesPlaySystemSound(1519)
            }
        }
    }
}

