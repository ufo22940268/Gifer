//
//  StickerMenuView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/6.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class StickerMenuView: UICollectionView {
    
    lazy var stickerImages: [UIImage] = [
        #imageLiteral(resourceName: "01_Cuppy_smile.png")
    ]
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 62, height: 62)
        super.init(frame: frame, collectionViewLayout: flowLayout)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70)
            ])
        translatesAutoresizingMaskIntoConstraints = false
        
        dataSource = self
        backgroundColor = #colorLiteral(red: 0.0862745098, green: 0.09019607843, blue: 0.09411764706, alpha: 1)
        
        register(StickerMenuItemView.self, forCellWithReuseIdentifier: "cell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentInset.top = (bounds.height - contentSize.height)/2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension StickerMenuView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StickerMenuItemView
        cell.setImage(stickerImages[indexPath.row])
        return cell
    }
}

class StickerMenuItemView: UICollectionViewCell {
    
    let imageView: UIImageView!
    
    override init(frame: CGRect) {
        imageView = UIImageView()
        super.init(frame: frame)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1.0)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setImage(_ image: UIImage) {
        imageView.image = image
    }
}
