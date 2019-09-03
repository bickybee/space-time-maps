//
//  UIButtonExtensions.swift
//  Space-Time-Maps
//
//  Created by Vicky on 02/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIButton

extension UIButton {
    
    func toggle() {
        
        self.isEnabled = !self.isEnabled
        self.alpha = self.isEnabled ? 1.0 : 0.0
        
    }
    
}
