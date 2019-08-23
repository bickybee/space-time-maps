//
//  TimeConstraints.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class Constraints {
    
    var areEnabled : Bool = false // TEMP for testing

//    var arrival : Constraint?
//    var departure : Constraint?
//    var duration : Constraint?
//
//
//    func all() -> [Constraint.Kind: Constraint] {
//        
//        var constraints = [Constraint.Kind: Constraint]()
//
//        if arrival != nil { constraints[Constraint.Kind.arrival] = arrival }
//        if departure != nil { constraints[Constraint.Kind.departure] = departure }
//        if duration != nil { constraints[Constraint.Kind.duration] = duration }
//
//        return constraints
//    }
//
//    func with(flexibility: Constraint.Flexibility) -> [Constraint.Kind: Constraint] {
//
//        let constraints = self.all()
//        let filteredConstraints = constraints.filter({ $0.value.flexibility == flexibility })
//
//        return filteredConstraints
//
//    }

}

struct Constraint {
    
    enum Flexibility : String {
        case hard, soft
    }
    
    enum Kind : String {
        case arrival, departure, duration
    }
    
    var time : TimeInterval
    var flexibility : Constraint.Flexibility
    
}
