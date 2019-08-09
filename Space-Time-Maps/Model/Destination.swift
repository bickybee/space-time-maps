//
//  Destination.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// A place that we are /going/ to at some /time
// I.e. a place with timing aspects to it

class Destination: NSObject {
    
    private static let calendar = Calendar.current
    private static let todayComponents = calendar.dateComponents([.day, .month, .year], from: Date())
    private static let todayDate = calendar.date(from: todayComponents)
    
    // Details about the place itself
    public var place : Place
    
    // Timing details about this destination, to be rendered accordingly
    // Relative to today, for simplicity, since we only provide 1-day views
    public var startTime : Int // point at which to render cell
    public var duration : Int // height of cell
    
    // For API calls...
    public var absoluteStartTime : Date {
        let todayAtHour = Destination.calendar.date(bySetting: .hour, value: startTime, of: Destination.todayDate!)
        return todayAtHour!
    }
    
    // Timing constraints provided by the user, which influence the calculated timing details
    //var timeConstraints = TimeConstraints()
    
    init(place: Place, startTime: Int) {
        self.place = place
        self.startTime = startTime
        self.duration = 1
    }
    
}

