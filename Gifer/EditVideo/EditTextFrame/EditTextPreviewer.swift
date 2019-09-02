//
//  TextEditPreviewer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol EditTextPreviewerDelegate: class {
    func onTextChanged(newText: String)
}

class EditTextPreviewer: UIView {
    
    lazy var textField: UITextField = {
        let textView = UITextField(frame: CGRect.zero).useAutoLayout()
        textView.textColor = .white
        textView.textAlignment = .center
        textView.keyboardAppearance = .dark
        textView.delegate = self
        return textView
    }()
    
    let textSize = CGFloat(30)
    
    let placeholderText = "触摸可编辑"
    var enablePlaceholder = false
    
    var text: String {
        if enablePlaceholder {
            return ""
        } else {
            return textField.text!
        }
    }
    
    var textInfo: EditTextInfo {
        get {
            return EditTextInfo(text: text, fontName: textField.font!.fontName, textColor: textField.textColor!)
        }
    }
    
    weak var delegate: EditTextPreviewerDelegate?
    
    init(textInfo: EditTextInfo) {
        super.init(frame: CGRect.zero)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
            ])
        
        addSubview(textField)
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.widthAnchor.constraint(equalTo: widthAnchor),
            textField.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        
        textField.becomeFirstResponder()
        
        textField.text = textInfo.text
        textField.textColor = textInfo.textColor
        textField.font = UIFont(name: textInfo.fontName, size: textSize)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onEditFieldChanged(notif:)), name: UITextField.textDidChangeNotification, object: textField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onEditFieldChanged(notif: Notification) {
        delegate?.onTextChanged(newText: text)
    }

    func setText(_ text: String) {
        textField.text = text
        textField.sizeToFit()
    }
    
    func showPlaceholderIfNeeded() {
        if textInfo.text.count == 0 {
            textField.text = placeholderText
            enablePlaceholder = true
        }
        
        textField.resignFirstResponder()
    }

    func hidePlaceholderIfNeeded() {
        if enablePlaceholder {
            textField.text = ""
            enablePlaceholder = false
        }
        textField.becomeFirstResponder()
    }
}

extension EditTextPreviewer {
    func update(font: UIFont) {
        textField.font = UIFont(name: font.fontName, size: textField.font!.pointSize)
    }
    
    func update(color: UIColor) {
        textField.textColor = color
    }
}

extension EditTextPreviewer: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        return text.replacingCharacters(in: Range(range, in: text)!, with: string).count < 20
    }
}
