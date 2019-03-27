//
//  TextEditBottomTools.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

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
    }
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView().useAutoLayout()
        stackView.axis = .horizontal
        return stackView
    }()

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
        stackView.addArrangedSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 60),
            ])
    }
}
