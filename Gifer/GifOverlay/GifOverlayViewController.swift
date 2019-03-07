//
//  GifOverlayViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GifOverlayViewController: UIViewController {
    
    @IBOutlet weak var overlayEditView: GifOverlayEditView!
    @IBOutlet weak var overlayRenderer: GifOverlayRenderer!
    @IBOutlet weak var trashView: TrashView!
    @IBOutlet weak var trashTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.isOpaque = false
        view.backgroundColor = .clear
    }
        
    func enableModification(_ enabled: Bool) {
        view.isUserInteractionEnabled = enabled
    }
    
    func addSticker(_ sticker: Sticker) {
        let sticker = overlayRenderer.addSticker(image: sticker.image
            , editable: true)
        sticker.stickerDelegate = self
    }
}

private let trashAnimationDuration = Double(0.3)

extension GifOverlayViewController: StickerViewDelegate {    
    
    private func showTrash(for sticker: StickerView) {
        trashTopConstraint.constant = 0
        trashView.superview!.layoutIfNeeded()
        trashView.isHidden = false
        trashView.closeTrash()
        UIView.animate(withDuration: trashAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.trashTopConstraint.constant = 100
            self.trashView.superview!.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func hideTrash(for sticker: StickerView) {
        self.trashView.isHidden = true
    }
    
    func isStickerOverTrash(sticker: StickerView) -> Bool {
        let stickerRect = sticker.convert(sticker.bounds, to: trashView.superview!)
        return stickerRect.intersects(trashView.frame)
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
                    self.overlayRenderer.removeSticker(sticker)
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
