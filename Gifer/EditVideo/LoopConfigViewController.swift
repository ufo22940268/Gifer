//
//  LoopConfigViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/14.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

enum LoopCount: Int, CustomStringConvertible, CaseIterable {
    case infinite, one, three, five
    
    var description: String {
        switch self {
        case .infinite:
            return "∞"
        case .one:
            return "1次"
        case .three:
            return "3次"
        case .five:
            return "5次"
        }
    }
    
    var count: Int {
        switch self {
        case .infinite:
            return 0
        case .one:
            return 1
        case .three:
            return 3
        case .five:
            return 5
        }
    }
}

class LoopCountCell: DarkTableCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class LoopCountConfigViewController: ConfigViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView
    var selectedLoopCount: LoopCount!
    var loopCounts = LoopCount.allCases

    init(loopCount: LoopCount) {
        let tableView = DarkTableView().useAutoLayout()
        self.tableView = tableView
        super.init(contentView: tableView)
        self.selectedLoopCount = loopCount
        
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LoopCountCell.self, forCellReuseIdentifier: "cell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loopCounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LoopCountCell
        let loopCount = loopCounts[indexPath.row]
        cell.textLabel?.text = loopCount.description
        if loopCount == selectedLoopCount {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLoopCount = loopCounts[indexPath.row]
        tableView.reloadData()
        tableView.cellForRow(at: indexPath)?.isSelected = true
        (presentingViewController as! ShareViewController).loopCount = selectedLoopCount!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true, completion: nil)
            self.interactiveAnimator.finish()
        }
    }
}
