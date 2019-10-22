//
//  PaddedDestinationView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PaddedDestinationView: IBView {

    @IBOutlet weak var destinationView: DestinationView!
    override var nibName: String! {
        return "PaddedDestinationView"
    }

}
