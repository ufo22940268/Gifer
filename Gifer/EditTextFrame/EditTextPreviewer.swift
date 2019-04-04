//
//  TextEditPreviewer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


class EditTextPreviewer: UIView {
    
    lazy var textView: UITextField = {
        let textView = UITextField(frame: CGRect.zero).useAutoLayout()
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize + 8)
        textView.textAlignment = .center
        return textView
    }()
    
    let textSize = CGFloat(20)
    
    var textInfo: EditTextInfo {
        get {
            return EditTextInfo(text: textView.text!, fontName: textView.font!.fontName, textColor: textView.textColor!)
        }
    }
    
    init(textInfo: EditTextInfo) {
        super.init(frame: CGRect.zero)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
            ])
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(equalTo: centerXAnchor),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.widthAnchor.constraint(equalTo: widthAnchor),
            ])
        
        textView.becomeFirstResponder()
        
        textView.text = textInfo.text
        textView.textColor = textInfo.textColor
        textView.font = UIFont(name: textInfo.fontName, size: textSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        textView.text = text
        textView.sizeToFit()
    }
}


extension EditTextPreviewer {
    func update(font: UIFont) {
        textView.font = UIFont(name: font.fontName, size: textView.font!.pointSize)
    }
    
    func update(color: UIColor) {
        textView.textColor = color
    }
}
