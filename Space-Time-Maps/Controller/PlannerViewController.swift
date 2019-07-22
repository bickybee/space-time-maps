//
//  ViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PlannerViewController: UIViewController {
    
    var placeManager : PlaceManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let placePaletteVC = segue.destination as? PlacePaletteViewController {
            placePaletteVC.placeManager = self.placeManager
        }
//        else if let plannerVC = segue.destination as? PlannerViewController {
//            plannerVC.placeManager = self.placeManager
//        }
    }

}
