//
//  IBView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// Superclass to store common funcionality of all UIViews loaded from XIBs

class IBView: UIView {

    @IBOutlet var contentView: UIView!
    var nibName: String! {
        fatalError("Must Override")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        Bundle.main.loadNibNamed(nibName, owner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
    }

}
