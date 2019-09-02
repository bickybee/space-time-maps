//
//  DragSession.swift
//  Space-Time-Maps
//
//  Created by Vicky on 19/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryEditingSession: NSObject {
    
    var travelMode : TravelMode
    var baseEvents : [Event]
    var movingEvent : Event
    var originalIndex : Int
    var callback : ([Event]?, Route?) -> ()
    
    static let scheduler = Scheduler()
    
    init(movingEvent event: Event, withIndex index: Int, inEvents events: [Event], travelMode: TravelMode, callback: @escaping ([Event]?, Route?) -> ()) {
        self.movingEvent = event
        self.baseEvents = events
        self.travelMode = travelMode
        self.callback = callback
        self.originalIndex = index
    }
    
    func moveEvent(toTime time: TimeInterval){
                
        var modifiedEvents = baseEvents
        movingEvent.timing.start = time - movingEvent.timing.duration / 2
        movingEvent.timing.end = time + movingEvent.timing.duration / 2
        modifiedEvents.append(movingEvent)
        modifiedEvents.sort(by: { $0.timing.start <= $1.timing.start })
        computeRoute(with: modifiedEvents)
        
    }
    
    
    func changeEventDuration(with delta: Double) {
        let duration = movingEvent.timing.duration + delta
        guard duration >= TimeInterval.from(minutes: 30.0) else { return }
//        let event = movingEvent.copy()
        movingEvent.timing.duration = duration
        movingEvent.timing.end = movingEvent.timing.start + movingEvent.timing.duration
        var modifiedEvents = baseEvents
        modifiedEvents.append(movingEvent)
        modifiedEvents.sort(by: { $0.timing.start <= $1.timing.start })
        computeRoute(with: modifiedEvents)
    }
    
    func removeEvent() {
        computeRoute(with: baseEvents)
    }
    
    func end() {
        moveEvent(toTime: movingEvent.timing.start)
    }

    
    func computeRoute(with events: [Event]) {
        if events.count <= 1 {
            callback(events, [])
        } else {
//            var destinations = [Destination]()
//            events.forEach({ event in
//                if let dest = event as? Destination {
//                    destinations.append(dest)
//                } else if let group = event as? OneOfBlock {
//                    let dest = Destination(place: group.places[0], timing: group.timing, constraints: Constraints())
//                    destinations.append(dest)
//                }
//            })
            ItineraryEditingSession.scheduler.schedule(events: events, travelMode: travelMode, callback: callback)
        }
    }

}
