//
//  CropContainer.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/1/16.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

enum CroppingStatus {
    case normal, adjustCrop
}

protocol CropContainerDelegate: class {
    func onDeactiveComponents()
}

class CropContainer: UIView {

    var gridRulerView: GridRulerView!
    var imagePlayerView: ImagePlayerView!
    var scrollView: UIScrollView!
    var coverViews = [GridRulerCoverView]()
    var initialCropArea: CGRect?
    
    var videoSize: CGSize? {
        didSet {
            self.cropRatio = videoSize
        }
    }
    
    var width: NSLayoutConstraint {
        return constraints.findById(id: "width")
    }
    
    var height: NSLayoutConstraint {
        return constraints.findById(id: "height")
    }

    var cropRatio: CGSize!
    var status: CroppingStatus = .normal
    
    func updateCroppingStatus(_ status: CroppingStatus) {
        self.status = status
        switch status {
        case .normal:
            scrollView.isScrollEnabled = false
            gridRulerView.isUserInteractionEnabled = false
            gridRulerView.isHidden = true
            coverViews.forEach{$0.updateStatus(.solid)}
        case .adjustCrop:
            scrollView.isScrollEnabled = true
            gridRulerView.isUserInteractionEnabled = true
            gridRulerView.isHidden = false
            coverViews.forEach{$0.updateStatus(.adjust)}
        }
    }
    
    var cropArea: CGRect {
        let cropRect = scrollView.convert(gridRulerView.frame, from: gridRulerView.superview)
        let canvasRect = imagePlayerView.frame
        return cropRect.applying(CGAffineTransform(scaleX: 1/canvasRect.width, y: 1/canvasRect.height))
    }
    
    weak var customDelegate: CropContainerDelegate?

    func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false
        scrollView.backgroundColor = UIColor.black
        
        scrollView.delegate = self
        
        
        gridRulerView = GridRulerView(scrollView: scrollView)
        addSubview(gridRulerView)
        gridRulerView.translatesAutoresizingMaskIntoConstraints = false
        let centerX = gridRulerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerX.identifier = "centerX"
        let centerY = gridRulerView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerY.identifier = "centerY"
        let width = gridRulerView.widthAnchor.constraint(equalToConstant: 0)
        width.priority = .defaultLow
        width.identifier = "width"
        let height = gridRulerView.heightAnchor.constraint(equalToConstant: 0)
        height.priority = .defaultLow
        height.identifier = "height"
        NSLayoutConstraint.activate([centerX, centerY, width, height])
        
        gridRulerView.setup()
        gridRulerView.delegate = self
        
        bringSubviewToFront(gridRulerView)
        
