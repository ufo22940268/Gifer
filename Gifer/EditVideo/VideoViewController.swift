//
//  EditingViewController.swift//  Gifer
//
//  Created by Frank Cheng on 2018/11/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

typealias progress = CMTime

class VideoPreviewView: UIImageView {

    init() {
        super.init(frame: CGRect.zero)
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol ImagePlayerDelegate: class {
    
    func onProgressChanged(progress: CMTime)
    
    func onBuffering(_ inBuffering: Bool)
    
    func updatePlaybackStatus(_ status: AVPlayer.TimeControlStatus)
}

class VideoViewController: UIViewController {
    
    var previewView: VideoPreviewView!
    var trimPosition: VideoTrimPosition {
        return imagePlayerView.trimPosition
    }
    var dismissed: Bool = false
    var videoInited: Bool = false
    var previewImage: UIImage?

    @IBOutlet var imagePlayerView: ImagePlayerView!
    var playerItem: ImagePlayerItem! {
        return imagePlayerView.playerItem
    }
    var videoBounds: CGRect {
        return CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
    }
    
    var filter: YPFilter? {
        return imagePlayerView.filter
    }
    
    var playDirection: PlayDirection = .forward {
        didSet {
            imagePlayerView.playDirection = self.playDirection
        }
    }
    
    func load(playerItem: ImagePlayerItem) -> Void {
        imagePlayerView.load(playerItem: playerItem)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if playerItem != nil {
            imagePlayerView.paused = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imagePlayerView.paused = true
    }
    
    func destroy() {
        imagePlayerView.destroy()
    }
    
    func setFilter(_ filter: YPFilter) {
        imagePlayerView.filter = filter
    }
    
    func setRate(_ rate: Float) {
        imagePlayerView.rate = rate
    }
    
    func play() {
        imagePlayerView.paused = false
    }
    
    func pause() {
        imagePlayerView.paused = true
    }
    
    func stop() {
        imagePlayerView.paused = true
    }
    
    weak var videoViewControllerDelegate: ImagePlayerDelegate? {
        didSet {
            imagePlayerView.customDelegate = videoViewControllerDelegate
        }
    }
}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition, state: VideoTrimState, side: TrimController.Side) {
        var toProgress: CMTime!
        if side == .left {
            toProgress = position.leftTrim
        } else {
            toProgress = position.rightTrim
        }
        imagePlayerView.seek(to: toProgress)
        imagePlayerView.trimPosition = position
        
        switch state {
        case .started:
            imagePlayerView.paused = true
        case .finished(_):
            imagePlayerView.paused = false
        default:
            break
        }
    }
}
