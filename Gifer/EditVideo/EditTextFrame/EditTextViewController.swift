//
//  TextEdifFrame.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

protocol EditTextViewControllerDelegate: class {
    func onAddEditText(info: EditTextInfo)
    
    func onUpdateEditText(info: EditTextInfo, componentId: ComponentId)
}

typealias ComponentId = Int

class EditTextViewController: UIViewController {
    
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        return view
    }()
    
    lazy var doneButton: UIBarButtonItem = {
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        return done
    }()
    
    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.tintColor = UIColor(named: "mainColor")
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
        
        toolbar.setItems(
            [cancel,
             UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
             doneButton],
            animated: false)
        return toolbar
    }()
    
    lazy var previewer: EditTextPreviewer = {
        let previewer = EditTextPreviewer(textInfo: textInfo).useAutoLayout()
        previewer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onPreviewTap(sender:))))
        previewer.delegate = self
        return previewer
    }()
    
    lazy var bottomTools: EditTextBottomTools = {
        let bottomTools = EditTextBottomTools().useAutoLayout()
        return bottomTools
    }()
    
    lazy var rootView: UIVisualEffectView = {
        let root = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).useAutoLayout()
        return root
    }()
    
    lazy var fontsPanel: FontsPanel = {
        let fontsPanel = FontsPanel().useAutoLayout()
        fontsPanel.delegate = self
        return fontsPanel
    }()
    
    lazy var palettePanel: PalettePanel = {
        let panel = PalettePanel().useAutoLayout()
        panel.delegate = self
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
    
    var originViewHeight: CGFloat?
    var keyboardHeight: CGFloat = 240 {
        didSet {
            let bottomSafeInset = self.view.safeAreaInsets.bottom
            panelContainer.constraints.findById(id: "height").constant = keyboardHeight - bottomSafeInset
        }
    }
    
    weak var delegate: EditTextViewControllerDelegate?
    
    var textInfo: EditTextInfo!
    var componentId: ComponentId?
    
    init(textInfo: EditTextInfo) {
        super.init(nibName: nil, bundle: nil)
        self.textInfo = textInfo
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(rootView)
        NSLayoutConstraint.activate([
            rootView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            rootView.topAnchor.constraint(equalTo: view.topAnchor),
            rootView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])

        rootView.contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            rootView.contentView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            rootView.contentView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            rootView.contentView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
            ])
        
        stackView.addArrangedSubview(toolbar)
        stackView.addArrangedSubview(previewer)
        stackView.addArrangedSubview(bottomTools)
        stackView.addArrangedSubview(panelContainer)
        
        bottomTools.delegate = self
        openTab(.keyboard)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        originViewHeight = self.view.frame.height
        
        updateDoneButton(previewText: previewer.text)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
    }
    
    @objc func onPreviewTap(sender: UITapGestureRecognizer) {
        if bottomTools.activatedItem != .keyboard {
            bottomTools.active(item: .keyboard)
        }
    }
}

extension EditTextViewController {
    private func openTab(_ item: EditTextBottomTools.Item) {
        if item != .keyboard {
            previewer.showPlaceholderIfNeeded()
        } else {
            previewer.hidePlaceholderIfNeeded()
        }
        
        bottomTools.active(item: item)
        panelContainer.subviews.forEach {$0.removeFromSuperview()}

        var panel: UIView
        switch item {
        case .font:
            panel = fontsPanel
        case .palette:
            panel = palettePanel
        case .keyboard:
            showKeyboard()
            return
        }
        
        hideKeyboard()
        panelContainer.addSubview(panel)
        panel.useSameSizeAsParent()
    }
    
    private func showKeyboard() {
        previewer.textField.becomeFirstResponder()
    }
    
    private func hideKeyboard() {
        previewer.textField.resignFirstResponder()
    }
}


extension EditTextViewController {
    
    @objc private func onCancel() {
        previewer.textField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onDone() {
        if let componentId = componentId {
            delegate?.onUpdateEditText(info: previewer.textInfo, componentId: componentId)
        } else {
            delegate?.onAddEditText(info: previewer.textInfo)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension EditTextViewController: FontsPanelDelegate {
    func onFontSelected(font: UIFont) {
        previewer.update(font: font)
    }
}


extension EditTextViewController: PalettePanelDelegate {
    func onColorSelected(color: UIColor) {
        previewer.update(color: color)
    }
}

extension EditTextViewController: EditTextBottomToolsDelegate {
    func onItemSelected(item: EditTextBottomTools.Item) {
        openTab(item)
    }
}

extension EditTextViewController: EditTextPreviewerDelegate {
    func updateDoneButton(previewText: String) {
        doneButton.isEnabled = previewText.count > 0
    }
    
    func onTextChanged(newText: String) {
        updateDoneButton(previewText: newText)
    }
}
