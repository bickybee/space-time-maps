//
//  DualTimeViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 26/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class StartEndTimeViewController: PopupViewController {

    var startPicker: TimePickerController!
    var endPicker: TimePickerController!
    
    var startDate : Date!
    var endDate : Date!
    
    var onUpdatedTimingBlock : ((Timing) -> Void)?
    
    convenience init(_ schedulable: Schedulable) {
        self.init()
        startDate = schedulable.timing.start.toDate()
        endDate = schedulable.timing.end.toDate()
        colour = colorFromSchedulable(schedulable)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPickers()
    }
    
    func setupPickers() {
        startPicker = TimePickerController()
        addChild(startPicker)
        view.insertSubview(startPicker.view, at: 0)
        startPicker.didMove(toParent: self)
        
        startPicker.label.text = "Start Time"
        startPicker.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 2.0)
        startPicker.delegate = self
        
        endPicker = TimePickerController()
        endPicker.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2.0)
        addChild(endPicker)
        view.insertSubview(endPicker.view, at: 0)
        
        endPicker.label.text = "End Time"
        endPicker.delegate = self
        endPicker.didMove(toParent: self)

        
        // fill with correct info
        if let startDate = startDate, let endDate = endDate {
            
            startPicker.picker.setDate(startDate, animated: false)
            endPicker.picker.setDate(endDate, animated: false)
            
            updatePickers()
        }
    }
    
    override func viewDidLayoutSubviews() {
        startPicker.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height / 2.0)
        endPicker.view.frame = CGRect(x: 0, y: view.bounds.height / 2.0 - 5, width: view.bounds.width , height: view.bounds.height / 2.0)
    }
    
    func timingFromPickers() -> Timing {
        let cal = Calendar.current
        
        let startHour = TimeInterval.from(hours: cal.component(.hour, from: startDate!))
        let startMin = TimeInterval.from(minutes: cal.component(.minute, from: startDate!))
        let start = startHour + startMin
        
        let endHour = TimeInterval.from(hours: cal.component(.hour, from: endDate!))
        let endMin = TimeInterval.from(minutes: cal.component(.minute, from: endDate!))
        let end = endHour + endMin
        
        return Timing(start: start, end: end)
    }
    
    func updatePickers() {
        startPicker.picker.maximumDate = endDate?.addingTimeInterval(-TimeInterval.from(minutes: 15))
        endPicker.picker.minimumDate = startDate?.addingTimeInterval(TimeInterval.from(minutes: 15))
    }

}

extension StartEndTimeViewController : TimePickerDelegate {
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateDateTo date: Date) {
        
        startDate = startPicker.picker.date
        endDate = endPicker.picker.date
        
        let newTiming = timingFromPickers()
        onUpdatedTimingBlock?(newTiming)
        updatePickers()
    }
    
    func timePickerController(_ timePickerController: TimePickerController, didUpdateTimeTo time: TimeInterval) {
        // do nothing
    }
    
}
