//
//  FramePreviewViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/6/29.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

protocol FramePreviewDelegate: class {
    func onCheck(index: Int, actived: Bool)
}

class FramePreviewViewController: UIViewController {

    @IBOutlet weak var checkItem: UIBarButtonItem!
    @IBOutlet weak var previewView: UIImageView!
    
    weak var delegate: FramePreviewDelegate?
    var index: Int!
    
    var sequence: Int? {
        didSet {
            navigationItem.title = sequence == nil ? "" : String(sequence!)
        }
    }
    
    var isActive: Bool! {
        didSet {
            if isActive {
                checkItem.image = #imageLiteral(resourceName: "check-circle-solid.png")
                checkItem.tintColor = view.tintColor
            } else {
                checkItem.image = #imageLiteral(resourceName: "check-circle-regular.png")
                checkItem.tintColor = .lightText
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DarkMode.enable(in: self)
        view.backgroundColor = UIColor(named: "darkBackgroundColor")
        view.tintColor = .yellowActiveColor
        navigationController?.view.tintColor = .yellowActiveColor
        // Do any additional setup after loading the view.
        
        isActive = false
    }
    
    
    @IBAction func onDismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCheck(_ sender: Any) {
        isActive = !isActive
        delegate?.onCheck(index: index, actived: isActive)
    }
}
