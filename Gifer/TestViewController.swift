//
//  TestViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/3/27.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos

class TestViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let v1 = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        v1.backgroundColor = .yellow
        
        let v2 = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        v2.backgroundColor = .red
        
        view.addSubview(v1)
        
        UIView.transition(with: v1, duration: 3, options: [], animations: {
            v1.addSubview(v2)
        }, completion: nil)
        
//        var livePhotos = [PHAsset]()
//        let assets = PHAsset.fetchAssets(with: .image, options: nil)
//        assets.enumerateObjects { (asset, _, _) in
//            if asset.mediaSubtypes == .photoLive {
//                livePhotos.append(asset)
//            }
//        }
//        
//        let livePhoto = livePhotos.first!
//        print(livePhoto)
//        PHImageManager.default().requestLivePhoto(for: livePhoto, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFit, options: nil) { (photo, info) in
//            let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("livePhoto")
//            try! FileManager.default.removeItem(at: url)
//            let options = PHAssetResourceRequestOptions()
//            options.isNetworkAccessAllowed = true
//            PHAssetResourceManager.default().writeData(for: PHAssetResource.assetResources(for: livePhoto).first { $0.type == PHAssetResourceType.pairedVideo }!, toFile: url, options: options, completionHandler: { (error) in                
//            })
//        }
    }
}

