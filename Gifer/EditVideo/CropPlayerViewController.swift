//
//  CropPlayerViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/10.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class CropPlayerViewController: UIViewController {
    @IBOutlet weak var imagePlayerView: ImagePlayerView!
    @IBOutlet var cropContainer: CropContainer!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var cropArea: CGRect? {
        set(newCropArea) {
            cropContainer.initialCropArea = newCropArea
        }
        
        get {
            return cropContainer.convert(cropContainer.bounds, to: imagePlayerView)
                .applying(CGAffineTransform(scaleX: 1/imagePlayerView.bounds.width, y: 1/imagePlayerView.bounds.height))
        }
    }
    
    var initialCropArea: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        cropContainer.scrollView = scrollView
        cropContainer.imagePlayerView = imagePlayerView
        cropContainer.setup()
        
        cropArea = initialCropArea
    }
    
    func onVideoReady(videoFrame: CGRect) {
        cropContainer.setupVideo(frame: videoFrame)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
