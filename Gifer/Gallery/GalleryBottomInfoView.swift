//
//  GalleryBottomInfoView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/21.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GalleryBottomInfoView: UICollectionReusableView {

    var videoInfoView: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        videoInfoView = UILabel()
        videoInfoView.textColor = UIColor.lightText
        videoInfoView.font = UIFont.systemFont(ofSize: UIFont.systemFontSize + 2, weight: .bold)
        videoInfoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(videoInfoView)
        NSLayoutConstraint.activate([
            videoInfoView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2.5),
            videoInfoView.centerXAnchor.constraint(equalTo: centerXAnchor)])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setVideoCount(_ count: Int, category: String) {
        if count == 0 {
            isHidden = true
        } else {
            isHidden = false
            videoInfoView.text = "\(count)个\(category)"
        }
    }
}
