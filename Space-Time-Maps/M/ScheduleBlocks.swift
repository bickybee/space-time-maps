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
    
    var timing : Timing {
        didSet {
            destination.timing = timing
        }
    }
    var destination : Destination
    var destinations: [Destination]? {
        return [destination]
    }
    
    init(timing: Timing, destination: Destination) {
        self.timing = timing
        self.destination = destination
    }
    
}

protocol OptionBlock : ScheduleBlock {
    
    var name: String { get set }
    var timing: Timing { get set }
    var optionCount: Int { get }
    var selectedIndex: Int? { get set }
    var destinations: [Destination]? { get }
}

// lotsa code duplication to follow but that's ok, fix later

class OneOfBlock : OptionBlock {

    var name: String
    var timing: Timing { // currently assuming that destinations always take on the greater block timing
        didSet {
            options.forEach({ $0.timing = timing })
        }
    }
    var options: [Destination]
    var selectedIndex: Int?
    var destination: Destination? {
        return selectedIndex != nil ? options[selectedIndex!] : nil
    }
    var destinations: [Destination]? {
        return destination != nil ? [destination!] : nil
    }
    var optionCount : Int {
        return options.count
    }
    
    init(name: String, timing: Timing, options: [Destination]) {
        self.name = name
        self.timing = timing
        self.options = options
    }
    
}

class AsManyOfBlock : OptionBlock {
    
    var name: String
    var timing: Timing
    var options: [[Destination]]
    var selectedIndex: Int?
    var destinations: [Destination]? {
        return selectedIndex != nil ? options[selectedIndex!] : nil
    }
    var optionCount: Int {
        return options.count
    }
    
    init(name: String, timing: Timing, options: [[Destination]]) {
        self.name = name
        self.timing = timing
        self.options = options
    }
    
}

//
//class AsManyOf : OptionGroup {
//
//    var name : String
//    var timing : Timing
//    var destinations : [Place]
//
//}

class OneOfGroup : Schedulable {
    
    var name : String
    var places : [Place]
    var timing : Timing
    var selectedIndex : Int?
    var selectedDestination : Destination? {
        get {
            if let index = selectedIndex {
                return Destination(place: self.places[index], timing: self.timing)
            } else {
                return nil
            }
        }
    }
    var destinations : [Destination] {
        get {
            return places.map{ Destination(place: $0, timing: self.timing) }
        }
    }
    
    init(name: String, places: [Place], timing: Timing, selectedIndex: Int?) {
        self.name = name
        self.places = places
        self.timing = timing
        self.selectedIndex = selectedIndex
    }
    
    func copy() -> Schedulable {
        return OneOfGroup(name: self.name, places: self.places, timing: self.timing, selectedIndex: self.selectedIndex)
    }
    
}
