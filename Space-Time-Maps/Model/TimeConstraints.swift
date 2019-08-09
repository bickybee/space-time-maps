//
//  TimeConstraints.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

let SECONDS_PER_MINUTE : Double = 60
let MINUTES_PER_HOUR : Double = 60
let HOURS_PER_DAY : Double = 24

class TimeConstraints: NSObject {
    
    var arrivalTime : Date?
    var departureTime : Date?
    var duration : TimeInterval
    
    override init() {
        duration = 1 * SECONDS_PER_MINUTE * MINUTES_PER_HOUR
    }

}
