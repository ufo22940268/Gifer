//
//  EditViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2018/11/12.
//  Copyright © 2018 Frank Cheng. All rights reserved.
//

import Foundation
import UIKit

class EditViewController: UIViewController {
    
    var videoVC: VideoViewController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {        
        if segue.identifier == "emberVideo" {
            videoVC = segue.destination as? VideoViewController
        }
    }
}
