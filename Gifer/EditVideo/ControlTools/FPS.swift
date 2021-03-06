//
//  FPS.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/15.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum FPSFigure: Int, CaseIterable {
    case f2 = 2
    case f5 = 5
    case f10 = 10
    case f20 = 20
    case f30 = 30
    
    static let `default` = FPSFigure.f5
    
    var interval: Double {
        return 1/Double(self.rawValue)
    }
    
    static func build(fromInterval: Double) -> FPSFigure {
        return FPSFigure.allCases.min { abs(1/Double($0.rawValue) - fromInterval) < abs(1/Double($1.rawValue) - fromInterval) }!
    }
    
    //The fps label size should be 30x30.
    var image: UIImage {
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        label.adjustsFontSizeToFitWidth = true
        label.text = String(self.rawValue)
        label.textColor = .lightText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 25, weight: .regular)
        label.sizeToFit()
        let canvasRect: CGRect = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))
        return UIGraphicsImageRenderer(bounds: canvasRect).image { context in
            label.drawText(in: canvasRect)
        }
    }
    
    static func showSelectionDialog(from host: EditViewController, currentFPS: FPSFigure, completion: @escaping (FPSFigure) -> Void) {
        host.pause()
        let vc = UIAlertController(title: NSLocalizedString("Select FPS", comment: ""), message: nil, preferredStyle: .alert)
        for figure in FPSFigure.allCases {
            vc.addAction(UIAlertAction(title: "\(figure.rawValue) FPS", style: .default, handler: { (_) in
                completion(figure)
            }))
            
            if figure == currentFPS {
                vc.preferredAction = vc.actions.last!
            }
        }
        vc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { _ in host.play() }))
        host.present(vc, animated: true, completion: nil)
    }
}
