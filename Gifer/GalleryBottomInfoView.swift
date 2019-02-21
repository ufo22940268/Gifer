//
//  GalleryBottomInfoView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/21.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GalleryBottomInfoView: UICollectionReusableView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    var videoInfoView: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        videoInfoView = UILabel()
        videoInfoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(videoInfoView)
        NSLayoutConstraint.activate([
            videoInfoView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            videoInfoView.centerXAnchor.constraint(equalTo: centerXAnchor)])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setVideoCount(_ count: Int) {
        if count == 0 {
            isHidden = true
        } else {
            isHidden = false
            videoInfoView.text = "\(count)个视频"
        }
    }
}
