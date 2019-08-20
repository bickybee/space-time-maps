//
//  Event.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

struct Timing {
    
    var start : TimeInterval
    var duration : TimeInterval
    var end : TimeInterval
    
    init(start: TimeInterval, end: TimeInterval) {
        self.start = start
        self.end = end
        self.duration = end - start
    }
    
    init(start: TimeInterval, duration: TimeInterval) {
        self.start = start
        self.duration = duration
        self.end = start + duration
    }
    
    init(end: TimeInterval, duration: TimeInterval) {
        self.end = end
        self.duration = duration
        self.start = end - duration
    }
    
    
}
