//
//  PlaceInfo.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-19.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlaceInfo: UIView {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 15.0
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1.0)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 4.0
    }

}
