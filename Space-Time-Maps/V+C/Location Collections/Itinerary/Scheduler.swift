//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation


class Scheduler : NSObject {
    
    let qs = QueryService()
    
    var schedDests : [Destination]!
    var schedLegs : [Leg]!
    var travelMode = TravelMode.driving
    
    func schedule(destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination], Route) -> ()) {

        // Member variables... (easy access within closures)
        schedDests = destinations.map( { return Destination(place: $0.place, timing: $0.timing, constraints: Constraints() )})
        schedLegs = [Leg]()
        
        destinations[1].constraints.arrival = Constraint(time: destinations[1].timing.start, flexibility: .hard)
    
        // First, find a seed constraint
        if let seedIndex = destinations.firstIndex(where: { $0.hasConstraints() }) {
            
            // Schedule events propogating outwards from seed
            scheduleEvents(seededAt: seedIndex) {
                DispatchQueue.main.async {
                    callback(self.schedDests, self.schedLegs)
                }
            }
            
        } else {
            print("schedule without constraints?")
        }
        
    }
    
    func scheduleEvents(seededAt index: Int, callback: () -> ()) {
        
        let dispatchGroup = DispatchGroup()
        
        let maxIndex = schedDests.count - 1
        let minIndex = 0
        
        // Propogating forward in time from first constrained event
        if (index < maxIndex) {
            
            dispatchGroup.enter()
            
            scheduleEventsForward(seededAt: index) {
                dispatchGroup.leave()
            }
        }
        
        // Propogating backwards in time
        if (index > minIndex) {
            
            dispatchGroup.enter()
            
            scheduleEventsBackward(seededAt: index) {
                dispatchGroup.leave()
            }
        }
        
        // Callback when it's all done
        dispatchGroup.wait()
        callback()
        
    }
    
    func scheduleEventsForward(seededAt index: Int, callback: @escaping () -> ()) {
        
        var i = index
        var destA = schedDests[index]
        var destB = schedDests[index + 1]
        var legCallback : ((Leg?) -> ())!
        
        // Setup callback
        legCallback = { leg in
            var leg = leg!
            leg.timing.start = destA.timing.start + destA.timing.duration
            self.schedLegs.append(leg)
            
            i += 1
            let nextStartTime = destA.timing.start + destA.timing.duration + leg.timing.duration
            let nextDestA = destB.copy()
            nextDestA.timing.start = nextStartTime
            self.schedDests[i] = nextDestA
            
            if i == self.schedDests.count - 1 {
                callback()
            } else {
                destA = self.schedDests[i]
                destB = self.schedDests[i + 1]
                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)

            }
        }
        
        // Begin recursive callback hell!
        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
    }
    
    func scheduleEventsBackward(seededAt index: Int, callback: @escaping () -> ()) {
        
        var i = index
        var destA = schedDests[index - 1]
        var destB = schedDests[index]
        var legCallback : ((Leg?) -> ())!
    
        // Setup callback
        legCallback = { leg in
            var leg = leg!
            leg.timing.start = destB.timing.start - leg.timing.duration
            self.schedLegs.append(leg)
            
            let nextStartTime = destB.timing.start - destA.timing.duration - leg.timing.duration
            let nextDestA = destA.copy()
            nextDestA.timing.start = nextStartTime
            self.schedDests[i - 1] = nextDestA
            i -= 1
            
            if i == 0 {
                callback()
            } else {
                destA = self.schedDests[i - 1]
                destB = self.schedDests[i]
                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
                
            }
        }
        
        // Begin recursive callback hell!
        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
    }
    
}



