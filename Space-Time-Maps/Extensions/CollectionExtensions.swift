//
//  ArrayExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 06/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
