//
//  PlaySpeedView.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/12/27.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import UIKit

private let triangleHeight: CGFloat = 8
private let triangleWidth: CGFloat = 16

class PlaySpeedRulerView: UIView {
    
    enum Indicator {
        case short, long, middle
        
        static let width: CGFloat = 2
        
        func draw(left: CGFloat, in containerRect: CGRect) {
            var size: CGSize
            switch self {
            case .short:
                UIColor.darkGray.setFill()
                size = CGSize(width: Indicator.width, height: 10)
            case .long:
                UIColor.gray.setFill()
                size = CGSize(width: Indicator.width, height: 15)
            case .middle:
                UIColor.lightGray.setFill()
                size = CGSize(width: Indicator.width, height: 20)
            }
            UIRectFill(CGRect(origin: CGPoint(x: left, y: (containerRect.height - size.height)/2), size: size))
        }
    }
    
    struct RulerRange {
        
        var width: CGFloat
        let sideSpace: CGFloat
        let indicatorCount: Int = 9 + 1 + 9
        var indicators: [Indicator]
        var indicatorGap: CGFloat {
            return (width - sideSpace*2)/CGFloat(indicatorCount - 1)
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
        var indicatorContainerRect = rect
        indicatorContainerRect.size.height = indicatorContainerRect.height - triangleHeight
        for indicator in rulerRange.createIndicators() {
            indicator.draw(left: left, in: rect)
            left = left + rulerRange.indicatorGap
        }
    }
}

class PlaySpeedScrollView: UIScrollView {
    
    override var contentSize: CGSize {
        didSet {
            let initScrollX = (contentSize.width - bounds.width)/2
            contentOffset = CGPoint(x: initScrollX, y: 0)
        }
    }
}

class PlaySpeedView: UIStackView {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var speedView: UILabel!

    override func awakeFromNib() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 65)])
        
        let coverView = PlaySpeedCoverView()
        coverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(coverView)
        coverView.isUserInteractionEnabled = false
        NSLayoutConstraint.activate([
            coverView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            coverView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            coverView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)])
        
        scrollView.delegate = self
    }
}

extension PlaySpeedView: UIScrollViewDelegate {
    
    var currentSpeed: CGFloat {
        return 1.33
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        speedView.text = String(format: "%.1fx", currentSpeed)
    }
}

class PlaySpeedCoverView: UIView {
    
    convenience init() {
        self.init(frame: CGRect.zero)
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawTriangle(in: rect)
    }
    
    func drawTriangle(in rect: CGRect) {
        var points = [CGPoint]()
        points.append(CGPoint(x: rect.width/2, y: rect.maxY - triangleHeight))
        points.append(CGPoint(x: rect.width/2 - triangleWidth/2, y: rect.maxY))
        points.append(CGPoint(x: rect.width/2 + triangleWidth/2, y: rect.maxY))
        
        #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1).setFill()
        let path = UIBezierPath()
        path.move(to: points.first!)
        for point in points[1..<points.count] {
            path.addLine(to: point)
        }
        path.close()
        
        path.fill()
    }
}