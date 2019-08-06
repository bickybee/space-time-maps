//
//  Route.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-19.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

struct Leg {
    var duration : Int
}

class Route : NSObject {
    
    var polyline : String
    var duration : Int // seconds
    var legs: [Leg]
    
    init(polyline: String, duration: Int, legs: [Leg]) {
        self.polyline = polyline
        self.duration = duration
        self.legs = legs
    }
    
}

