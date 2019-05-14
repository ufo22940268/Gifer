//
//  LoopConfigViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/14.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class LoopConfigViewController: ConfigViewController {
    
    var tableView: UITableView

    init() {
        let tableView = DarkTableView().useAutoLayout()
        self.tableView = tableView
        super.init(contentView: tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
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
