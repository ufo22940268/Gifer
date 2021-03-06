//
//  GifOverlayViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

private let trashAnimationDuration = Double(0.3)

class GifOverlayViewController: UIViewController {
    
    @IBOutlet weak var overlayEditView: GifOverlayEditView!
    @IBOutlet weak var overlayRenderer: GifOverlayRenderer!
    @IBOutlet weak var trashView: TrashView!
    @IBOutlet weak var trashTopConstraint: NSLayoutConstraint!
    
    var stickerViews = [StickerView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isOpaque = false
        view.backgroundColor = .clear
    }
        
    func enableModification(_ enabled: Bool) {
        view.isUserInteractionEnabled = enabled
        overlayRenderer.editable = enabled
    }
    
    func addSticker(_ sticker: StickerInfo) {
        let sticker = overlayRenderer.addSticker(image: sticker.image
            , editable: true)
        sticker.stickerDelegate = self
        stickerViews.append(sticker)
    }
    
    func removeAllStickers() {
        for stickerView in stickerViews {
            removeSticker(stickerView)
        }
    }
    
    func hideStickerFrames(_ hide: Bool) {
        for stickerView in stickerViews {
            stickerView.hideFrame = hide
        }
    }
    
    func updateWhenContainerSizeChanged() {
        for stickerView in stickerViews {
            stickerView.updateLayoutWhenContainerSizeChanged()
        }
    }
    
    func onShowOptionMenu() {
        enableModification(true)
        hideStickerFrames(false)
    }
}

extension GifOverlayViewController: StickerViewDelegate {
    
    private func showTrash(for sticker: StickerView) {
        trashTopConstraint.constant = 0
        trashView.superview!.layoutIfNeeded()
        trashView.isHidden = false
        trashView.closeTrash()
        UIView.animate(withDuration: trashAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.trashTopConstraint.constant = 50
            self.trashView.superview!.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func hideTrash(for sticker: StickerView) {
        self.trashView.isHidden = true
    }
    
    func isStickerOverTrash(sticker: StickerView) -> Bool {
        let stickerRect = sticker.convert(sticker.validBoundsForDelete, to: trashView.superview!)
        return stickerRect.intersects(trashView.frame)
    }
    
    func removeSticker(_ sticker: StickerView) {
        if let index = stickerViews.firstIndex(of: sticker) {
            stickerViews.remove(at: index)
        }
        
        self.overlayRenderer.removeSticker(sticker)
    }
    
    var stickers: [StickerInfo] {
        return overlayRenderer.stickers
    }
        
    func onStickerPanStateChanged(state: UIGestureRecognizer.State, sticker: StickerView) {
        let hoverOnTrash = isStickerOverTrash(sticker: sticker)
        sticker.hoverOnTrash(hoverOnTrash)
        if case .began = state {
            showTrash(for: sticker)
        } else if case .ended = state {
            UIView.animate(withDuration: 0.175) {
                self.hideTrash(for: sticker)
                if hoverOnTrash {
                    self.removeSticker(sticker)
                }
            }
        } else {
            if hoverOnTrash {
                self.trashView.openTrash()
            } else {
                self.trashView.closeTrash()
            }
        }
    }
}
