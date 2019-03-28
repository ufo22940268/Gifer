//
//  FontsPanel.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/28.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol FontsPanelDelegate: class {
    func onFontSelected(font: UIFont)
}

class FontsPanel: UIView {
    
    lazy var fontPickerView: UIPickerView = {
        let fontPickerView = UIPickerView().useAutoLayout()
        fontPickerView.dataSource = self
        fontPickerView.delegate = self
        return fontPickerView
    }()
    
    lazy var allFonts: [UIFont] = UIFont.listAllFonts()

    weak var delegate: FontsPanelDelegate?

    init() {
        super.init(frame: CGRect.zero)
        addSubview(fontPickerView)
        fontPickerView.setSameSizeAsParent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FontsPanel: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allFonts.count
    }
}

extension FontsPanel: UIPickerViewDelegate {    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let font = allFonts[row]
        delegate?.onFontSelected(font: font)
        return NSAttributedString(string: font.fontName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
}
