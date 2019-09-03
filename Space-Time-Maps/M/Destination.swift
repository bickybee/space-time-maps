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
    
    var place : Place
    var timing : Timing
    
    init(place: Place, timing: Timing) {
        self.place = place
        self.timing = timing
        
    }
    
    func copy() -> Event {
        return Destination(place: self.place, timing: self.timing)
    }
}

