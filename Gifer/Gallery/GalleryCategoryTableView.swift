//
//  GalleryCategoryTableView.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/4.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

class GalleryCategoryCell: DarkTableCell {
    @IBOutlet weak var button: UIButton!
}

class GalleryCategoryTableView: UITableView {
    let items = GalleryCategory.allCases
    
    override func awakeFromNib() {
        dataSource = self
        backgroundColor = .dark
        separatorStyle = .none
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
        cell.button.setImage(item.icon, for: .normal)
        cell.button.imageView?.contentMode = .scaleAspectFit
        cell.button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 2, bottom: 3, right: 2)
        cell.button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        cell.button.sizeToFit()
        return cell
    }
}
