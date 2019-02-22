//
//  GifOverlayViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/23.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GifOverlayViewController: UIViewController {
    
    @IBOutlet weak var overlayEditView: GifOverlayEditView!
    @IBOutlet weak var overlayRenderer: GifOverlayRenderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overlayRenderer.addSticker(image: #imageLiteral(resourceName: "01_Cuppy_smile.png"), editable: true)
        

        // Do any additional setup after loading the view.
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
