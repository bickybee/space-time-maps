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
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func create(_ sender: Any) {        
        delegate?.createGroup(name: getName(), kind: getKind())
        self.dismiss(animated: true, completion: nil)
    }
    
    func getName() -> String {
        if let name = nameField.text {
            return name == "" ? "Group" : name
        } else {
            return "Group"
        }
    }
    
    func getKind() -> PlaceGroup.Kind {
        let selection = kindField.selectedSegmentIndex
        switch selection {
        case 0:
            return .none
        case 1:
            return .oneOf
        case 2:
            return .asManyOf
        default:
            return .none
        }
    }

}

protocol GroupCreationDelegate: AnyObject {
    
    func createGroup(name: String, kind: PlaceGroup.Kind)
    
}
