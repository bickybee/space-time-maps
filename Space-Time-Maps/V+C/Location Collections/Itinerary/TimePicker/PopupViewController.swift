//
//  TimePickerViewController.swift
//  Space-Time-Maps
//
//  Created by Vicky on 21/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController {
    
    var colour : UIColor = .gray
    var onDoneBlock : (() -> Void)?
    var doneButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        setupBackground()
        setupButton()
    }
    
    func setupButton() {
        let button = UIButton(frame: .zero)
        button.layer.cornerRadius = 5;
        button.setTitle("X", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = colour
        button.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        doneButton = button
    }
    
    func setupBackground() {
        // border
        view.layer.cornerRadius = 10;
        view.layer.borderWidth = 5;
        view.layer.borderColor = colour.cgColor
        view.backgroundColor = .white
    }
    
    @objc func didTapDone(_ sender: Any) {
        onDoneBlock?()
    }
    
    override func viewDidLayoutSubviews() {
        doneButton.frame = CGRect(x: view.frame.width - 30, y: 0, width: 30, height: 30)
    }
    
    func colorFromSchedulable(_ schedulable: Schedulable) -> UIColor {
        
        var colour : UIColor!
        if let block = schedulable as? SingleBlock {
            colour = block.destination.place.color
        } else if let dest = schedulable as? Destination {
            colour = dest.place.color
        } else {
            colour = UIColor.gray
        }
        
        return colour
    }

}
