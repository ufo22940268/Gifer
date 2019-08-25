//
//  AlbumViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/8/5.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit
import Photos
import AVKit

class AlbumCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    override func awakeFromNib() {
        let colorView = UIView()
        colorView.backgroundColor = #colorLiteral(red: 0.08100000024, green: 0.08100000024, blue: 0.08100000024, alpha: 1)
        selectedBackgroundView = colorView
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

protocol AlbumViewControllerDelegate: class {
    func onUpdateFetchOptions(localIdentifier: String?, localizedTitle: String?)
}

class AlbumViewController: UITableViewController {
    
    var collections: [PHAssetCollection]?
    
    weak var customDelegate: AlbumViewControllerDelegate?
    
    var initialCollectionIdentifier: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        DarkMode.enable(in: self)
        view.backgroundColor = .darkBackground        
        
        self.clearsSelectionOnViewWillAppear = true
        let footerView: UIView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 1)))
        tableView.backgroundColor = .darkContent
        tableView.tableFooterView = footerView
        tableView.rowHeight = 70
        loadData()
    }

    @IBAction func onDismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadData() {
        let options = PHFetchOptions()

        var collections = [PHAssetCollection]()
        let subtypes: [PHAssetCollectionSubtype] = [.smartAlbumUserLibrary, .smartAlbumFavorites]
        for subtype in subtypes {
            if let col = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil).firstObject {
                collections.append(col)
            }
        }
        
        PHAssetCollection.fetchTopLevelUserCollections(with: options).enumerateObjects { (col, _, _) in
            if let col = col as? PHAssetCollection {
                collections.append(col)
            }
        }
        self.collections = collections
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let index = self.collections?.firstIndex(where: { $0.localIdentifier == initialCollectionIdentifier }) {
            self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if cell.tag != 0 {
            PHImageManager.default().cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        
        let imageSize = CGSize(width: 55, height: 55)
        let col = collections![indexPath.row]
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.cornerRadius = 4
        if let asset = PHAsset.fetchAssets(in: col, options: nil).firstObject {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.resizeMode = .exact
            let requestId = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: imageSize.width*UIScreen.main.scale, height: imageSize.height*UIScreen.main.scale), contentMode: .aspectFill, options: options) { (uiImage, _) in
                cell.imageView?.image = uiImage?.center(in: CGRect(origin: .zero, size: imageSize ))
            }
            cell.tag = Int(requestId)
        } else {
            let canvasSize = imageSize
            cell.imageView?.clipsToBounds = true
            cell.imageView?.image = UIGraphicsImageRenderer(size: canvasSize).image(actions: { (context) in
                let image = #imageLiteral(resourceName: "Image Placeholder.png")
                image.draw(in: CGRect(origin: .zero, size: canvasSize))
                
            })
        }
        
        cell.textLabel?.textColor = .lightText
        cell.textLabel?.font = .systemFont(ofSize: 19, weight: .semibold)
        cell.textLabel?.text = col.localizedTitle
        cell.detailTextLabel?.textColor = .lightText
        var imageCount: Int = 0
        if col.assetCollectionType == .smartAlbum {
            imageCount = PHAsset.fetchAssets(in: col, options: nil).count
        } else {
            imageCount = col.estimatedAssetCount == NSNotFound ? 0 : col.estimatedAssetCount
        }
        cell.detailTextLabel?.text = "\(imageCount)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let col = collections![indexPath.row]
        self.customDelegate?.onUpdateFetchOptions(localIdentifier: col.localIdentifier, localizedTitle: col.localizedTitle)
        navigationController?.popViewController(animated: true)
    }
}
