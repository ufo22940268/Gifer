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
    
    override func awakeFromNib() {
        backgroundColor = .clear
        textLabel?.textColor = .white
        let bgView = UIView()
        bgView.backgroundColor = .clear
        selectedBackgroundView = bgView
        button.isUserInteractionEnabled = false
        
        button.setTitleColor(.yellowActiveColor, for: .selected)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        button.isSelected = selected
        
        if selected {
            button.imageView?.tintColor = .yellowActiveColor
        } else {
            button.imageView?.tintColor = tintColor
        }
    }
}

protocol GalleryCategoryDelegate: class {
    func onSelectGalleryCategory(_ galleryCategory: GalleryCategory)
}

class GalleryCategoryTableView: UITableView {
    let items = GalleryCategory.allCases
    weak var customDelegate: GalleryCategoryDelegate?
    
    var selectedCategory: GalleryCategory? {
        set(newCategory) {
            selectRow(at: IndexPath(row: items.lastIndex(of: newCategory!)!, section: 0), animated: false, scrollPosition: .middle)
        }
        
        get {
            if let row = indexPathForSelectedRow?.row {
                return items[row]
            } else {
                return nil
            }
        }
    }
    
    override func awakeFromNib() {
        dataSource = self
        backgroundColor = .darkBackground
        separatorStyle = .none
        
        selectedCategory = .video
        delegate = self
        allowsSelection = true
    }
}

extension GalleryCategoryTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GalleryCategoryCell
        let item = items[indexPath.row]
        cell.button.setTitle(item.title, for: [.normal])
        cell.button.setImage(item.icon, for: .normal)
        cell.button.imageView?.contentMode = .scaleAspectFit
        cell.button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 2, bottom: 3, right: 2)
        cell.button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        cell.button.sizeToFit()
        return cell
    }
}

extension GalleryCategoryTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        customDelegate?.onSelectGalleryCategory(items[indexPath.row])
    }
}
