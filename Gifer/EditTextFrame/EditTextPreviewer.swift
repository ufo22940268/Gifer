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
        return textView
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
            ])
        
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(equalTo: centerXAnchor),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor)])
        setText("adsf")
        
        textView.becomeFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        textView.text = text
        textView.sizeToFit()
    }
}
