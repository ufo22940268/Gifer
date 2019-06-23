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
    
    lazy var editField: EditTextPreviewer = {
        let previewer = EditTextPreviewer(textInfo: textInfo).useAutoLayout()
        previewer.delegate = self
        return previewer
    }()
    
    
    lazy var rootView: UIVisualEffectView = {
        let root = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).useAutoLayout()
        return root
    }()
    
    weak var delegate: EditTextViewControllerDelegate?
    
    var textInfo: EditTextInfo!
    var componentId: ComponentId?
    var contentView: UIView {
        return rootView.contentView
    }
    
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
        
        contentView.addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            toolbar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            toolbar.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor)
            ])
        contentView.addSubview(editField)
        NSLayoutConstraint.activate([
            editField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            editField.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 120)
            ])
        
        updateDoneButton(previewText: editField.text)
    }
}

extension EditTextViewController {
    
    @objc private func onCancel() {
        editField.textField.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func onDone() {
        if let componentId = componentId {
            delegate?.onUpdateEditText(info: editField.textInfo, componentId: componentId)
        } else {
            delegate?.onAddEditText(info: editField.textInfo)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension EditTextViewController: FontsPanelDelegate {
    func onFontSelected(font: UIFont) {
        editField.update(font: font)
    }
}


extension EditTextViewController: PalettePanelDelegate {
    func onColorSelected(color: UIColor) {
        editField.update(color: color)
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
