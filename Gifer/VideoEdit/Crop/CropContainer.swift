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

class CropContainer: UIView {

    var gridRulerView: GridRulerView!
    @objc weak var contentView: UIView!
    var scrollView: UIScrollView!
    var coverViews = [GridRulerCoverView]()
    
    var videoSize: CGSize? {
        didSet {
            self.cropRatio = videoSize
        }
    }
    
    var cropRatio: CGSize!
    
    func updateCroppingStatus(_ status: CroppingStatus) {
        switch status {
        case .normal:
            scrollView.isUserInteractionEnabled = false
            gridRulerView.isUserInteractionEnabled = false
            gridRulerView.isHidden = true
            coverViews.forEach{$0.updateStatus(.solid)}
        case .adjustCrop:
            scrollView.isUserInteractionEnabled = true
            gridRulerView.isUserInteractionEnabled = true
            gridRulerView.isHidden = false
            coverViews.forEach{$0.updateStatus(.adjust)}
        }
    }
    
    var cropArea: CGRect {
        let cropRect = scrollView.convert(gridRulerView.frame, from: gridRulerView.superview)
        let canvasRect = contentView.frame
        return cropRect.applying(CGAffineTransform(scaleX: 1/canvasRect.width, y: 1/canvasRect.height))
    }
    var restoreTask: DispatchWorkItem?

    override func awakeFromNib() {
        guard let superview = superview else { return }
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false
        scrollView.backgroundColor = UIColor.black
        addSubview(scrollView)
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 10
        
        NSLayoutConstraint.activate([
            scrollView.centerXAnchor.constraint(equalTo: centerXAnchor),
            scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
            scrollView.widthAnchor.constraint(equalTo: widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: heightAnchor)
            ])
        
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
        
        updateCroppingStatus(.normal)
    }
    
    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalToConstant: scrollView.bounds.width).with(identifier: "width"),
            contentView.heightAnchor.constraint(equalToConstant: scrollView.bounds.height).with(identifier: "height")
            ])
    }
    
    func setupVideo(frame videoFrame: CGRect) {
        gridRulerView.setupVideo(frame: videoFrame)
        contentView.constraints.findById(id: "width").constant = videoFrame.width
        contentView.constraints.findById(id: "height").constant = videoFrame.height
    }
    
    private var layoutSizeAccordingToVideoSize: CGSize? {
        guard let superview = superview, let videoSize = videoSize else { return nil }
        let rect = superview.bounds.inset(by: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
        let targetSize = AVMakeRect(aspectRatio: videoSize, insideRect: rect).size
        return targetSize
    }
    
    func updateWhenContainerSizeChanged(containerBounds: CGRect) {
        guard let targetSize = layoutSizeAccordingToVideoSize else { return  }
        constraints.findById(id: "height").constant = targetSize.height
        constraints.findById(id: "width").constant = targetSize.width
        
        contentView.constraints.findById(id: "height").constant = targetSize.height
        contentView.constraints.findById(id: "width").constant = targetSize.width
        
        gridRulerView.constraints.findById(id: "height").constant = targetSize.height
        gridRulerView.constraints.findById(id: "width").constant = targetSize.width
        gridRulerView.syncConstraintsToGuide()
    }
    
    func changeCropSize(_ targetSize: CGSize) {
        constraints.findById(id: "height").constant = targetSize.height
        constraints.findById(id: "width").constant = targetSize.width

        gridRulerView.constraints.findById(id: "height").constant = targetSize.height
        gridRulerView.constraints.findById(id: "width").constant = targetSize.width
        gridRulerView.customConstraints.centerY.constant = 0
        gridRulerView.customConstraints.centerX.constant = 0
    }
    
    func createTestContentView() -> UIView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        scrollView.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(size: scrollView.frame.size).image { (context) in
            #imageLiteral(resourceName: "IMG_3415.JPG").draw(centerIn: CGRect(origin: CGPoint.zero, size: scrollView.frame.size))
        }
        imageView.image = image
        imageView.contentMode = .center
        return imageView
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) {
            return hitView
        } else {
            return scrollView
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
    
    func resetCrop(videoRect: CGRect) {
        constraints.findById(id: "width").constant = videoRect.width
        constraints.findById(id: "height").constant = videoRect.height
        contentView.constraints.findById(id: "width").constant = videoRect.width
        contentView.constraints.findById(id: "height").constant = videoRect.height
        scrollView.zoomScale = 1
        scrollView.contentOffset = CGPoint.zero
        gridRulerView.customConstraints.width.constant = videoRect.width
        gridRulerView.customConstraints.height.constant = videoRect.height
        gridRulerView.customConstraints.centerX.constant = 0
        gridRulerView.customConstraints.centerY.constant = 0
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
    }
    
    func updateWhenVideoSizeChanged(videoSize: CGSize) {
        gridRulerView.customConstraints.width.constant = videoSize.width
        gridRulerView.customConstraints.height.constant = videoSize.height
        gridRulerView.guideConstraints.width.constant = videoSize.width
        gridRulerView.guideConstraints.height.constant = videoSize.height
        
        contentView.constraints.findById(id: "width").constant = videoSize.width
        contentView.constraints.findById(id: "height").constant = videoSize.height
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
            self.restorePositionWhenDragFinished()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: restoreTask!)
    }
}

extension CropContainer: UIScrollViewDelegate {
 
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}

extension CGRect {
    func getEdgeInsets(withContainer container: CGRect) -> UIEdgeInsets {
        return UIEdgeInsets(top: minY, left: minX, bottom: container.maxY - maxY, right: container.maxX - maxX)
    }
}
