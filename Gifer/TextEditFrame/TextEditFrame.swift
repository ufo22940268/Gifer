//
//  TextEdifFrame.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


class TextEditFrame: UIVisualEffectView {
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        return view
    }()
    
    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        
        toolbar.setItems(
            [cancel,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
             done],
            animated: false)
        return toolbar
    }()
    
    lazy var previewer: TextEditPreviewer = {
        let previewer = TextEditPreviewer().useAutoLayout()
        return previewer
    }()

    init() {
        super.init(effect: UIBlurEffect(style: .dark))
        setup()
    }
    
    override func awakeFromNib() {
        setup()
    }
    
    fileprivate func setup() {
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            contentView.topAnchor.constraint(equalTo: stackView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            ])
        
        stackView.addArrangedSubview(toolbar)
        stackView.addArrangedSubview(previewer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension TextEditFrame {
    
    @objc private func onCancel() {
        print("cancel")
    }
    
    @objc private func onDone() {
        
    }
}
