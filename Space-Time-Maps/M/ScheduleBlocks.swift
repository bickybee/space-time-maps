//
//  PlaceGroup.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

// More complex stuff to render in the schedule
// Groups/blocks that contain Schedulables

protocol ScheduleBlock : Schedulable {
    
    var timing : Timing { get set }
    var destinations: [Destination]? { get }
    
}

class SingleBlock : ScheduleBlock {
    
    var timing : Timing
    var place : Place
    
    var destination : Destination {
        return Destination(place: place, timing: timing)
    }
    var destinations: [Destination]? {
        return [destination]
    }
    
    init(timing: Timing, place: Place) {
        self.timing = timing
        self.place = place
    }
    
}

protocol OptionBlock : ScheduleBlock {
    
    // set values
    var timing: Timing { get set }
    var placeGroup: PlaceGroup { get set } // reference to original group
    
    var options: [[Int]] { get } // lists of indices into placegroup
    var optionPlaceIDs: [[String]] { get } // convenience
    
    var selectedOption: Int? { get set }
    
    var destinations: [Destination]? { get } // result of selected option
    var name: String { get }
    var isFixed : Bool { get set }
}

// lotsa code duplication to follow but that's ok, FIXE later

class OneOfBlock : OptionBlock {

    var timing: Timing // applying timing to destinatino, no longer true tho
    var placeGroup : PlaceGroup
    var selectedOption: Int?
    var options : [[Int]]
    var isFixed : Bool
    
    var optionPlaceIDs: [[String]] {
        return options.map( { $0.map( { placeGroup[$0].placeID } ) } )
    }
    
    var destination: Destination? {
        
        if let index = selectedOption {
            let place = placeGroup[index]
            return Destination(place: place, timing: timing)
        } else {
            return nil
        }
        
    }
    var destinations: [Destination]? {
        return destination != nil ? [destination!] : nil
    }
    var optionCount : Int {
        return placeGroup.count
    }
    var name : String {
        return placeGroup.name
    }
    
    init(placeGroup: PlaceGroup, timing: Timing) {
        self.placeGroup = placeGroup
        self.timing = timing
        self.options = placeGroup.places.indices.map( { [$0] } )
        self.isFixed = false
    }
    
}

class AsManyOfBlock : OptionBlock {
    
    var placeGroup: PlaceGroup
    var timing: Timing {
        willSet(newTiming) {
            let delta = newTiming.start - timing.start
            shiftDestinationsBy(delta)
        }
    }
    
    var options: [[Int]] // indices into placeGroup
    
    var optionPlaceIDs: [[String]] {
        return options.map( { $0.map( { placeGroup[$0].placeID } ) } )
    }
    
    var scheduledOptions: [[Destination]]?
    
    var selectedOption: Int?
    var destinations: [Destination]? {
        return selectedOption != nil ? scheduledOptions![selectedOption!] : nil
    }
    var optionCount: Int {
        return options.count
    }
    var name : String {
        return placeGroup.name
    }
    var isFixed: Bool
    
    init(placeGroup: PlaceGroup, timing: Timing) {
        self.placeGroup = placeGroup
        self.timing = timing
        self.isFixed = false
        
        let indices = Array(placeGroup.places.indices)
        var p = [[Int]]()
        Combinatorics.permute(indices, indices.count - 1, &p)
        
        self.options = p
    }
    
    func shiftDestinationsBy(_ dT: TimeInterval) {
        
        if let scheduledOptions = scheduledOptions {
            for dests in scheduledOptions {
                for d in dests {
                    let duration = d.timing.duration
                    let start = d.timing.start + dT
                    d.timing = Timing(start: start, duration: duration)
                }
            }
        }
        
    }
    
    func defaultPermutations() -> [[Int]] {
//        let places = placeGroup.places.indices
        let indices = Array(placeGroup.places.indices)
        var p = [[Int]]()
        Combinatorics.permute(indices, indices.count - 1, &p)
        return p
    }
    
    // Find out which combination of places actually fits in the overall timeblock
    func setPermutationsUsing(_ timeDict: TimeDict) {
        
        // Keep track of valid terms and their total times
        var validPermTimes = [ ( TimeInterval, [Int] )]()
        
        // First try permutations that include ALL places, then decrease number of places (subset size) if none fit, etc.
        var trialPerms = defaultPermutations()
        var subsetSize = placeGroup.count
        
        // Let's gooo
        var optionFound = false
        while (!optionFound) {
            
            // Sum up all the times for each perm and see if it fits in the asManyOf block
            for perm in trialPerms {
                var timeNeeded = TimeInterval(0)
                for (i, placeIndex) in perm.enumerated() {
                    timeNeeded += placeGroup[placeIndex].timeSpent
                    if (i < perm.count - 1) {
                        timeNeeded += timeDict[PlacePair(startID: placeGroup[placeIndex].placeID, endID: placeGroup[perm[i + 1]].placeID)]!
                    }
                }
                
                if timeNeeded <= timing.duration {
                    validPermTimes.append( (timeNeeded, perm) )
                }
            }
            
            if validPermTimes.count > 0 {
                // Were any perms valid? If so, we're good to go
                optionFound = true
            } else if subsetSize > 1 {
                // Otherwise, try a smaller subset of places
                subsetSize -= 1
                trialPerms = Combinatorics.subsetPermutations(input: Array(placeGroup.places.indices), size: subsetSize)
            } else {
                break
            }
        }
        
        // Only take best 5
        if validPermTimes.count > 5 {
            validPermTimes.sort(by: { $0.0 <= $1.0 } )
        }
        
        let topFive = validPermTimes.prefix(5)
        let validPerms = topFive.map( { $0.1 })
        options = validPerms

    }

    
    
    
}
