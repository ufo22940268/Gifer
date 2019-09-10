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
    
    lazy var reloadButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Refresh", comment: ""), for: .normal)
        button.setTitleColor(.yellowActiveColor, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        button.addTarget(self, action: #selector(onRefresh), for: .touchUpInside)
        return button
    }()
    
    var customDelegate: GalleryBottomInfoViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView().useAutoLayout()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        
        videoInfoView = UILabel()
        videoInfoView.textColor = UIColor.lightText
        videoInfoView.font = UIFont.preferredFont(forTextStyle: .headline)
        videoInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(videoInfoView)
        stackView.addArrangedSubview(reloadButton)
        
        addSubview(stackView)
        stackView.alignment = .center
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onRefresh() {
        print("onRefresh")
        customDelegate?.onRefresh(self)
    }
    
    func setVideoCount(_ count: Int, category: String, collectionTitle: String?) {
        if count == 0 {
            isHidden = true
        } else {
            isHidden = false
            videoInfoView.text = "\(collectionTitle ?? ""), \(String.localizedStringWithFormat(category, count))"
        }
    }
}


protocol GalleryBottomInfoViewDelegate: class {
    func onRefresh(_ bottomView: GalleryBottomInfoView)
}
