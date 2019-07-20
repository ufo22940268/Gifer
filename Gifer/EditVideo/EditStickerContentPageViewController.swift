//
//  EditStickerContentPageViewController.swift
//  Gifer
//
//  Created by Frank Cheng on 2019/7/19.
//  Copyright © 2019 Frank Cheng. All rights reserved.
//

import UIKit

typealias EditStickerLoader = () -> UIImage

protocol EditStickerPageDelegate: class {
    func onPageTransition(to index: Int)
}

class EditStickerPageViewController: UIPageViewController {
    
    var vcs: [UIViewController]?
    weak var customDelegate: EditStickerPageDelegate?
    
    lazy var emojiVC: UIViewController = {
        let vc = storyboard?.instantiateViewController(withIdentifier: "StickerCollection") as! EditStickerCollectionViewController
        vc.setLoaders(emojiImageCharacters.map {char in
            return {
                return String(char).image()
            }
        })
        return vc
    }()
    
    lazy var cuppyVC: UIViewController = {
        let vc = storyboard?.instantiateViewController(withIdentifier: "StickerCollection") as! EditStickerCollectionViewController
        vc.setLoaders(cuppyImageNames.map { imageName in
            return { UIImage(named: imageName)! }
        })
        return vc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        
        vcs = [UIViewController]()
        vcs?.append(emojiVC)
        vcs?.append(cuppyVC)
        
        setViewControllers([vcs!.first!], direction: .forward, animated: true, completion: nil)
    }
    
    func transition(to index: Int) {
        guard let vcs = vcs else { return }
        setViewControllers(Array(vcs[index...index]), direction: vcs.firstIndex(of: viewControllers!.first!)! < index ? .forward: .reverse, animated: true, completion: nil)
    }
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

extension EditStickerPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = viewControllers?.first else { return }
        let index = vcs!.firstIndex(of: viewController)!
        customDelegate?.onPageTransition(to: index)
    }
}
