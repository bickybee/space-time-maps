//
//  Destination.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// A place that we are /going/ to at some /time
// I.e. a place with timing aspects to it

class Destination: NSObject {
    
    // Details about the place itself
    var place : Place
    
    // Timing details about this destination, to be rendered accordingly
    var startTime : Date // point at which to render cell
    var duration : Int // height of cell
    
    // Timing constraints provided by the user, which influence the calculated timing details
    //var timeConstraints = TimeConstraints()
    
    
    init(place: Place, startTime: Date) {
        self.place = place
        self.startTime = startTime
        self.duration = 1
    }
    
}

