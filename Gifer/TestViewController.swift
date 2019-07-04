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
        
        var livePhotos = [PHAsset]()
        let assets = PHAsset.fetchAssets(with: .image, options: nil)
        assets.enumerateObjects { (asset, _, _) in
            if asset.mediaSubtypes == .photoLive {
                livePhotos.append(asset)
            }
        }
        
        let livePhoto = livePhotos.first!
        print(livePhoto)
        PHImageManager.default().requestLivePhoto(for: livePhoto, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFit, options: nil) { (photo, info) in
            let url = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("livePhoto")
            try! FileManager.default.removeItem(at: url)
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().writeData(for: PHAssetResource.assetResources(for: livePhoto).first { $0.type == PHAssetResourceType.pairedVideo }!, toFile: url, options: options, completionHandler: { (error) in
                
                let asset = AVAsset(url: url)
            })
        }
    }
}

