//
//  GalleryCategoryTableView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/4.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GalleryCategoryCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
}

class GalleryCategoryTableView: UITableView {
    let items = GalleryCategory.allCases
    
    override func awakeFromNib() {
        dataSource = self
    }
}

extension GalleryCategoryTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GalleryCategoryCell
        let item = items[indexPath.row]
        cell.button.setTitle(item.title, for: .normal)
        return cell
    }
}
