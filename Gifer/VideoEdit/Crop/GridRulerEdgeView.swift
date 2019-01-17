//
//  GridRulerEdgeView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/17.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

enum GridRulerEdgePosition: CaseIterable, GridRulerControllerPosition {
    case left, top, right, bottom
    
    func setupLayout(child: UIView, parent: UIView, with corners: [GridRulerCornerPosition: GridRulerCornerView]) {
        switch self {
        case .left:
            NSLayoutConstraint.activate([
                child.widthAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth),
                child.topAnchor.constraint(equalTo: corners[.leftTop]!.bottomAnchor),
                child.bottomAnchor.constraint(equalTo: corners[.leftBottom]!.topAnchor),
                child.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
                ])
        case .top:
            NSLayoutConstraint.activate([
                child.heightAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth),
                child.leadingAnchor.constraint(equalTo: corners[.leftTop]!.trailingAnchor),
                child.trailingAnchor.constraint(equalTo: corners[.rightTop]!.leadingAnchor),
                child.topAnchor.constraint(equalTo: parent.topAnchor)
                ])
        case .right:
            NSLayoutConstraint.activate([
                child.widthAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth),
                child.topAnchor.constraint(equalTo: corners[.leftTop]!.bottomAnchor),
                child.bottomAnchor.constraint(equalTo: corners[.leftBottom]!.topAnchor),
                child.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
                ])
        case .bottom:
            NSLayoutConstraint.activate([
                child.heightAnchor.constraint(equalToConstant: gridRulerTouchEdgeWidth),
                child.leadingAnchor.constraint(equalTo: corners[.leftTop]!.trailingAnchor),
                child.trailingAnchor.constraint(equalTo: corners[.rightTop]!.leadingAnchor),
                child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
                ])
        }
    }
    
    func adjustFrame(parentConstraints: GridRulerView.Constraints, translate: CGPoint) {
        
    }
}

protocol GridRulerControllerPosition {
    func adjustFrame(parentConstraints: GridRulerView.Constraints, translate: CGPoint)
}

protocol GridRulerConstroller {
    var controllerPosition: GridRulerControllerPosition {get}
}

class GridRulerEdgeView: UIView, GridRulerConstroller {
    
    var controllerPosition: GridRulerControllerPosition {
        return position as GridRulerControllerPosition
    }
    
    var position: GridRulerEdgePosition!
    
    init(position: GridRulerEdgePosition) {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        self.position = position
        backgroundColor = UIColor.yellow
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayout(with corners: [GridRulerCornerPosition: GridRulerCornerView]) {
        guard let superview = superview else {
            return
        }
        self.position.setupLayout(child: self, parent: superview, with: corners)
    }
}
