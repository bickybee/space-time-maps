//
//  Schedulables.swift
//  Space-Time-Maps
//
//  Created by Vicky on 05/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

// Building blocks to render/represent the itinerary

protocol Schedulable {
    
    var timing : Timing { get set }
    
}

class Destination: Schedulable {
    
    var place : Place
    var timing : Timing
    
    init(place: Place, timing: Timing) {
        self.place = place
        self.timing = timing
        
    }
    
    func copy() -> Schedulable {
        return Destination(place: self.place, timing: self.timing)
    }
}

typealias Route = [Leg]

struct Leg : Schedulable {
    
    var polyline : String
    var timing : Timing
    var travelTiming : Timing
    
    func copy() -> Schedulable {
        return Leg(polyline: self.polyline, timing: self.timing, travelTiming: self.travelTiming)
    }
    
}

