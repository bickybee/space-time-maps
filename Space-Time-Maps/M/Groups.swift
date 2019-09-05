//
//  PlaceGroup.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

protocol Event {
    
    var timing : Timing { get set }
    func copy() -> Event
    
}

struct PlaceGroup {
    
    enum Kind : String {
        case asManyOf, oneOf, none
    }
    
    var name : String
    var places : [Place]
    var kind : PlaceGroup.Kind
    
    func copy() -> PlaceGroup {
        return PlaceGroup(name: self.name, places: self.places, kind: self.kind)
    }
    
}

//class EventBlock : Event {
//    
//    var timing: Timing
//    var destinations: [Destination]
//    
//}

class OptionBlock : Event {
    
    var options: [[Destination]]
    var timing: Timing
    var selectedIndex: Int?
    var selectedOption: [Destination]? {
        return selectedIndex != nil ? options[selectedIndex!] : nil
    }
    
    init(options: [[Destination]], timing: Timing) {
        self.timing = timing
        self.options = options
    }
    
    func copy() -> Event {
        let copy = OptionBlock(options: self.options, timing: self.timing)
        copy.selectedIndex = self.selectedIndex
        return copy
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

class OneOfGroup : Event {
    
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
    
    func copy() -> Event {
        return OneOfGroup(name: self.name, places: self.places, timing: self.timing, selectedIndex: self.selectedIndex)
    }
    
}
