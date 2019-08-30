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

class Destination: Event {
    
    // Details about the place itself
    var place : Place
    
    // Timing details about this destination, to be rendered accordingly
    // Relative to today, for simplicity, since we only provide 1-day views
    var timing : Timing
    
    // Timing constraints provided by the user, which influence the calculated timing details
    var constraints : Constraints//var timeConstraints = TimeConstraints()
    
    init(place: Place, timing: Timing, constraints: Constraints) {
        
        self.place = place
        self.timing = timing
        self.constraints = constraints
        
    }
    
    func hasConstraints() -> Bool {
        return constraints.areEnabled
    }
    
    func copy() -> Destination {
        return Destination(place: self.place, timing: self.timing, constraints: self.constraints)
    }
}

