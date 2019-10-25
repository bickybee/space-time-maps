//
//  TravelTimeCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 24/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit
import ChameleonFramework

class TravelTimeCell: UICollectionViewCell {
    
    @IBOutlet weak var travelTimeIndicator: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    func configureWith(_ leg: Leg) {
        print(travelTimeIndicator.bounds.height)
        let colors = [leg.startPlace.color, leg.endPlace.color]
        let frame = CGRect(x: travelTimeIndicator.frame.minX,
                           y: travelTimeIndicator.frame.minY,
                           width: travelTimeIndicator.frame.width,
                           height: travelTimeIndicator.frame.height)
        let gradient = GradientColor(.topToBottom, frame: frame, colors: colors)
        travelTimeIndicator.backgroundColor = gradient
        timeLabel.text = Utils.secondsToString(seconds: leg.travelTiming.duration)
    }
    
    override func prepareForReuse() {
        travelTimeIndicator.backgroundColor = .clear
        timeLabel.text = ""
    }
    
}

