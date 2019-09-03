//
//  DragSession.swift
//  Space-Time-Maps
//
//  Created by Vicky on 19/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// If we begin moving something in the itinerary, it creates one of these sessions

class ItineraryEditingSession: NSObject {
    
    // Consts
    let MIN_DURATION = TimeInterval.from(minutes: 30.0)
    
    // These are set upon initialization, don't change after
    var travelMode : TravelMode
    var baseEvents : [Event] // Ordered list of events NOT containing event being edited --> UNCHANGING!
    var originalIndex : Int
    var callback : ([Event]?, Route?) -> () // TBH this probably shouldn't be set in the construcor, it should be an argument for each public method
    
    // This is what gets modified!
    var movingEvent : Event // Event being edited/moved around
    
    static let scheduler = Scheduler()
    
    init(movingEvent event: Event, withIndex index: Int, inEvents events: [Event], travelMode: TravelMode, callback: @escaping ([Event]?, Route?) -> ()) {
        self.movingEvent = event
        self.baseEvents = events
        self.travelMode = travelMode
        self.callback = callback
        self.originalIndex = index
    }
    
    func moveEvent(toTime time: TimeInterval){
        
        // Make this time the "middle" of the event
        movingEvent.timing.start = time - movingEvent.timing.duration / 2
        movingEvent.timing.end = time + movingEvent.timing.duration / 2
        
        // Create new schedule
        var modifiedEvents = baseEvents
        modifiedEvents.append(movingEvent)
        modifiedEvents.sort(by: { $0.timing.start <= $1.timing.start })
        
        // Compute new route with modifications
        computeRoute()
        
    }
    
    
    func changeEventDuration(with delta: Double) {
        let duration = movingEvent.timing.duration + delta
        guard duration >= MIN_DURATION else { return }
        
        // Shift it downwards from start-time, arbitrary design decision...
        movingEvent.timing.duration = duration
        movingEvent.timing.end = movingEvent.timing.start + movingEvent.timing.duration
        
        // Compute new route with modifications
        computeRoute()
    }
    
    func removeEvent() {
        computeRoute(with: baseEvents)
    }
    
    func end() {
        moveEvent(toTime: movingEvent.timing.start)
    }
    
    func computeRoute() {
        
        // Add movingEvent with whatever changes it may have had to the baseEvents (unchanging events!)
        var modifiedEvents = baseEvents
        modifiedEvents.append(movingEvent)
        modifiedEvents.sort(by: { $0.timing.start <= $1.timing.start })
        computeRoute(with: modifiedEvents)
        
    }
    
    func computeRoute(with events: [Event]) {
        if events.count <= 1 {
            callback(events, [])
        } else {
            ItineraryEditingSession.scheduler.schedule(events: events, travelMode: travelMode, callback: callback)
        }
    }

}
