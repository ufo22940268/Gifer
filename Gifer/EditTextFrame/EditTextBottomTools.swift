//
//  TextEditBottomTools.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol EditTextBottomToolsDelegate: class {
    func onItemSelected(item: EditTextBottomTools.Item)
}

class EditTextBottomTools: UIView {
    
    enum Item: CaseIterable {
        case keyboard, font, palette
        
        var icon: UIImage {
            switch self {
            case .keyboard:
                return #imageLiteral(resourceName: "keyboard-regular.png")
            case .font:
                return #imageLiteral(resourceName: "font-solid.png")
            case .palette:
                return #imageLiteral(resourceName: "palette-solid.png")
            }
        }
        
        var index: Int {
            switch self {
            case .keyboard:
                return 0
            case .font:
                return 1
            case .palette:
                return 2
            }
        }
    }
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView().useAutoLayout()
        stackView.axis = .horizontal
        return stackView
    }()
    
    weak var delegate: EditTextBottomToolsDelegate?
    var activatedItem = Item.keyboard

    init() {
        super.init(frame: CGRect.zero)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44)])

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        
        backgroundColor = .black
        
        for item in Item.allCases {
            addIcon(for: item)
        }                
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addIcon(for item: Item) {
        let button = UIButton(type: .custom).useAutoLayout()
        button.setImage(item.icon, for: .normal)
        button.tintColor = .gray
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onItemSelected(sender:))))
        stackView.addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            ])
    }
    
    func active(item: Item) {
        activatedItem = item
        let itemView = stackView.arrangedSubviews[item.index]
        itemView.tintColor = UIColor(named: "mainColor")
        
        stackView.arrangedSubviews.enumerated()
            .filter { (arg) -> Bool in  arg.0 != item.index }
            .forEach { arg in arg.1.tintColor = .gray }
    }
    
    @objc func onItemSelected(sender: UITapGestureRecognizer) {
        let index = stackView.arrangedSubviews.firstIndex(of: sender.view!)
        let item = Item.allCases.first { (item) -> Bool in
            item.index == index
        }!
        delegate?.onItemSelected(item: item)
    }
}
