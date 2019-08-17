//
//  TimeConstraints.swift
//  Space-Time-Maps
//
//  Created by Vicky on 08/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

enum TimingType : String {
    case arrival, departure, duration
}

class Constraints {
    
    var arrival : TimeConstraint?
    var departure : TimeConstraint?
    var duration : TimeConstraint?
    
    func all() -> [TimingType: TimeConstraint] {
        
        var constraints = [TimingType: TimeConstraint]()
        
        if arrival != nil { constraints[TimingType.arrival] = arrival }
        if departure != nil { constraints[TimingType.departure] = departure }
        if duration != nil { constraints[TimingType.duration] = duration }
        
        return constraints
    }
    
    func with(flexibility: TimeConstraint.Flexibility) -> [TimingType: TimeConstraint] {
    
        let constraints = self.all()
        let filteredConstraints = constraints.filter({ $0.value.flexibility == flexibility })
        
        return filteredConstraints
    
    }

}

struct TimeConstraint {
    
    enum Flexibility : String {
        case hard, soft
    }
    
    var time : TimeInterval
    var flexibility : TimeConstraint.Flexibility
    
}