        setupCover()
        updateCroppingStatus(.adjustCrop)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
    }
    
    @objc func onTap(sender: UITapGestureRecognizer) {
        customDelegate?.onDeactiveComponents()
    }
    
    func setupVideo(frame videoFrame: CGRect) {
        isHidden = false
        width.constant = videoFrame.width
        height.constant = videoFrame.height
        gridRulerView.setupVideo(frame: videoFrame)
        
        imagePlayerView.paused = true
        
        NSLayoutConstraint.activate([
            imagePlayerView.widthAnchor.constraint(equalToConstant: videoFrame.width),
            imagePlayerView.heightAnchor.constraint(equalToConstant: videoFrame.height)
            ])
        
        if let cropArea = initialCropArea {
            let cropViewRect = AVMakeRect(aspectRatio: cropArea.size.applying(CGAffineTransform(scaleX: videoFrame.width, y: videoFrame.height)), insideRect: superview!.bounds)
            width.constant = cropViewRect.width
            height.constant = cropViewRect.height
            gridRulerView.customConstraints.width.constant = cropViewRect.width
            gridRulerView.customConstraints.height.constant = cropViewRect.height
            gridRulerView.syncGuideConstraints()
            layoutIfNeeded()
            
            let zoomToRect = cropArea.applying(CGAffineTransform(scaleX: imagePlayerView.bounds.width, y: imagePlayerView.bounds.height))
            scrollView.zoom(to: zoomToRect, animated: false)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if status == .adjustCrop {
            let pointOfGrid = gridRulerView.convert(point, from: self)
            if gridRulerView.hitBorder(point: pointOfGrid) {
                return super.hitTest(point, with: event)
            } else {
                return scrollView
            }
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
    func setupCover() {
        let frameView = gridRulerView.frameView!
        
        let left = GridRulerCoverView()
        addSubview(left)
        let contentView = superview!
        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: frameView.leadingAnchor),
            left.topAnchor.constraint(equalTo: contentView.topAnchor),
            left.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        
        let top = GridRulerCoverView()
        addSubview(top)
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            top.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            top.topAnchor.constraint(equalTo: contentView.topAnchor),
            top.bottomAnchor.constraint(equalTo: frameView.topAnchor)
            ])

        let right = GridRulerCoverView()
        addSubview(right)
        NSLayoutConstraint.activate([
            right.leadingAnchor.constraint(equalTo: frameView.trailingAnchor),
            right.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            right.topAnchor.constraint(equalTo: top.bottomAnchor),
            right.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

        let bottom = GridRulerCoverView()
        addSubview(bottom)
        NSLayoutConstraint.activate([
            bottom.leadingAnchor.constraint(equalTo: left.trailingAnchor),
            bottom.trailingAnchor.constraint(equalTo: right.leadingAnchor),
            bottom.topAnchor.constraint(equalTo: frameView.bottomAnchor),
            bottom.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
        
        coverViews.append(contentsOf: [left, right, top, bottom])
        bringSubviewToFront(gridRulerView)
    }
}

extension CropContainer: GridRulerViewDelegate {
    
    /// Resize crop area with animation
    ///
    /// - Parameter gridBounds: bounds of gridRulerView.
    fileprivate func resizeTo(gridBounds: CGRect) {
        let rect = gridRulerView.convert(gridBounds, to: imagePlayerView)
        let newRect = AVMakeRect(aspectRatio: rect.size, insideRect: superview!.bounds)
        
        UIView.animate(withDuration: 0.5) {
            self.width.constant = newRect.width
            self.height.constant = newRect.height
            self.gridRulerView.customConstraints.width.constant = newRect.width
            self.gridRulerView.customConstraints.height.constant = newRect.height
            self.gridRulerView.customConstraints.centerX.constant = 0
            self.gridRulerView.customConstraints.centerY.constant = 0
            self.gridRulerView.syncGuideConstraints()
            
            self.scrollView.zoom(to: rect, animated: false)
            self.layoutIfNeeded()
        }
    }
    
    func resizeTo(ratio: CGSize) {
        let gridBounds = AVMakeRect(aspectRatio: ratio, insideRect: gridRulerView.bounds)
        let rect = gridRulerView.convert(gridBounds, to: imagePlayerView)
        let newRect = AVMakeRect(aspectRatio: rect.size, insideRect: superview!.bounds)
                
        UIView.animate(withDuration: 0.5) {
            self.width.constant = newRect.width
            self.height.constant = newRect.height
            self.gridRulerView.customConstraints.width.constant = newRect.width
            self.gridRulerView.customConstraints.height.constant = newRect.height
            self.gridRulerView.customConstraints.centerX.constant = 0
            self.gridRulerView.customConstraints.centerY.constant = 0
            self.gridRulerView.syncGuideConstraints()
            self.layoutIfNeeded()
        }
    }
    
    func onDragFinished() {
        resizeTo(gridBounds: gridRulerView.bounds)
    }
    
    func resetCropArea() {
        UIView.animate(withDuration: 0.5) {
            let toRect = AVMakeRect(aspectRatio: self.imagePlayerView.bounds.size, insideRect: self.superview!.bounds)
            self.width.constant = toRect.width
            self.height.constant = toRect.height
            self.gridRulerView.customConstraints.width.constant = toRect.width
            self.gridRulerView.customConstraints.height.constant = toRect.height
            self.gridRulerView.customConstraints.centerX.constant = 0
            self.gridRulerView.customConstraints.centerY.constant = 0
            self.gridRulerView.syncGuideConstraints()
            
            self.scrollView.contentOffset = .zero
            self.scrollView.setZoomScale(toRect.width/self.imagePlayerView.bounds.width, animated: false)
            self.superview?.layoutIfNeeded()
        }
    }
}

extension CropContainer: UIScrollViewDelegate {
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imagePlayerView
    }
}

extension CropContainer: CropMenuViewDelegate {
    func onCropSizeSelected(size: CropSize) {
        if size.type == .free {
            resizeTo(ratio: imagePlayerView.bounds.size)
        } else {
            resizeTo(ratio: size.ratio)
        }
    }
}
