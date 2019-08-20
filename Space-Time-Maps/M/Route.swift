//
//  Route.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-19.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

struct Leg : Schedulable {
    var polyline : String
    var duration : TimeInterval
    var startTime : TimeInterval
}

//class Route : NSObject {
//
//    var duration : TimeInterval // seconds
//    var legs: [Leg] {
//        didSet {
//            legs.sort(by: { $0.startTime < $1.startTime })
//        }
//    }
//
//    init(legs: [Leg]) {
//        self.legs = legs
//        self.duration = 0
//        for leg in legs {
//            self.duration += leg.duration
//        }
//    }
//}

