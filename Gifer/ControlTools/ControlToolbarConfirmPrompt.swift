//
//  ControlToolbarConfirmPrompt.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

@objc protocol ConfirmPromptDelegate: class {
    func onPromptDismiss()
}

protocol TransactionView {
    func commitChange()
    func rollbackChange()
}

class ControlToolbarConfirmPrompt: UIStackView {
    
    private var okButton: ConfirmExtraButton!
    private var cancelButton: ConfirmExtraButton!
    weak var customDelegate: ConfirmPromptDelegate?
    
    var contentView: TransactionView!

    init(contentView: TransactionView) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        addArrangedSubview(contentView as! UIView)
        self.contentView = contentView
        
        let extraView = UIStackView()
        addArrangedSubview(extraView)
        extraView.translatesAutoresizingMaskIntoConstraints = false
        extraView.axis = .horizontal
        extraView.distribution = .fillEqually
        extraView.isLayoutMarginsRelativeArrangement = true
        
        okButton = ConfirmExtraButton(type: .ok)
        okButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOkClicked)))
        cancelButton = ConfirmExtraButton(type: .cancel)
        cancelButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCancelClicked)))
        extraView.addArrangedSubview(cancelButton)
        extraView.addArrangedSubview(okButton)
    }
    
    @objc func onOkClicked() {
        contentView.commitChange()
        customDelegate?.onPromptDismiss()
    }
    
    @objc func onCancelClicked() {
        contentView.rollbackChange()
        customDelegate?.onPromptDismiss()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
