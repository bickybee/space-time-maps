//
//  PlaceCreationViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 09/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlaceEditingViewController: UIViewController {
    
    weak var delegate : PlaceEditingDelegate?
    var place : Place!
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var addBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = place.name
        timePicker.countDownDuration = 3600
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func finishEditingPlace(_ sender: Any) {
        place.timeSpent = timePicker.countDownDuration
        delegate?.finishedEditingPlace(place)
        self.dismiss(animated: true, completion: nil)
    }

}

protocol PlaceEditingDelegate: AnyObject {
    
    func finishedEditingPlace(_ editedPlace: Place)
    
}
