//
//  TimeIntervalExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 15/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

extension TimeInterval {
    
    static func from(hours: Double) -> TimeInterval {
        return hours * 3600.0
    }
    
    static func from(hours: Int) -> TimeInterval {
        return Double(hours) * 3600.0
    }
    
    static func from(minutes: Double) -> TimeInterval {
        return minutes * 60.0
    }
    
    static func from(minutes: Int) -> TimeInterval {
        return Double(minutes) * 60.0
    }
    
    func inHours() -> Double {
        return self / 3600.0
    }
    
    func inMinutes() -> Double {
        return self / 60.0
    }
    
}
