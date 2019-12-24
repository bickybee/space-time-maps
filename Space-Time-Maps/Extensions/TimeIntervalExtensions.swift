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
    
    func toDate() -> Date? {
        let totalMinutes = self.inMinutes()
        let hour = floor(totalMinutes / 60.0)
        let minute = totalMinutes - (hour * 60)
        var components = DateComponents()
        components.hour = Int(hour)
        components.minute = Int(minute)
        
        let calendar = Calendar.current
        return calendar.date(from: components)
    }
    
}
