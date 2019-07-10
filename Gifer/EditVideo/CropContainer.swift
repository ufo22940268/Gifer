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
    var imagePlayerView: UIView!
    weak var scrollView: UIScrollView!
    var coverViews = [GridRulerCoverView]()
    
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
    var restoreTask: DispatchWorkItem?
    
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
    }
    
    private var layoutSizeAccordingToVideoSize: CGSize? {
        guard let superview = superview, let videoSize = videoSize else { return nil }
        let rect = superview.bounds
        if gridRulerView.isGridChanged {
            return gridRulerView.bounds.size
        } else {
            let targetSize = AVMakeRect(aspectRatio: videoSize, insideRect: rect).size
            return targetSize
        }
    }
    
    ///Triggerd by crop container size changed
    func updateWhenContainerSizeChanged(containerBounds: CGRect) {
        guard let targetSize = layoutSizeAccordingToVideoSize else { return }
        constraints.findById(id: "height").constant = targetSize.height
        constraints.findById(id: "width").constant = targetSize.width
        
        if gridRulerView.isGridChanged {
        } else {
            imagePlayerView.constraints.findById(id: "height").constant = targetSize.height
            imagePlayerView.constraints.findById(id: "width").constant = targetSize.width
        }
        
        gridRulerView.constraints.findById(id: "height").constant = targetSize.height
        gridRulerView.constraints.findById(id: "width").constant = targetSize.width
        gridRulerView.syncConstraintsToGuide()
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
    
    func updateLayout(width: CGFloat, height: CGFloat) {
        constraints.findById(id: "width").constant = width
        constraints.findById(id: "height").constant = height
    }
    
    func adjustTo(ratio: CGSize) {
        guard let layoutSize = layoutSizeAccordingToVideoSize else { return }
        scrollView.zoomScale = 1.0
        updateLayout(width: layoutSize.width, height: layoutSize.height)
        gridRulerView.updateLayout(width: layoutSize.width, height: layoutSize.height)
        superview!.layoutIfNeeded()

        cropRatio = ratio
        let container = self.bounds
        let targetRect = AVMakeRect(aspectRatio: ratio, insideRect: container)
        
        gridRulerView.resizeTo(rect: targetRect)
        constraints.findById(id: "width").constant = targetRect.width
        constraints.findById(id: "height").constant = targetRect.height
        
        scrollView.contentOffset = CGPoint(x: (scrollView.contentSize.width - targetRect.width)/2, y: (scrollView.contentSize.height - targetRect.height)/2)
        
        gridRulerView?.isGridChanged = true
    }
}

extension CropContainer: GridRulerViewDelegate {
    fileprivate func restorePositionWhenDragFinished() {
        let fromRulerFrame = gridRulerView.frame
        let scrollFrame = self.scrollView.convert(scrollView.frame, from: scrollView.superview!)
        let fromScrollContentSize = self.scrollView.contentSize
        let fromRulerFrameInContentCoordinate = self.scrollView.convert(gridRulerView.frame, from: gridRulerView.superview!)

        let toRulerSize = AVMakeRect(aspectRatio: fromRulerFrame.size, insideRect: scrollFrame).size

        let toWidth = toRulerSize.width
        let toHeight = toRulerSize.height
        let toCenterX = CGFloat(0)
        let toCenterY = CGFloat(0)

        UIView.animate(withDuration: 0.3) {
            self.gridRulerView.customConstraints.width.constant = toWidth
            self.gridRulerView.customConstraints.height.constant = toHeight
            self.gridRulerView.customConstraints.centerX.constant = toCenterX
            self.gridRulerView.customConstraints.centerY.constant = toCenterY
            self.layoutIfNeeded()

            let toRulerFrame = self.gridRulerView.frame

            let newZoomScale = self.scrollView.zoomScale*toRulerFrame.width/fromRulerFrame.width

            self.scrollView.zoomScale = newZoomScale
            self.constraints.first(where: {$0.identifier == "width"})!.constant = toWidth
            self.constraints.first(where: {$0.identifier == "height"})!.constant = toHeight
            self.layoutIfNeeded()

            let contentOriginPostition = self.scrollView.contentSize.applying(CGAffineTransform(scaleX: fromRulerFrameInContentCoordinate.minX/fromScrollContentSize.width, y: fromRulerFrameInContentCoordinate.minY/fromScrollContentSize.height))
            self.scrollView.contentOffset = CGPoint(x: contentOriginPostition.width, y: contentOriginPostition.height)
        }
    }
    
    
    func onDragFinished() {
        restoreTask?.cancel()
        restoreTask = DispatchWorkItem {
//            self.restorePositionWhenDragFinished()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: restoreTask!)
    }
    
    func resetCropArea() {
        gridRulerView.isGridChanged = false
        adjustTo(ratio: videoSize!)
    }
}

extension CropContainer: UIScrollViewDelegate {
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if status == .adjustCrop {
            return imagePlayerView
        } else {
            return nil
        }
    }
}

