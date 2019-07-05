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
        setup()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        textLabel?.textColor = .white
        
        selectedBackgroundView = UIView()
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
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .dark
        tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 1)))
        separatorStyle = .none
    }
}
