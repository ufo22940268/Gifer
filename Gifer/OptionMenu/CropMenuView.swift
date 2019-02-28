//
//  CropMenuView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/24.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

@objc protocol CropMenuViewDelegate: class {
    func onResetCrop()
}

class CropMenuView: UIScrollView, Transaction {
    
    var customDelegate: CropMenuViewDelegate!
    var contentView: UIStackView!
    
    var allCropSizes: [CropSize] {
        var sizes = [CropSize]()
        sizes.append(CropSize(ratioHeight: 1, ratioWidth: 1, type: .ratio))
        sizes.append(CropSize(ratioHeight: 4, ratioWidth: 3, type: .ratio))
        sizes.append(CropSize(ratioHeight: 16, ratioWidth: 9, type: .ratio))
        sizes.append(CropSize(ratioHeight: 3, ratioWidth: 4, type: .ratio))
        return sizes
    }

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60)])
        
        contentView = UIStackView()
        contentView.axis = .horizontal
        contentView.spacing = 16
        contentView.isLayoutMarginsRelativeArrangement = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        contentView.alignment = .center
        addSubview(contentView)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topAnchor.constraint(equalTo: contentView.topAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            heightAnchor.constraint(equalTo: contentView.heightAnchor)
            ])
        
        for size in allCropSizes {
            contentView.addArrangedSubview(CropSizeIcon(size:size))
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commitChange() {
    }
    
    func rollbackChange() {
    }
}

struct CropSize {
    var ratioHeight: Int?
    var ratioWidth: Int?
    var type: CropSizeType
    
    var formatString: String {
        switch type {
        case .ratio:
            return "\(ratioHeight!):\(ratioWidth!)"
        default:
            return ""
        }
    }
    
    var clamp: CGSize? {
        if let h = ratioHeight, let w = ratioWidth, CGFloat(h)/CGFloat(w) >= CGFloat(16)/9 {
            return CGSize(width: 9, height: 14)
        } else {
            return CGSize(width: ratioWidth!, height: ratioHeight!)
        }
    }
}

enum CropSizeType {
    case ratio, free, origin
}


class CropSizeIcon: UIView {
    
    var cropSize: CropSize!
    
    init(size: CropSize) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        let containerSize = CGSize(width: 44, height: 44)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: containerSize.width),
            heightAnchor.constraint(equalToConstant: containerSize.height)])
        
        let frameView = UIView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(frameView)
        if let ratioWidth = size.clamp?.width, let ratioHeight = size.clamp?.height {
            let frameSize = AVMakeRect(aspectRatio: CGSize(width: ratioWidth, height: ratioHeight), insideRect: CGRect(origin: CGPoint.zero, size: containerSize))
            NSLayoutConstraint.activate([
                frameView.widthAnchor.constraint(equalToConstant: frameSize.width),
                frameView.heightAnchor.constraint(equalToConstant: frameSize.height)])
        }
        NSLayoutConstraint.activate([
            frameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: centerYAnchor)])
        frameView.layer.cornerRadius = 4
        frameView.layer.borderColor = UIColor(named: "mainColor")!.cgColor
        frameView.layer.borderWidth = 2
        
        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelView)
        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor)])
        labelView.text = size.formatString
        labelView.textColor = UIColor(named: "mainColor")
        labelView.font = UIFont.boldSystemFont(ofSize: 9)
        labelView.sizeToFit()

        backgroundColor = .clear
        self.cropSize = size
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
