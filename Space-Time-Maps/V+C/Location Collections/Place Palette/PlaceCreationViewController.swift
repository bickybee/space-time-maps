//
//  PlaceCreationViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 09/10/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlaceCreationViewController: UIViewController {
    
    weak var delegate : PlaceCreationDelegate?
    var place : Place!
    
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var addBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = place.name
        timePicker.countDownDuration = 3600
        // Do any additional setup after loading the view.
    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPlace(_ sender: Any) {
        place.timeSpent = timePicker.countDownDuration
        delegate?.createPlace(place)
        self.dismiss(animated: true, completion: nil)
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

protocol PlaceCreationDelegate: AnyObject {
    
    func createPlace(_ newPlace: Place)
    
}
