//
//  StickerMenuView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/6.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

struct Sticker {
    var image: UIImage
}

class StickerMenuView: UICollectionView {
    
    lazy var stickerImages: [UIImage] = [
        "01_Cuppy_smile",
        "02_Cuppy_lol",
        "03_Cuppy_rofl",
        "04_Cuppy_sad",
        "05_Cuppy_cry",
        "06_Cuppy_love",
        "07_Cuppy_hate",
        "08_Cuppy_lovewithmug",
        "09_Cuppy_lovewithcookie",
        "10_Cuppy_hmm",
        "11_Cuppy_upset",
        "12_Cuppy_angry",
        "13_Cuppy_curious",
        "14_Cuppy_weird",
        "15_Cuppy_bluescreen",
        "16_Cuppy_angry",
        "17_Cuppy_tired",
        "18_Cuppy_workhard",
        "19_Cuppy_shine",
        "20_Cuppy_disgusting",
        "21_Cuppy_hi",
        "22_Cuppy_bye",
        "23_Cuppy_greentea",
        "24_Cuppy_phone",
        "25_Cuppy_battery"
        ].map{UIImage(named: $0)!}
    
    weak var customDelegate: StickerMenuDelegate?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 62, height: 62)
        flowLayout.scrollDirection = .horizontal
        super.init(frame: frame, collectionViewLayout: flowLayout)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 70)
            ])
        translatesAutoresizingMaskIntoConstraints = false
        
        dataSource = self
        delegate = self
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

extension StickerMenuView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = stickerImages[indexPath.row]
        customDelegate?.onSelect(sticker: Sticker(image: image))
    }
}

protocol StickerMenuDelegate: class {
    func onSelect(sticker: Sticker)
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
            imageView.heightAnchor.constraint(equalToConstant: 62),
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
