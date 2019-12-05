//
//  Event.swift
//  Space-Time-Maps
//
//  Created by Vicky on 20/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

typealias TimeDict = [ PlacePair : TimeInterval ]

struct PlacePair : Hashable {
    var startID : String
    var endID : String
    var travelMode: TravelMode
}

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
    
    func equals(_ timing: Timing) -> Bool {
        return self.start == timing.start && self.end == timing.end
    }
    
    func contains(_ time: TimeInterval) -> Bool {
        return (start < time) && (end > time)
    }
    
    func containsInclusive(_ time: TimeInterval) -> Bool {
        return (start <= time) && (end >= time)
    }
    
    func fullyContains(_ timing: Timing) -> Bool {
        return (start <= timing.start) && (end >= timing.end)
    }
    
    func intersects(_ timing: Timing) -> Bool {
        return self.equals(timing)
            || self.contains(timing.start)
            || self.contains(timing.end)
            || timing.contains(self.start)
            || timing.contains(self.end)
    }
    
    func offsetBy(_ time: TimeInterval) -> Timing {
        return Timing(start: self.start + time, end: self.end + time)
    }
    
    func withStartShiftedTo(_ startTime: TimeInterval) -> Timing {
        return Timing(start: startTime, end: self.end + (startTime - self.start))
    }
    
    func withEndShiftedTo(_ endTime: TimeInterval) -> Timing {
        return Timing(start: self.start + (endTime - self.end), end: endTime)
    }
    
    func intersectionWith(_ timing: Timing) -> Timing? {
        guard self.intersects(timing) else { return nil }
        // Start by assuming they intersect entirely, thus returning self
        var intersection = Timing(start: self.start, end: self.end)
        // If self contains the other interval's start, we shift the start time of the intersection
        if self.contains(timing.start) {
            intersection.start = timing.start
        }
        // If self contains the other interval's start, we shift the end time of the intersection
        if self.contains(timing.end) {
            intersection.end = timing.end
        }
        
        intersection.duration = intersection.end - intersection.start
        return intersection
    }
    
    
}
