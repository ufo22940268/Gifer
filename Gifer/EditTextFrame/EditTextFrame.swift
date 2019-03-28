//
//  TextEdifFrame.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit


class EditTextViewController: UIViewController {
    
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
    
    lazy var previewer: EditTextPreviewer = {
        let previewer = EditTextPreviewer().useAutoLayout()
        return previewer
    }()
    
    lazy var bottomTools: EditTextBottomTools = {
        let bottomTools = EditTextBottomTools().useAutoLayout()
        return bottomTools
    }()
    
    lazy var rootView: UIVisualEffectView = {
        return UIVisualEffectView(effect: UIBlurEffect(style: .dark)).useAutoLayout()
    }()
    
    lazy var fontsPanel: FontsPanel = {
        let fontsPanel = FontsPanel().useAutoLayout()
        fontsPanel.delegate = self
        return fontsPanel
    }()
    
    lazy var palettePanel: PalettePanel = {
        let panel = PalettePanel().useAutoLayout()
        return panel
    }()
    
    lazy var panelContainer: UIView = {
        let panelContainer = UIView().useAutoLayout()
        panelContainer.backgroundColor = .black
        NSLayoutConstraint.activate([
            panelContainer.heightAnchor.constraint(equalToConstant: keyboardHeight).with(identifier: "height")
            ])
        return panelContainer
    }()
    
    enum Tab {
        case fonts, palette
    }
    
    var originViewHeight: CGFloat?
    var keyboardHeight: CGFloat = 240 {
        didSet {
            panelContainer.constraints.findById(id: "height").constant = keyboardHeight
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(rootView)
        NSLayoutConstraint.activate([
            rootView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            rootView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])

        rootView.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            rootView.contentView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            rootView.contentView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            rootView.contentView.topAnchor.constraint(equalTo: stackView.topAnchor),
            rootView.contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            ])
        
        stackView.addArrangedSubview(toolbar)
        stackView.addArrangedSubview(previewer)
        stackView.addArrangedSubview(bottomTools)
        stackView.addArrangedSubview(panelContainer)
        
        openTab(.palette)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            originViewHeight = self.view.frame.height
            keyboardHeight = keyboardSize.height
            self.view.frame.size.height -= keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let originViewHeight = originViewHeight {
            self.view.frame.size.height = originViewHeight
        }
    }
}

extension EditTextViewController {
    
    private func openTab(_ tab: Tab) {
        var panel: UIView
        switch tab {
        case .fonts:
            panel = fontsPanel
        case .palette:
            panel = palettePanel
        }
        
        panelContainer.subviews.forEach {$0.removeFromSuperview()}
        panelContainer.addSubview(panel)
        panel.setSameSizeAsParent()
    }
}

extension EditTextViewController {
    
    @objc private func onCancel() {
        print("cancel")
    }
    
    @objc private func onDone() {
        
    }
}

extension EditTextViewController: FontsPanelDelegate {
    func onFontSelected(font: UIFont) {
        previewer.update(font: font)
    }
}
