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
        schedDests = destinations.map( { return $0.copy() })
        schedLegs = [Leg]()
        
        // First, find a seed constraint
        var seedIndex : Int
        if let constrainedIndex = destinations.firstIndex(where: { $0.hasConstraints() }) {
            print("seed found")
            seedIndex = constrainedIndex
        } else {
            print("no seed")
            seedIndex = 0
        }
        
        scheduleEvents(seededAt: seedIndex) {
            DispatchQueue.main.async {
                callback(self.schedDests, self.schedLegs)
            }
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
            let minStartTime = destA.timing.start + destA.timing.duration + leg.timing.duration
            let nextDestA = destB.copy()
            if nextDestA.timing.start < minStartTime {
                nextDestA.timing.start = minStartTime
            }
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
            
            let maxStartTime = destB.timing.start - destA.timing.duration - leg.timing.duration
            let nextDestA = destA.copy()
            if nextDestA.timing.start > maxStartTime {
                nextDestA.timing.start = maxStartTime
            }
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
    
    // Assume all are "fully constrained"
    func schedule2(destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination], Route) -> ()) {
        
        // Member variables... (easy access within closures)
        schedDests = destinations.map( { return $0.copy() })
        schedLegs = [Leg]()
        
        var i = 0
        var destA = schedDests[0]
        var destB = schedDests[1]
        var legCallback : ((Leg?) -> ())!
        
        // Setup callback
        legCallback = { leg in
            var leg = leg!
            leg.timing.start = destA.timing.end
            self.schedLegs.append(leg)
            
            i += 1
            let minStartTime = destA.timing.end + leg.timing.duration
            let nextDestA = destB.copy()
            if nextDestA.timing.start < minStartTime {
                nextDestA.timing.start = minStartTime
            }
            self.schedDests[i] = nextDestA
            
            if i == self.schedDests.count - 1 {
                DispatchQueue.main.async {
                    callback(self.schedDests, self.schedLegs)
                }
            } else {
                destA = self.schedDests[i]
                destB = self.schedDests[i + 1]
                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
                
            }
        }
        
        // Begin recursive callback hell!
        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)

    }
    
}



