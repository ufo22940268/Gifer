//
//  DarkTable.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/5/8.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit


class DarkTableCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        textLabel?.textColor = .white
        
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .yellow
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            selectedBackgroundView?.backgroundColor = .black
        } else {
            selectedBackgroundView?.backgroundColor = .dark
        }
    }
}


class DarkTableView: UITableView {
    init() {
        super.init(frame: .zero, style: .plain)
        backgroundColor = .dark
        tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 1)))
        separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
