//
//  TimePickerView.swift
//  Space-Time-Maps
//
//  Created by Vicky on 21/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimePickerView: UIView {
    @IBOutlet weak var startPicker: UIDatePicker!
    @IBOutlet weak var endPicker: UIDatePicker!
    
  override init(frame: CGRect) {
       super.init(frame: frame)
   }

   convenience init() {
       self.init(frame: CGRect.zero)
   }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
