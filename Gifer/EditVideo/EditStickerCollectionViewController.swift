//
//  EditStickerCollectionViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"
let emojiImageCharacters = [0x1F601...0x1F64F]
    .flatMap { $0 }
    .compactMap { Unicode.Scalar($0) }
    .map(Character.init)

class EditStickerCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
}

protocol EditStickerCollectionDelegate: class {
    func onSelected(sticker: UIImage)
}

class EditStickerCollectionViewController: UICollectionViewController {
    
    var loaders: [EditStickerLoader]?
    
    weak var customDelegate: EditStickerCollectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(EditStickerCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    func setLoaders(_ loaders: [EditStickerLoader]) {
        self.loaders = loaders
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loaders?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! EditStickerCell
    
        // Configure the cell
        let image = loaders?[indexPath.row]()
        cell.imageView.image = image
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        customDelegate?.onSelected(sticker: loaders![indexPath.row]())
    }
}
