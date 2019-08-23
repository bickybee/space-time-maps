//
//  GroupCreationViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 22/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupCreationViewController: UIViewController {

    weak var delegate : GroupCreationDelegate?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var kindField: UISegmentedControl!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func create(_ sender: Any) {
        var text : String
        if let name = nameField.text {
            text = name
        } else {
            text = "Group"
        }
        
        var kind : PlaceGroup.Kind
        let selection = kindField.selectedSegmentIndex
        switch selection {
        case 0:
            kind = .asManyOf
        case 1:
            kind = .oneOf
        default:
            kind = .asManyOf
        }
        
        delegate?.createGroup(name: text, kind: kind)
        
        print("bye")
        self.dismiss(animated: true, completion: nil)
    }

}

protocol GroupCreationDelegate: AnyObject {
    
    func createGroup(name: String, kind: PlaceGroup.Kind)
    
}
