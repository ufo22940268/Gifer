//
//  EditTextColorPickerView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class EditTextColorPickerCell: UICollectionViewCell {
    
    var color: UIColor! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let rect = rect.insetBy(dx: 4, dy: 4)
        let outerRing = UIBezierPath(ovalIn: rect)
        UIColor.white.setStroke()
        outerRing.lineWidth = 2
        outerRing.stroke()
        
        if let color = color {
            let colorCircle = UIBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            color.setFill()
            colorCircle.fill()
        }
        
        if isSelected {
            let selectedRing = UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2))
            selectedRing.lineWidth = 2
            UIColor.black.setStroke()
            selectedRing.stroke()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class EditTextColorPickerView: UICollectionView {

    var allColors = Palette.allColors
    
    init() {
        let layout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: layout)
        
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 40, height: 40)
        
        dataSource = self
        
        register(EditTextColorPickerCell.self, forCellWithReuseIdentifier: "cell")
    }
        
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditTextColorPickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EditTextColorPickerCell
        let color = allColors[indexPath.row]
        cell.color = color
        return cell
    }
}
