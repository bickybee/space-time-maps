//
//  GroupCell.swift
//  Space-Time-Maps
//
//  Created by Vicky on 30/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class GroupCell: DestinationCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupButtons() {
        
        let next = UIButton()
        let previous = UIButton()
        
        next.frame = CGRect(x: self.frame.maxX + 5, y: self.center.y , width: 25, height: 25)
        previous.frame = CGRect(x: self.frame.minX - 5, y: self.center.y , width: 25, height: 25)
        
        next.backgroundColor = .red
        previous.backgroundColor = .blue
        
        self.addSubview(next)
        self.addSubview(previous)
    }
    

    
}
