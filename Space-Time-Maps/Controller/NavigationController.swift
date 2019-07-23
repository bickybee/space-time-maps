//
//  MyNavigationController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-20.
//  Copyright © 2019 vicky. All rights reserved.
//

// Hide back text on all navbars
// https://stackoverflow.com/questions/23853617/uinavigationbar-hide-back-button-text

import UIKit

class MyNavigationController: UINavigationController, UINavigationControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    // FIXME: - Although invisible, still gets in the way of taps
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let item = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        viewController.navigationItem.backBarButtonItem = item
        if let navBar = viewController.navigationController?.navigationBar {
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()
            navBar.isTranslucent = true
            
        }
    }
}
