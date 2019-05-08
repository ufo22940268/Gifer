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
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            contentView.backgroundColor = .black
        } else {
            contentView.backgroundColor = .dark
        }
    }
    
}
