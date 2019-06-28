//
//  FramesViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import AVKit

class FramesViewController: UIViewController {
    
    var playerItem: ImagePlayerItem!
    var frames: [ImagePlayerFrame] {
        return playerItem.frames
    }
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        
        if isInitial() {
            let directory = (try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)).appendingPathComponent("imagePlayer")
            let paths = (try! FileManager.default.contentsOfDirectory(atPath: directory.path)).map { URL(fileURLWithPath: $0) }
            let frames = paths.map { (path: URL) -> ImagePlayerFrame in
                var frame = ImagePlayerFrame(time: .zero)
                frame.path = path
                return frame
            }
            playerItem = ImagePlayerItem(frames: frames, duration: CMTime(seconds: 3, preferredTimescale: 600))
        }

        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let width: CGFloat = collectionView.bounds.width/4 - 3*4
        flowLayout.itemSize = CGSize(width: width, height: width)
    }
}

extension FramesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playerItem != nil ? frames.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        cell.image.image = #imageLiteral(resourceName: "01_Cuppy_smile.png")
        return cell
    }
}
