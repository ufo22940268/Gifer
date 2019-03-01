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
        
//        let sticker = overlayRenderer.addSticker(image: #imageLiteral(resourceName: "01_Cuppy_smile.png"), editable: true)
//        sticker.stickerDelegate = self
        

        // Do any additional setup after loading the view.
    }
        
    func enableModification(_ enabled: Bool) {
        view.isUserInteractionEnabled = enabled
    }
}

private let trashAnimationDuration = Double(0.3)

extension GifOverlayViewController: StickerViewDelegate {    
    
    private func showTrash(for sticker: StickerView) {
        trashTopConstraint.constant = 0
        trashView.superview!.layoutIfNeeded()
        trashView.isHidden = false        
        UIView.animate(withDuration: trashAnimationDuration, delay: 0, options: .curveEaseIn, animations: {
            self.trashTopConstraint.constant = 100
            self.trashView.superview!.layoutIfNeeded()
            self.trashView.openTrash()
        }, completion: nil)
    }
    
    private func hideTrash(for sticker: StickerView) {
        UIView.animate(withDuration: trashAnimationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.trashTopConstraint.constant = 0
            self.trashView.superview!.layoutIfNeeded()
            self.trashView.closeTrash()
        }, completion: { _ in self.trashView.isHidden = true })
    }
    
    func isStickerOverTrash(sticker: StickerView) -> Bool {
        let stickerRect = sticker.convert(sticker.bounds, to: trashView.superview!)
        return stickerRect.intersects(trashView.frame)
    }
    
    func onPanStateChanged(state: UIGestureRecognizer.State, sticker: StickerView) {
        let hover = isStickerOverTrash(sticker: sticker)
        sticker.hoverOnTrash(hover)
        if case .began = state {
            showTrash(for: sticker)
        } else if case .ended = state {
            hideTrash(for: sticker)
        }
    }
}
