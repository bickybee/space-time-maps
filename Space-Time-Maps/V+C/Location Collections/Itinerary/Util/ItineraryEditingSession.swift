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
    var originalBaseBlocks : [ScheduleBlock]
    var baseBlocks : [ScheduleBlock] // Ordered list of blocks NOT containing block being edited --> UNCHANGING!
    var callback : ([ScheduleBlock]?, Route?) -> () // TBH this probably shouldn't be set in the construcor, it should be an argument for each public method
    
    // This is what gets modified!
    var movingBlock : ScheduleBlock // Block being edited/moved around
    var lastPosition : Int?
    var overlapsClosedHoursOfPlaces = [TimeInterval]()
    
    var scheduler : Scheduler
    
    init(scheduler: Scheduler, movingBlock block: ScheduleBlock, withIndex index: Int?, inBlocks blocks: [ScheduleBlock], travelMode: TravelMode, callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        self.movingBlock = block
        self.baseBlocks = blocks
        self.baseBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        self.originalBaseBlocks = self.baseBlocks.map{ $0.copy() }
        
        self.travelMode = travelMode
        self.callback = callback
        self.lastPosition = index
        self.scheduler = scheduler
        
        super.init()
        self.overlapsClosedHoursOfPlaces = intersectsClosedHours(movingBlock)
    }
    
    func moveBlock(toTime time: TimeInterval){
        
        // Make this time the "middle" of the block
        var movedBlock = movingBlock.copy()
        movedBlock.timing.start = time - movedBlock.timing.duration / 2
        movedBlock.timing.end = time + movedBlock.timing.duration / 2

        // Create new schedule
        var modifiedBlocks = originalBaseBlocks.map{ $0.copy() }
        var insertAt = modifiedBlocks.endIndex
        for (i, block) in modifiedBlocks.enumerated() {
            
            if block.timing.start >= movedBlock.timing.start {
                insertAt = i
                break
            }
            
        }
        
        // A changed block order /or/ a change in overlaps with closed hours requires a full reschedule.
        let changedOrder = true//(insertAt != lastPosition)
//            let changedClosedHoursIntersections = closedHoursIntersections != overlapsClosedHoursOfPlaces
//            overlapsClosedHoursOfPlaces = closedHoursIntersections
        modifiedBlocks.insert(movedBlock, at: insertAt)
        movingBlock = movedBlock
        lastPosition = insertAt

        if changedOrder {//|| changedClosedHoursIntersections {
                print("reschedule")
                scheduler.reschedule(blocks: modifiedBlocks, movingIndex: insertAt, callback: callback)
                
            } else { // Otherwise just shift, no reschedule
                print("shift")
                scheduler.scheduleShift(blocks: modifiedBlocks, movingBlockIndex: insertAt, callback: callback)
            }
//        }
        
        
    }
    
    func changeBlockTiming(_ timing: Timing) {
        movingBlock.timing = timing
        
        var modifiedBlocks = originalBaseBlocks.map{ $0.copy() }
        modifiedBlocks.append(movingBlock)
        modifiedBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        
        scheduler.schedulePinch(of: movingBlock, withIndex: lastPosition!, in: modifiedBlocks, callback: callback)
    }
    
    
    func changeBlockDuration(with delta: Double) {
        let duration = movingBlock.timing.duration + delta
        guard duration >= MIN_DURATION else { return }
        
        // Shift it downwards from start-time, arbitrary design decision...
        movingBlock.timing.duration = duration
        movingBlock.timing.end = movingBlock.timing.start + movingBlock.timing.duration
        
        var modifiedBlocks = originalBaseBlocks.map{ $0.copy() }
        modifiedBlocks.append(movingBlock)
        modifiedBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        
        scheduler.schedulePinch(of: movingBlock, withIndex: lastPosition!, in: modifiedBlocks, callback: callback)
        
    }
    
    func removeBlock() {
        scheduler.reschedule(blocks: originalBaseBlocks, callback: callback)
        lastPosition = nil
    }
    
    func end() {
        moveBlock(toTime: movingBlock.timing.start)
    }
    
    func intersectsBlocks(_ block: ScheduleBlock) -> Bool {
        
        guard block.destinations.count > 0 else { return false }
        
        for b in originalBaseBlocks {
            guard b.destinations.count > 0 else { continue }
            for d in b.destinations {
                if d.timing.intersects(block.timing) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func intersectsLegs(_ block: ScheduleBlock, in route: Route) -> Bool {
        
        guard block.destinations.count > 0 else { return false }
        
        for dest in block.destinations {
            for leg in route.legs {
                if dest.timing.intersects(leg.travelTiming) {
                    return true
                }
            }
        }
        return false
    }
    
    func intersectsClosedHours(_ block: ScheduleBlock) -> [TimeInterval] {
        
        var placesIntersectingClosedHours = Array.init(repeating: 0.0, count: block.places.count)
        for (i, place) in block.places.enumerated() {
            guard let closedHours = place.closedHours else { continue }
            placesIntersectingClosedHours[i] += block.timing.intersectionWith(closedHours[0])?.duration ?? 0.0
            placesIntersectingClosedHours[i] += block.timing.intersectionWith(closedHours[1])?.duration ?? 0.0
        }
        return  placesIntersectingClosedHours
    }

}
