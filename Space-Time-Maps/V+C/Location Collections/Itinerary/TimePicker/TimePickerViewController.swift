//
//  TimePickerViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 21/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class TimePickerViewController: UIViewController {
    
    @IBOutlet weak var startPicker: UIDatePicker!
    @IBOutlet weak var endPicker: UIDatePicker!
    @IBOutlet weak var doneButton: UIButton!
    
    var block : Schedulable?
    var colour : UIColor!
    
    var startDate : Date?
    var endDate : Date?
    
    var onDoneBlock : (() -> Void)?
    var onUpdatedTimingBlock : ((Timing) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        colour = colorFromSchedulable()
        startDate = block?.timing.start.toDate()
        endDate = block?.timing.end.toDate()
        
        setupPickers()
        setupBackground()
        setupButton()
    }
    
    func setupButton() {
        doneButton.layer.cornerRadius = 5;
        doneButton.backgroundColor = colour
    }
    
    func setupPickers() {
        // make small and remove lines
        startPicker.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        startPicker.subviews[0].subviews[2].isHidden = true
        endPicker.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        endPicker.subviews[0].subviews[2].isHidden = true

        
        // fill with correct info
        if let startDate = startDate, let endDate = endDate {
            
            startPicker.setDate(startDate, animated: false)
            endPicker.setDate(endDate, animated: false)
            
            updatePickers()
        }
    }
    
    func setupBackground() {
        // border
        view.layer.cornerRadius = 10;
        view.layer.borderWidth = 5;
        view.layer.borderColor = colour.cgColor
    }
    
    @IBAction func didTapDone(_ sender: Any) {
        onDoneBlock?()
    }
    
    @IBAction func didUpdateStartPicker(_ sender: Any) {
        // update block, then
        startDate = startPicker.date
        onUpdatedTimingBlock?(timingFromPickers())
        updatePickers()
    }
    
    @IBAction func didUpdateEndPicker(_ sender: Any) {
        // update block, then
        endDate = endPicker.date
        onUpdatedTimingBlock?(timingFromPickers())
        updatePickers()
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
        startPicker.maximumDate = endDate?.addingTimeInterval(-TimeInterval.from(minutes: 15))
        endPicker.minimumDate = startDate?.addingTimeInterval(TimeInterval.from(minutes: 15))
    }
    
    func colorFromSchedulable() -> UIColor {
        
        var colour : UIColor!
        if let block = block as? SingleBlock {
            colour = block.destination.place.color
        } else {
            colour = UIColor.gray
        }
        
        return colour
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
