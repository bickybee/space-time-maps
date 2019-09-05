//
//  PlaceGroup.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

struct Group {
    
    enum Kind : String {
        case asManyOf, oneOf, none
    }
    
    var name : String
    var places : [Place]
    var kind : Group.Kind
    
    func copy() -> Group {
        return Group(name: self.name, places: self.places, kind: self.kind)
    }
    
}

class OneOfBlock : Event {
    
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
        return OneOfBlock(name: self.name, places: self.places, timing: self.timing, selectedIndex: self.selectedIndex)
    }
    
}
