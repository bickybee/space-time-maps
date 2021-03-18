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
    var destinations: [Destination] { get }
    var places : [Place] { get }
    var isPusher : Bool { get set }
    var isBeingPushed : Bool { get set }
    func copy() -> ScheduleBlock
}

class SingleBlock : ScheduleBlock {
    
    var timing : Timing
    var place : Place
    var places : [Place] {
        return [place]
    }
    
    var isPusher : Bool
    var isBeingPushed: Bool
    
    var destination : Destination {
        return Destination(place: place, timing: timing)
    }
    var destinations: [Destination] {
        return [destination]
    }
    
    init(timing: Timing, place: Place) {
        self.timing = timing
        self.place = place
        self.isBeingPushed = false
        self.isPusher = false
    }
    
    func copy() -> ScheduleBlock {
        return SingleBlock(timing: timing, place: place)
    }
    
}

protocol OptionBlock : ScheduleBlock {
    
    // set values
    var timing: Timing { get set }
    var placeGroup: PlaceGroup { get set } // reference to original group
    
    var options: [[Int]] { get } // lists of indices into placegroup
    var optionPlaceIDs: [[String]] { get } // convenience
    
    var optionCount: Int { get }
    var selectedOption: Int? { get set }
    
    var destinations: [Destination] { get } // result of selected option
    var name: String { get }
    var isFixed : Bool { get set }
    
}

// lotsa code duplication to follow but that's ok, FIXE later

class OneOfBlock : OptionBlock {

    var timing: Timing // applying timing to destinatino, no longer true tho
    var placeGroup : PlaceGroup
    var places : [Place] {
        return placeGroup.places
    }
    var selectedOption: Int?
    var options : [[Int]]
    var isFixed : Bool
    
    var isPusher : Bool
    var isBeingPushed: Bool
    
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
    var destinations: [Destination] {
        return destination != nil ? [destination!] : []
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
        
        self.isBeingPushed = false
        self.isPusher = false
    }
    
    func copy() -> ScheduleBlock {
        
        let theCopy = OneOfBlock(placeGroup: self.placeGroup, timing: self.timing)
        theCopy.options = self.options
        theCopy.selectedOption = self.selectedOption
        theCopy.isFixed = self.isFixed
        
        return theCopy
    }
    
}

class AsManyOfBlock : OptionBlock {
    
    var placeGroup: PlaceGroup
    var places : [Place] {
        return placeGroup.places
    }
    var timing: Timing {
        willSet(newTiming) {
            let delta = newTiming.start - timing.start
            shiftDestinationsBy(delta)
        }
    }
    
    var isPusher : Bool
    var isBeingPushed: Bool
    
    // BEST options...
    var options: [[Int]] // indices into placeGroup
    
    var optionPlaceIDs: [[String]] {
        return options.map( { $0.map( { placeGroup[$0].placeID } ) } )
    }
    
    var allOptions: [[[Int]]] //lol
 
    var scheduledOptions: [[Destination]]?
    
    var selectedOption: Int?
    var destinations: [Destination] {
        if let options = scheduledOptions, let selectedInd = selectedOption {
            return options[safe: selectedInd] ?? []
        } else {
            return []
        }
    }
    var optionCount: Int {
        return scheduledOptions?.count ?? 0
    }
    var name : String {
        return placeGroup.name
    }
    var isFixed: Bool
    
    init(placeGroup: PlaceGroup, timing: Timing) {
        self.placeGroup = placeGroup
        self.timing = timing
        self.isFixed = false
        
        self.isBeingPushed = false
        self.isPusher = false
        
//        let indices = Array(placeGroup.places.indices)
//        var p = [[Int]]()
//        Combinatorics.permute(indices, indices.count - 1, &p)
//
        self.options = [[Int]]()
        self.allOptions = [[[Int]]]()
        for _ in placeGroup.places.indices {
            self.allOptions.append([[Int]]())
        }
    }
    
    convenience init(placeGroup: PlaceGroup, timing: Timing, timeDict: TimeDict, travelMode: TravelMode) {
        self.init(placeGroup: placeGroup, timing: timing)
        self.setPermutationsUsing(timeDict, travelMode)
    }
    
    func copy() -> ScheduleBlock {
        
        let theCopy = AsManyOfBlock(placeGroup: self.placeGroup, timing: self.timing)
        theCopy.options = self.options
        theCopy.allOptions = self.allOptions
        theCopy.selectedOption = self.selectedOption
        theCopy.scheduledOptions = self.scheduledOptions.map { $0.map{ $0.map{ $0.copy() } }} as! [[Destination]]?
        theCopy.isFixed = self.isFixed
        
        return theCopy
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
    func setPermutationsUsing(_ timeDict: TimeDict, _ travelMode: TravelMode) {
        
        guard placeGroup.count > 0 else { return }
        // Keep track of valid terms and their total times
        
        // First try permutations that include ALL places, then decrease number of places (subset size) if none fit, etc.
        var trialPerms = defaultPermutations()
        var subsetSize = placeGroup.count
        let numSubsetLevels = placeGroup.count - 1
        
        // Let's gooo
        for level in 0 ... numSubsetLevels {
            
            trialPerms = Combinatorics.subsetPermutations(input: Array(placeGroup.places.indices), size: subsetSize)
            
            var validPermTimes = [ ( TimeInterval, [Int] )]()
//            var timeAvailable = timing.duration
            
            // Sum up all the times for each perm and see if it fits in the asManyOf block
            for perm in trialPerms {
                var timeNeeded = TimeInterval(0)
                for (i, placeIndex) in perm.enumerated() {
                    let place = placeGroup[placeIndex]
                    // Time spent at place
                    timeNeeded += place.timeSpent
                    // Time spent getting from this place to the next
                    if (i < perm.count - 1) {
                        let nextPlace = placeGroup[perm[i + 1]]
                        timeNeeded += timeDict.timeFrom(place, to: nextPlace, travellingBy: travelMode) //CRASHES
                    }
                }
                
                validPermTimes.append( (timeNeeded, perm) )
            }
            
            validPermTimes.sort(by: { $0.0 <= $1.0 } )
            let validPerms = validPermTimes.map( { $0.1 })
            allOptions[level] = validPerms
            
            subsetSize -= 1
            
//            } else if subsetSize > 1 {
//                // Otherwise, try a smaller subset of places
//
//            } else {
//                break
//            }
        }
        
//        validPermTimes.sort(by: { $0.0 <= $1.0 } )
//        let validPerms = validPermTimes.map( { $0.1 })
//        options = validPerms

    }
    
}
