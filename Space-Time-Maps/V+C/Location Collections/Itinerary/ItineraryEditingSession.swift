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
    var baseBlocks : [ScheduleBlock] // Ordered list of blocks NOT containing block being edited --> UNCHANGING!
    var callback : ([ScheduleBlock]?, Route?) -> () // TBH this probably shouldn't be set in the construcor, it should be an argument for each public method
    
    // This is what gets modified!
    var movingBlock : ScheduleBlock // Block being edited/moved around
    var lastPosition : Int?
    
    var scheduler : Scheduler
    
    init(scheduler: Scheduler, movingBlock block: ScheduleBlock, withIndex index: Int?, inBlocks blocks: [ScheduleBlock], travelMode: TravelMode, callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        self.movingBlock = block
        self.baseBlocks = blocks
        self.baseBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        
        self.travelMode = travelMode
        self.callback = callback
        self.lastPosition = index
        self.scheduler = scheduler
    }
    
    func moveBlock(toTime time: TimeInterval){
        
        // Make this time the "middle" of the block
        movingBlock.timing.start = time - movingBlock.timing.duration / 2
        movingBlock.timing.end = time + movingBlock.timing.duration / 2
        
        if intersectsOtherBlocks(movingBlock) {
            removeBlock()
        } else {
        
            // Create new schedule
            var modifiedBlocks = baseBlocks
            var insertAt = modifiedBlocks.endIndex
            for (i, block) in modifiedBlocks.enumerated() {
                
                if block.timing.start >= movingBlock.timing.start {
                    insertAt = i
                    break
                }
                
            }
            
            let changedOrder = (insertAt != lastPosition)
            modifiedBlocks.insert(movingBlock, at: insertAt)
            lastPosition = insertAt
            
            if changedOrder {
                scheduler.reschedule(blocks: modifiedBlocks, callback: callback)
            } else {
                scheduler.scheduleShift(blocks: modifiedBlocks, callback: callback)
            }
        }
        
    }
    
    
    func changeBlockDuration(with delta: Double) {
        let duration = movingBlock.timing.duration + delta
        guard duration >= MIN_DURATION else { return }
        
        // Shift it downwards from start-time, arbitrary design decision...
        movingBlock.timing.duration = duration
        movingBlock.timing.end = movingBlock.timing.start + movingBlock.timing.duration
        
        if intersectsOtherBlocks(movingBlock) {
            removeBlock()
        } else {
            // Compute new route with modifications
            var modifiedBlocks = baseBlocks
            modifiedBlocks.append(movingBlock)
            modifiedBlocks.sort(by: { $0.timing.start <= $1.timing.start })
            
            scheduler.schedulePinch(of: movingBlock, in: modifiedBlocks, callback: callback)
        }
        
    }
    
    func removeBlock() {
        scheduler.reschedule(blocks: baseBlocks, callback: callback)
    }
    
    func end() {
        moveBlock(toTime: movingBlock.timing.start)
    }
    
    func intersectsOtherBlocks(_ block: ScheduleBlock) -> Bool {
        
        guard let destinations = block.destinations else { return false }
        
        for dest in destinations {
            for b in baseBlocks {
                guard let bDests = b.destinations else { continue }
                for d in bDests {
                    if d.timing.intersects(dest.timing) {
                        return true
                    }
                }
            }
        }
        
        return false
    }

}
