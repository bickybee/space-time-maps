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

class Destination: Schedulable {
    
    // Details about the place itself
    public var place : Place
    
    // Timing details about this destination, to be rendered accordingly
    // Relative to today, for simplicity, since we only provide 1-day views
    public var startTime : TimeInterval // point at which to render cell
    public var duration : TimeInterval // height of cell
    
    // Timing constraints provided by the user, which influence the calculated timing details
    //var timeConstraints = TimeConstraints()
    
    init(place: Place, startTime: TimeInterval) {
        self.place = place
        self.startTime = startTime
        self.duration = TimeInterval.from(minutes: 30.0)
    }
    
}

