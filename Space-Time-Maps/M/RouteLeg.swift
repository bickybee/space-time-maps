//
//  RouteLeg.swift
//  Space-Time-Maps
//
//  Created by Vicky on 16/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

typealias Route = [Leg]

struct Leg : Schedulable {
    
    var polyline : String
    var timing : Timing
}
