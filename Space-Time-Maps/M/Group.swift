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
    
}

struct OneOfBlock : Event {
    
    var name : String
    var places : [Place]
    var timing : Timing
    var selectedIndex : Int
    var destinations : [Destination] {
        get {
            return places.map{ Destination(place: $0, timing: self.timing, constraints: Constraints()) }
        }
    }
    
}
