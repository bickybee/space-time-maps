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
    var originalIndex : Int
    var callback : ([ScheduleBlock]?, Route?) -> () // TBH this probably shouldn't be set in the construcor, it should be an argument for each public method
    
    // This is what gets modified!
    var movingBlock : ScheduleBlock // Block being edited/moved around
    
    static let scheduler = Scheduler()
    
    init(movingBlock block: ScheduleBlock, withIndex index: Int, inBlocks blocks: [ScheduleBlock], travelMode: TravelMode, callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        self.movingBlock = block
        self.baseBlocks = blocks
        self.travelMode = travelMode
        self.callback = callback
        self.originalIndex = index
    }
    
    func moveBlock(toTime time: TimeInterval){
        
        // Make this time the "middle" of the block
        movingBlock.timing.start = time - movingBlock.timing.duration / 2
        movingBlock.timing.end = time + movingBlock.timing.duration / 2
        
        // Create new schedule
        var modifiedBlocks = baseBlocks
        modifiedBlocks.append(movingBlock)
        modifiedBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        
        // Compute new route with modifications
        computeRoute()
        
    }
    
    
    func changeBlockDuration(with delta: Double) {
        let duration = movingBlock.timing.duration + delta
        guard duration >= MIN_DURATION else { return }
        
        // Shift it downwards from start-time, arbitrary design decision...
        movingBlock.timing.duration = duration
        movingBlock.timing.end = movingBlock.timing.start + movingBlock.timing.duration
        
        // Compute new route with modifications
        computeRoute()
    }
    
    func removeBlock() {
        computeRoute(with: baseBlocks)
    }
    
    func end() {
        moveBlock(toTime: movingBlock.timing.start)
    }
    
    func computeRoute() {
        
        // Add movingBlock with whatever changes it may have had to the baseBlocks (unchanging blocks!)
        var modifiedBlocks = baseBlocks
        modifiedBlocks.append(movingBlock)
        modifiedBlocks.sort(by: { $0.timing.start <= $1.timing.start })
        computeRoute(with: modifiedBlocks)
        
    }
    
    func computeRoute(with blocks: [ScheduleBlock]) {
        if blocks.count <= 0 {
            callback(blocks, [])
        } else {
            ItineraryEditingSession.scheduler.schedule(blocks: blocks, travelMode: travelMode, callback: callback)
        }
    }

}
