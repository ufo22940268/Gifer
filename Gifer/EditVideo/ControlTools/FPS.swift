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
    case f7 = 7
    case f24 = 24
    case f30 = 30
    
    //The fps label size should be 30x30.
    var image: UIImage {
        let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        label.adjustsFontSizeToFitWidth = true
        label.text = String(self.rawValue)
        label.textColor = .lightText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 25, weight: .semibold)
        label.sizeToFit()
        let canvasRect: CGRect = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))
        return UIGraphicsImageRenderer(bounds: canvasRect).image { context in
            label.drawText(in: canvasRect)
        }
    }
    
    static func showSelectionDialog(from host: UIViewController, completion: @escaping (FPSFigure) -> Void) {
        let vc = UIAlertController(title: NSLocalizedString("Select FPS", comment: ""), message: nil, preferredStyle: .alert)
        for figure in FPSFigure.allCases {
            vc.addAction(UIAlertAction(title: "\(figure.rawValue)FPS", style: .default, handler: { (_) in
                completion(figure)
            }))
        }
        
        host.present(vc, animated: true, completion: nil)
    }
}
