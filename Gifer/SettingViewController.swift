//
//  SettingViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {

    @IBOutlet weak var gifMaxDurationView: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let footView = UIView()
        tableView.tableFooterView = footView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let duration = UserDefaults.standard.integer(forKey: UserDefaultKeys.gifMaxDuration.rawValue)
        gifMaxDurationView.text = "\(duration)s"
    }
}
