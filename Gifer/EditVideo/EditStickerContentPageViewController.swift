//
//  EditStickerContentPageViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

typealias EditStickerLoader = () -> UIImage

class EditStickerPageViewController: UIPageViewController {
    
    var  vcs: [UIViewController]?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        // Do any additional setup after loading the view.
        vcs = (0..<3).map { i in
            let vc = storyboard?.instantiateViewController(withIdentifier: "StickerCollection") as! EditStickerCollectionViewController
            vc.setLoaders([
                { "😀".image() }
                ])
            return vc
        }
        
        setViewControllers([vcs!.first!], direction: .forward, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EditStickerPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vcs = vcs else { return nil }
        let index = vcs.firstIndex(of: viewController)!
        if vcs.indices.contains(index - 1) {
            return vcs[index - 1]
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vcs = vcs else { return nil }
        let index = vcs.firstIndex(of: viewController)!
        if vcs.indices.contains(index + 1) {
            return vcs[index + 1]
        } else {
            return nil
        }
    }
    
    
}
