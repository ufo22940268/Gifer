//
//  CameraViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/9/2.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit


class CameraViewController: UIViewController {
    
    var types: [CameraType] = CameraType.allCases

    @IBOutlet weak var labelCollectionView: UICollectionView!
    @IBOutlet weak var shotView: ShotView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DarkMode.enable(in: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (labelCollectionView.visibleCells.first { (cell) -> Bool in
            labelCollectionView.indexPath(for: cell)?.row == 0
        } as? CameraTypeCell)?.isHighlighted = true
    }
    
    override func viewDidLayoutSubviews() {
        let itemWidth = (labelCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width
        labelCollectionView.contentInset = .init(top: 0, left: (view.bounds.width - itemWidth)/2, bottom: 0, right: (view.bounds.width - itemWidth)/2)
    }
    
    func nothingChanges() -> Bool {
        return true
    }
    
    @IBAction func onResetCamera(_ sender: Any) {
        print("onResetCamera")
        shotView.resetRecording()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        if nothingChanges() {
            dismiss(animated: true, completion: nil)
        } else {
            // TODO: Prompt for dimissing changes.
        }
    }
    
    @IBAction func onDone(_ sender: Any) {
    }
}

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return types.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CameraTypeCell
        let type = types[indexPath.row]
        cell.labelView.text = type.title
        return cell
    }
}

extension CameraViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentIndex = labelCollectionView.indexPathForItem(at: CGPoint(x: labelCollectionView.contentOffset.x + labelCollectionView.frame.width/2, y: labelCollectionView.frame.height/2))
        labelCollectionView.visibleCells.forEach { (cell) in
            let cell = cell as! CameraTypeCell
            cell.isHighlighted = labelCollectionView.indexPath(for: cell) == currentIndex
        }
    }
}


enum CameraType: CaseIterable {
    case video
    case photos
    
    var title: String {
        switch self {
        case .video:
            return NSLocalizedString("camera_video", comment: "")
        case .photos:
            return NSLocalizedString("camera_photos", comment: "")
        }
    }
}

class CameraTypeCell: UICollectionViewCell {
    
    @IBOutlet weak var labelView: UILabel!
    
    override var isHighlighted: Bool {
        didSet {
            labelView.textColor = isHighlighted ? .white : .lightText
        }
    }
}
