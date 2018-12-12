//
//  EditingViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/10.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Photos

extension AVPlayer {
    func seek(toProgress progress: CGFloat) {
        seek(to: progress*self.currentItem!.duration)
    }
}

class VideoPreviewView: UIImageView {

    init() {
        super.init(frame: CGRect.zero)
        contentMode = .scaleAspectFit
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class VideoViewController: AVPlayerViewController {
    
    var previewView: VideoPreviewView!
    
    override func viewDidLoad() {
        if let contentOverlayView = contentOverlayView {
            previewView = VideoPreviewView()
            previewView.translatesAutoresizingMaskIntoConstraints = false
            contentOverlayView.addSubview(previewView);
            NSLayoutConstraint.activate([
                previewView.leadingAnchor.constraint(equalTo: contentOverlayView.leadingAnchor),
                previewView.trailingAnchor.constraint(equalTo: contentOverlayView.trailingAnchor),
                previewView.topAnchor.constraint(equalTo: contentOverlayView.topAnchor),
                previewView.bottomAnchor.constraint(equalTo: contentOverlayView.bottomAnchor)
                ])
            previewView.backgroundColor = UIColor.black 
        }
    }
    
    func load(playerItem: AVPlayerItem) -> Void {
        self.player = AVPlayer(playerItem: playerItem)
        addPeriodicTimeObserver()
    }
    
    func setPreviewImage(_ image: UIImage) {
        previewView.image = image
    }
    
    func play() {
        self.player?.play()
    }
    
    func pause() {
        self.player?.pause()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removePeriodicTimeObserver()
    }
    
    var timeObserverToken: Any?
    var boundaryObserverToken: Any?
    weak var progressDelegator: VideoProgressDelegate?
    
    func addPeriodicTimeObserver() {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.02, preferredTimescale: timeScale)
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time,
                                                           queue: .main) {
                                                            [weak self] time in
                                                            guard let currentItem = self?.player?.currentItem else {return}
                                                            if self!.player!.timeControlStatus == .playing {
                                                                let timeValue = CGFloat(time.value)/CGFloat(time.timescale)*CGFloat(currentItem.duration.timescale)
                                                                // update player transport UI
                                                                self?.progressDelegator?.onProgressChanged(progress: timeValue/CGFloat(currentItem.duration.value))
                                                            }
        }
        
        boundaryObserverToken = player?.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: 0.00001, preferredTimescale: timeScale))], queue: DispatchQueue.main, using: {
            self.previewView.isHidden = true
        })
    }
    
    func showLoading(_ show: Bool) {
        print("showLoading: \(show)")
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        if let observer = boundaryObserverToken {
            player?.removeTimeObserver(observer)
            self.boundaryObserverToken = nil
        }
    }
    
    func seek(toProgress progress: CGFloat) {
        guard let player = self.player, let currentItem = player.currentItem else {
            return
        }
        
        let time = CMTime(value: CMTimeValue(Double(progress*CGFloat(currentItem.duration.value))), timescale: 600)
        player.seek(to: time)
    }

}

func *(progress: CGFloat, duration: CMTime) -> CMTime {
    return CMTime(value: CMTimeValue(progress*CGFloat(duration.value)), timescale: duration.timescale)
}

extension VideoViewController {
    
    func updateTrim(position: VideoTrimPosition) {
        guard let player = player, let currentItem = player.currentItem else { return }
        
        player.seek(toProgress: position.leftTrim)
        currentItem.forwardPlaybackEndTime = position.rightTrim*currentItem.duration
    }
}
