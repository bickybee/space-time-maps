//
//  DurationTimeViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 26/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class DurationTimeViewController: PopupViewController {
    
    var durationPicker: TimePickerController!
    var duration: TimeInterval!
    
    var onUpdatedDurationBlock : ((TimeInterval) -> Void)?

    convenience init(_ schedulable: Schedulable) {
        self.init()
        duration = schedulable.timing.duration
        colour = colorFromSchedulable(schedulable)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPicker()
    }
    
    func setupPicker() {
       durationPicker = TimePickerController()
       addChild(durationPicker)
       view.insertSubview(durationPicker.view, at: 0)
       durationPicker.didMove(toParent: self)
       
       durationPicker.label.text = "Duration"
       durationPicker.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        durationPicker.picker.datePickerMode = .countDownTimer
        durationPicker.picker.minuteInterval = 15
       durationPicker.delegate = self
       
       // fill with correct info
       if let duration = duration {
           durationPicker.picker.countDownDuration = duration
       }
   }

}

extension DurationTimeViewController : TimePickerDelegate {
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateTimeTo time: TimeInterval) {
        duration = timePickerController.picker.countDownDuration
        onUpdatedDurationBlock?(duration)
    }
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateDateTo date: Date) {
        // do nothing
    }
    
}
