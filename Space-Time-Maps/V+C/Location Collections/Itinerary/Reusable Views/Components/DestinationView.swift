//
//  DestinationView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DestinationView: IBView {

    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override var nibName : String! {
        return "DestinationView"
    }
    
}
