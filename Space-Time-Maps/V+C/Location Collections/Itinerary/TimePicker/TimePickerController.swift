//
//  TimePickerController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 24/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimePickerController: UIViewController {

    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var picker: UIDatePicker!
    
    var delegate: TimePickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // format picker
        picker.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        //picker.subviews[0].subviews[2].isHidden = true
        
    }
    
    @IBAction func didUpdatePicker(_ sender: Any) {
        if picker.datePickerMode == .time {
            delegate?.timePickerController(self, didUpdateDateTo: picker.date)
        } else if picker.datePickerMode == .countDownTimer {
            delegate?.timePickerController(self, didUpdateTimeTo: picker.countDownDuration)
        }
        
    }
    
    @IBAction func didUpdateStepper(_ sender: Any) {
        if picker.datePickerMode == .time {
            stepDate()
        } else if picker.datePickerMode == .countDownTimer {
            stepTime()
        }
        stepper.value = 0
    }
    
    func stepDate() {
        if #available(iOS 13.0, *) {
        
            let dir = stepper.value
            let dt = dir * TimeInterval.from(minutes: 15)
            let potentialDate = picker.date.addingTimeInterval(dt)
            
            var newDate: Date?
            if let minDate = picker.minimumDate {
                let dif = abs(potentialDate.distance(to: minDate))
                if dif >= TimeInterval.from(minutes: 15) {
                    newDate = potentialDate
                }
            } else if let maxDate = picker.maximumDate {
                let dif = abs(potentialDate.distance(to: maxDate))
                if dif >= TimeInterval.from(minutes: 15) {
                    newDate = potentialDate
                }
            }
            
            if let date = newDate {
                picker.setDate(date, animated: true)
                delegate?.timePickerController(self, didUpdateDateTo: picker.date)
            }
        }
    }
    
    func stepTime() {
        let dir = stepper.value
        let dt = dir * TimeInterval.from(minutes: 15)
        let time = picker.countDownDuration + dt
        if time > 0 {
            picker.countDownDuration = time
            delegate?.timePickerController(self, didUpdateTimeTo: time)
        }
    }
    
}


protocol TimePickerDelegate : AnyObject {
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateDateTo date: Date)
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateTimeTo time: TimeInterval)

}
