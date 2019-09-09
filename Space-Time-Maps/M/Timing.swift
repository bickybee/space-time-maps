//
//  Event.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

protocol Schedulable {
    var timing : Timing { get set }
}

struct Timing {
    
    var start : TimeInterval = 0
    var duration : TimeInterval = 0
    var end : TimeInterval = 0
    
    init() {}
    
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
    
    init (start: TimeInterval, end: TimeInterval, duration: TimeInterval) {
        self.start = start
        self.end = end
        self.duration = duration
    }
    
    
}
