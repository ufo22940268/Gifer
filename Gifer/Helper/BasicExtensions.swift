//
//  BasicExtensions.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox
import AVKit

extension UIView {
    
    @discardableResult
    func useAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    @discardableResult
    func useSameSizeAsParent() -> Self {
        self.useAutoLayout()
        guard let superview = superview else { fatalError() }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            topAnchor.constraint(equalTo: superview.topAnchor),
            widthAnchor.constraint(equalTo: superview.widthAnchor),
            heightAnchor.constraint(equalTo: superview.heightAnchor)
            ])
        return self
    }
    
    func drawTopSeparator(rect: CGRect) {
        UIColor.separator.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0.5))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0.5))
        path.lineWidth = 1
        path.stroke()
    }
    
    func drawBottomSeparator(rect: CGRect) {
        UIColor.separator.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.maxY - 0.5))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 0.5))
        path.lineWidth = 1
        path.stroke()
    }
}

extension UIButton {
    override open var intrinsicContentSize: CGSize {
        let intrinsicContentSize = super.intrinsicContentSize
        let adjustedWidth = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }
}

extension UIDevice {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
    
    /// 在有 Taptic Engine 的设备上触发一个轻微的振动
    ///
    /// - Parameter params: level  (number)  0 ~ 3 表示振动等级
    func taptic(level: Int, isSupportTaptic: Bool = true) {
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

extension UIColor {
    static func fromHexString(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    static let separator = UIColor.fromHexString(hex: "2a2a2a")
}


extension UIImage {
    func resize(inSize boundSize: CGSize) -> UIImage {
        let targetSize = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(origin: .zero, size: boundSize)).size
        return UIGraphicsImageRenderer(size: targetSize).image { (context) in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension CGImage {
    func resize(inSize boundSize: CGSize) -> CGImage {
        let targetSize = AVMakeRect(aspectRatio: self.size, insideRect: CGRect(origin: .zero, size: boundSize)).size
        let context = CGContext(data: nil, width: Int(targetSize.width), height: Int(targetSize.height), bitsPerComponent: self.bitsPerComponent, bytesPerRow: self.bytesPerRow, space: self.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: self.bitmapInfo.rawValue)!
        context.draw(self, in: CGRect(origin: .zero, size: targetSize))
        return context.makeImage()!
    }
}

extension UIViewController {
    func isInitial() -> Bool {
        //        guard UIDevice.isSimulator else { fatalError() }
        let initialVC =  storyboard!.instantiateInitialViewController()!
        if let navigationVC = initialVC as? UINavigationController {
            return type(of: navigationVC.topViewController!) == type(of: self)
        } else {
            return type(of: initialVC) == type(of: self)
        }
    }    
}


extension TimeInterval {
    func formatTime() -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
}

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.font = UIFont(name: "Avenir-Light", size: 18)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

