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

class CropMenuView: UICollectionView, Transaction {
    
    var customDelegate: CropMenuViewDelegate!
    
    lazy var allCropSizes: [CropSize] = {
        var sizes = [CropSize]()
        sizes.append(CropSize(ratioHeight: 1, ratioWidth: 1, type: .ratio))
        sizes.append(CropSize(ratioHeight: 4, ratioWidth: 3, type: .ratio))
        sizes.append(CropSize(ratioHeight: 16, ratioWidth: 9, type: .ratio))
        sizes.append(CropSize(ratioHeight: 3, ratioWidth: 4, type: .ratio))
        return sizes
    }()

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        layout.scrollDirection = .horizontal
        super.init(frame: CGRect.zero, collectionViewLayout: layout)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 60)])
        
        register(CropSizeIcon.self, forCellWithReuseIdentifier: "cell")
        
        dataSource = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commitChange() {
    }
    
    func rollbackChange() {
    }
}

extension CropMenuView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allCropSizes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CropSizeIcon
        cell.setCropSize(allCropSizes[indexPath.row])
        return cell
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


class CropSizeIcon: UICollectionViewCell {
    
    var frameView: UIView!
    var labelView: UILabel!
    var frameWidthConstraint: NSLayoutConstraint!
    var frameHeightConstraint: NSLayoutConstraint!
    let containerSize = CGSize(width: 44, height: 44)

    override init(frame: CGRect) {
        super.init(frame: frame)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: containerSize.width),
            heightAnchor.constraint(equalToConstant: containerSize.height)])
        
        frameView = UIView()
        frameView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(frameView)

        frameView.layer.cornerRadius = 4
        frameView.layer.borderColor = UIColor(named: "mainColor")!.cgColor
        frameView.layer.borderWidth = 2
        NSLayoutConstraint.activate([
            frameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: centerYAnchor)])
        frameWidthConstraint = frameView.widthAnchor.constraint(equalToConstant: 0)
        frameHeightConstraint = frameView.heightAnchor.constraint(equalToConstant: 0)
        
        labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelView)
        NSLayoutConstraint.activate([
            labelView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor)])
   
        labelView.textColor = UIColor(named: "mainColor")
        labelView.font = UIFont.boldSystemFont(ofSize: 9)
        labelView.sizeToFit()

        backgroundColor = .clear
    }
    
    func setCropSize(_ size: CropSize) {
        if let ratioWidth = size.clamp?.width, let ratioHeight = size.clamp?.height {
            let frameSize = AVMakeRect(aspectRatio: CGSize(width: ratioWidth, height: ratioHeight), insideRect: CGRect(origin: CGPoint.zero, size: containerSize))
            frameWidthConstraint.constant = frameSize.width
            frameHeightConstraint.constant = frameSize.height
            frameWidthConstraint.isActive = true
            frameHeightConstraint.isActive = true
        }

        
        labelView.text = size.formatString
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
