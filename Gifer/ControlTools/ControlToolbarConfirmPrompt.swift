//
//  ControlToolbarConfirmPrompt.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/26.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

@objc protocol ConfirmPromptDelegate: class {
    func onPromptDismiss(toolbarItem: ToolbarItem, commitChange: Bool)
}

protocol Transaction {
    func commitChange()
    func rollbackChange()
}

typealias TransactionView = UIView&Transaction

class ControlToolbarConfirmPrompt: UIStackView {
    
    private var okButton: ConfirmExtraButton!
    private var cancelButton: ConfirmExtraButton!
    weak var customDelegate: ConfirmPromptDelegate?
    
    var contentView: TransactionView!
    var toolbarItem: ToolbarItem!

    init(contentView: TransactionView, toolbarItem: ToolbarItem) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        addArrangedSubview(contentView)
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
        
        self.toolbarItem = toolbarItem
    }
    
    @objc func onOkClicked() {
        contentView.commitChange()
        customDelegate?.onPromptDismiss(toolbarItem: self.toolbarItem, commitChange: true)
    }
    
    @objc func onCancelClicked() {
        contentView.rollbackChange()
        customDelegate?.onPromptDismiss(toolbarItem: self.toolbarItem, commitChange: false)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
