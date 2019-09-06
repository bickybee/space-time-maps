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
    
    var timing: Timing { get set }
    var placeGroup: PlaceGroup { get set } // reference to original group
    
    var optionIndex: Int? { get set }
    
    var optionCount: Int { get }
    var destinations: [Destination]? { get }
    var name: String { get }
}

// lotsa code duplication to follow but that's ok, fix later

class OneOfBlock : OptionBlock {

    var timing: Timing {
        didSet {
            optionIndex = nil
        }
    }
    var placeGroup : PlaceGroup
    
    var optionIndex: Int?
    
    var destination: Destination? {
        
        if let index = optionIndex {
            let place = placeGroup.places[index]
            return Destination(place: place, timing: timing)
        } else {
            return nil
        }
        
    }
    var destinations: [Destination]? {
        return destination != nil ? [destination!] : nil
    }
    var optionCount : Int {
        return placeGroup.places.count
    }
    var name : String {
        return placeGroup.name
    }
    
    init(placeGroup: PlaceGroup, timing: Timing) {
        self.placeGroup = placeGroup
        self.timing = timing
    }
    
}

class AsManyOfBlock : OptionBlock {
    
    var placeGroup: PlaceGroup
    var timing: Timing {
        didSet {
            optionIndex = nil
        }
    }
    var permutations: [[Destination]]
    
    var optionIndex: Int?
    var destinations: [Destination]? {
        return optionIndex != nil ? permutations[optionIndex!] : nil
    }
    var optionCount: Int {
        return permutations.count
    }
    var name : String {
        return placeGroup.name
    }
    
    init(placeGroup: PlaceGroup, timing: Timing, permutations: [[Destination]]) {
        self.placeGroup = placeGroup
        self.timing = timing
        self.permutations = permutations
    }
    
}
