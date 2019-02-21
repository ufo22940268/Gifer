//
//  SelectGifDurationViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/2/20.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class SelectGifDurationTableCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SelectGifDurationViewController: UITableViewController {
    
    var durations = [Int]()
    var selectedDuration: Int!
    
    var selectedIndex: Int {
        return durations.firstIndex(of: selectedDuration)!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
//         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        selectedDuration = UserDefaults.standard.integer(forKey: UserDefaultKeys.gifMaxDuration.rawValue)
        for i in stride(from: 8, to: 17, by: 2) {
            durations.append(i)
        }
        tableView.register(SelectGifDurationTableCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return durations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SelectGifDurationTableCell

        cell.textLabel?.text = "\(durations[indexPath.row])s"
        if selectedIndex == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedDuration = durations[indexPath.row]
        UserDefaults.standard.set(selectedDuration, forKey: UserDefaultKeys.gifMaxDuration.rawValue)
        tableView.reloadData()
        
        dismiss(animated: true, completion: nil)
    }
}
