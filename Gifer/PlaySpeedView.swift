//
//  PlaySpeedView.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

class PlaySpeedRulerView: UIView {
    
    enum Indicator {
        case short, long, middle
        
        static let width: CGFloat = 2
        
        func draw(left: CGFloat, in containerRect: CGRect) {
            var size: CGSize
            switch self {
            case .short:
                size = CGSize(width: Indicator.width, height: 15)
            case .long:
                size = CGSize(width: Indicator.width, height: 20)
            case .middle:
                size = CGSize(width: Indicator.width, height: 25)
            }
            UIColor.gray.setFill()
            UIRectFill(CGRect(origin: CGPoint(x: left, y: (containerRect.height - size.height)/2), size: size))
        }
    }
    
    struct RulerRange {
        
        var width: CGFloat
        let sideSpace: CGFloat
        let indicatorCount: Int = 9 + 1 + 9
        var indicators: [Indicator]
        var indicatorGap: CGFloat {
            return (width - sideSpace*2)/CGFloat(indicatorCount)
        }
        
        init(width: CGFloat) {
            self.width = width
            sideSpace = UIScreen.main.bounds.width/2
            indicators = [Indicator]()
            for i in 1...indicatorCount {
                if i == indicatorCount/2 + 1 {
                    indicators.append(Indicator.middle)
                } else if i % (indicatorCount/2/2 + 1) == 0 {
                    indicators.append(Indicator.long)
                } else {
                    indicators.append(Indicator.short)
                }
            }
        }

        var left: CGFloat {
            return sideSpace
        }
        
        var right: CGFloat {
            return width - sideSpace
        }
        

        func createIndicators() -> [Indicator] {
            return indicators
        }
    }
    
    var rulerWidth: CGFloat = UIScreen.main.bounds.width*2
    var rulerRange: RulerRange!
    
    override func awakeFromNib() {
        rulerRange = RulerRange(width: rulerWidth)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: rulerWidth)])
    }

    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        var left = rulerRange.left
        for indicator in rulerRange.createIndicators() {
            indicator.draw(left: left, in: rect)
            left = left + rulerRange.indicatorGap
        }
    }
}

class PlaySpeedView: UIStackView {
    
    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 65)])
    }
}
